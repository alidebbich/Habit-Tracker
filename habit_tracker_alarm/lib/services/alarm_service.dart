import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';
import '../data/alarm_repository.dart';
import '../data/habit_repository.dart';

// ---------------------------------------------------------------------------
// Top-level background callback — MUST be a top-level function and annotated.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  // App is in killed state; relaunched by the system.
  // getNotificationAppLaunchDetails() in init() will handle routing.
}

class AlarmService {
  AlarmService._internal();
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AlarmRepository _alarmRepo = AlarmRepository();
  final HabitRepository _habitRepo = HabitRepository();

  bool _initialized = false;

  /// Set this callback so the UI layer can navigate to AlarmDismissScreen.
  void Function(String alarmId)? onAlarmFired;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    if (_initialized) return;

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

    _initialized = true;

    // Check if the app was launched via fullScreenIntent / notification tap.
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

    await _requestPermissions();
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
    await androidPlugin.requestNotificationsPermission();
  }

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

  Future<void> requestExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  Future<bool> hasFullScreenIntentPermission() async => true;

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  Future<void> _rescheduleExistingAlarms() async {
    try {
      final alarms = await _alarmRepo.getAlarms();
      for (final alarm in alarms) {
        if (alarm.isEnabled) {
          await scheduleAlarm(alarm);
        }
      }
    } catch (e) {
      debugPrint('AlarmService: Error rescheduling alarms: $e');
    }
  }

  Future<void> scheduleAlarm(Alarm alarm) async {
    final int notifId = _notifId(alarm.id);
    // Always cancel first to avoid duplicate notifications
    await _notifications.cancel(notifId);

    final DateTime nextTrigger = _getNextTriggerDate(alarm);
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(nextTrigger, tz.local);

    final bool isBuiltIn = _isBuiltInSound(alarm.sound);
    final String? soundName =
        (isBuiltIn && alarm.sound != 'default') ? alarm.sound : null;

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
      additionalFlags: Int32List.fromList(<int>[4]),
      ongoing: true,
    );

    // Try with exact alarm first, fall back to inexact
    try {
      await _notifications.zonedSchedule(
        notifId,
        '⏰ ${alarm.label}',
        _missionDescription(alarm),
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: alarm.weekdays.isEmpty
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
        payload: alarm.id,
      );
      debugPrint('AlarmService: Scheduled exact alarm at $scheduledDate for ${alarm.label}');
    } catch (e) {
      debugPrint('AlarmService: Exact alarm failed ($e), trying inexact...');
      try {
        await _notifications.zonedSchedule(
          notifId,
          '⏰ ${alarm.label}',
          _missionDescription(alarm),
          scheduledDate,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: alarm.weekdays.isEmpty
              ? DateTimeComponents.time
              : DateTimeComponents.dayOfWeekAndTime,
          payload: alarm.id,
        );
        debugPrint('AlarmService: Scheduled inexact alarm for ${alarm.label}');
      } catch (e2) {
        debugPrint('AlarmService: Could not schedule alarm: $e2');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel / Delete
  // ---------------------------------------------------------------------------

  Future<void> cancelAlarm(String alarmId) async {
    final int notifId = _notifId(alarmId);
    try {
      await _notifications.cancel(notifId);
      debugPrint('AlarmService: Cancelled notification $notifId');
    } catch (e) {
      debugPrint('AlarmService: Error cancelling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('AlarmService: Error cancelling all notifications: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Mission completion
  // ---------------------------------------------------------------------------

  Future<void> completeHabitMission(Alarm alarm) async {
    if (alarm.associatedHabitId != null) {
      try {
        final habits = await _habitRepo.getHabits();
        final matches =
            habits.where((h) => h.id == alarm.associatedHabitId).toList();
        if (matches.isNotEmpty) {
          final habit = matches.first;
          if (!habit.isCompletedOn(DateTime.now())) {
            await _habitRepo.updateHabit(habit.toggleCompletion(DateTime.now()));
          }
        }
      } catch (e) {
        debugPrint('AlarmService: Error completing habit mission: $e');
      }
    }
    await cancelAlarm(alarm.id);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _notifId(String alarmId) => alarmId.hashCode.abs() % 0x7FFFFFFF;

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
