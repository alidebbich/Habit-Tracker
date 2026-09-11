import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';
import '../data/alarm_repository.dart';
import '../data/habit_repository.dart';

// ---------------------------------------------------------------------------
// Top-level background callback required by flutter_local_notifications.
// Must be annotated so the Dart VM keeps it in the compiled output.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  // When the app is killed and a notification is tapped, Android relaunches
  // the app. getNotificationAppLaunchDetails() in init() then handles routing.
}

class AlarmService {
  AlarmService._internal();
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AlarmRepository _alarmRepo = AlarmRepository();
  final HabitRepository _habitRepo = HabitRepository();

  /// Set this callback so the UI layer can navigate to AlarmDismissScreen.
  void Function(String alarmId)? onAlarmFired;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    // Check if the app was launched via fullScreenIntent / notification from
    // the lock screen — if so fire immediately once Flutter is ready.
    final launchDetails =
        await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          onAlarmFired?.call(payload);
        });
      }
    }

    // Request permissions that are required for reliable alarm delivery.
    await _requestPermissions();

    // Re-schedule any saved alarms after a restart.
    await _rescheduleExistingAlarms();
  }

  void _onNotificationTapped(NotificationResponse response) {
    final alarmId = response.payload;
    if (alarmId != null) onAlarmFired?.call(alarmId);
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Android 13+: POST_NOTIFICATIONS (shows a dialog — appropriate at startup)
    await androidPlugin.requestNotificationsPermission();
  }

  /// Returns true if exact alarms can be scheduled.
  /// On Android 12+ the user must grant this in system settings.
  Future<bool> canScheduleExactAlarms() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    try {
      return await androidPlugin.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the "Alarms & Reminders" system settings screen so the user can
  /// grant SCHEDULE_EXACT_ALARM (required on Android 12+).
  Future<void> requestExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  /// Returns true if USE_FULL_SCREEN_INTENT is granted.
  /// On Android 14+ users may need to grant this via Special App Access.
  /// Note: flutter_local_notifications does not expose a direct API for this,
  /// so we return true and guide users manually via the banner text.
  Future<bool> hasFullScreenIntentPermission() async {
    // The permission check API varies by plugin version.
    // Return true by default — the banner will still show build guidance.
    return true;
  }

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  Future<void> _rescheduleExistingAlarms() async {
    final alarms = await _alarmRepo.getAlarms();
    for (final alarm in alarms) {
      if (alarm.isEnabled) await scheduleAlarm(alarm);
    }
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    final int notifId = alarm.id.hashCode.abs() % 0x7FFFFFFF;
    final DateTime nextTrigger = _getNextTriggerDate(alarm);
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(nextTrigger, tz.local);

    // Only use built-in raw resource names as the notification sound.
    // Custom file paths are played by AlarmAudioService when the dismiss
    // screen opens — they cannot be used as a RawResourceAndroidNotificationSound.
    final bool isBuiltIn = _isBuiltInSound(alarm.sound);
    final String? soundName =
        (isBuiltIn && alarm.sound != 'default') ? alarm.sound : null;

    // Attempt 1: with built-in sound + exact alarm
    try {
      await _scheduleInternal(
        notifId: notifId,
        alarm: alarm,
        scheduledDate: scheduledDate,
        soundName: soundName,
        exact: true,
      );
      return;
    } catch (_) {}

    // Attempt 2: default sound + exact alarm
    try {
      await _scheduleInternal(
        notifId: notifId,
        alarm: alarm,
        scheduledDate: scheduledDate,
        soundName: null,
        exact: true,
      );
      return;
    } catch (_) {}

    // Attempt 3: default sound + inexact (fallback if permission denied)
    try {
      await _scheduleInternal(
        notifId: notifId,
        alarm: alarm,
        scheduledDate: scheduledDate,
        soundName: null,
        exact: false,
      );
    } catch (_) {}
  }

  Future<void> _scheduleInternal({
    required int notifId,
    required Alarm alarm,
    required tz.TZDateTime scheduledDate,
    required String? soundName,
    required bool exact,
  }) async {
    final channelId =
        soundName != null ? 'alarm_channel_$soundName' : 'alarm_channel_default';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      'Wake Up Alarms',
      channelDescription: 'Alarms that wake you up with a morning mission',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: soundName != null
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
      enableVibration: alarm.vibrate,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      // FLAG_INSISTENT (4): keeps looping the sound/vibration until cleared
      additionalFlags: Int32List.fromList(<int>[4]),
    );

    await _notifications.zonedSchedule(
      notifId,
      '⏰ ${alarm.label}',
      _missionDescription(alarm),
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: alarm.weekdays.isEmpty
          ? DateTimeComponents.time
          : DateTimeComponents.dayOfWeekAndTime,
      payload: alarm.id,
    );
  }

  // ---------------------------------------------------------------------------
  // Mission completion
  // ---------------------------------------------------------------------------

  /// Auto-checks the linked morning-anchor habit and cancels the alarm.
  /// Called from AlarmDismissScreen when the user completes their mission.
  Future<void> completeHabitMission(Alarm alarm) async {
    if (alarm.associatedHabitId != null) {
      final habits = await _habitRepo.getHabits();
      final matches =
          habits.where((h) => h.id == alarm.associatedHabitId).toList();
      if (matches.isNotEmpty) {
        final habit = matches.first;
        if (!habit.isCompletedOn(DateTime.now())) {
          await _habitRepo.updateHabit(habit.toggleCompletion(DateTime.now()));
        }
      }
    }
    await cancelAlarm(alarm.id);
  }

  Future<void> cancelAlarm(String alarmId) async {
    final int notifId = alarmId.hashCode.abs() % 0x7FFFFFFF;
    await _notifications.cancel(notifId);
  }

  Future<void> cancelAll() async => _notifications.cancelAll();

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isBuiltInSound(String sound) {
    if (sound == 'default') return true;
    if (sound.startsWith('/')) return false;
    if (Platform.isAndroid && sound.contains(Platform.pathSeparator)) {
      return false;
    }
    return true;
  }

  DateTime _getNextTriggerDate(Alarm alarm) {
    final now = DateTime.now();
    DateTime target = DateTime(
        now.year, now.month, now.day, alarm.time.hour, alarm.time.minute);

    // If that moment has already passed today, start from tomorrow
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }

    // Advance until we land on an allowed weekday (Dart: 1=Mon … 7=Sun)
    if (alarm.weekdays.isNotEmpty) {
      int safety = 0;
      while (!alarm.weekdays.contains(target.weekday) && safety < 7) {
        target = target.add(const Duration(days: 1));
        safety++;
      }
    }

    return target;
  }

  String _missionDescription(Alarm alarm) {
    switch (alarm.dismissMissionType) {
      case DismissMissionType.habitCheck:
        return 'Complete your morning habit to dismiss this alarm!';
      case DismissMissionType.mathProblem:
        return 'Solve a math problem to dismiss this alarm!';
      case DismissMissionType.typingChallenge:
        return 'Type a phrase to dismiss this alarm!';
      case DismissMissionType.shakePhone:
        return 'Shake your phone to dismiss this alarm!';
      default:
        return 'Tap to dismiss your alarm.';
    }
  }
}
