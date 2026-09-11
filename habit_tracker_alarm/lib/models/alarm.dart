
enum DismissMissionType {
  none,
  habitCheck, // Must check off a specific habit
  mathProblem, // Solve a simple math problem
  typingChallenge, // Type a specific phrase
  photoCapture, // Take a photo (would require camera permission)
  barcodeScan, // Scan a barcode/QR code
  shakePhone, // Shake phone a certain number of times
}

class Alarm {
  final String id;
  final DateTime time; // Time of day for alarm
  final List<int> weekdays; // 0 = Sunday, 1 = Monday, etc. Empty for daily
  final String label;
  final bool isEnabled;
  final DismissMissionType dismissMissionType;
  final String? associatedHabitId; // ID of habit that must be completed to dismiss
  final String? dismissMissionParam; // Parameter for mission (e.g., math problem, phrase to type)
  final int snoozeDuration; // Minutes
  final int maxVolume; // 0-100
  final bool vibrate;
  final String sound; // 'default' or asset name
  
  Alarm({
    required this.id,
    required this.time,
    this.weekdays = const [],
    this.label = 'Alarm',
    this.isEnabled = true,
    this.dismissMissionType = DismissMissionType.none,
    this.associatedHabitId,
    this.dismissMissionParam,
    this.snoozeDuration = 5,
    this.maxVolume = 100,
    this.vibrate = true,
    this.sound = 'default',
  });
  
  // Check if alarm should trigger on a given date
  bool shouldTriggerOn(DateTime date) {
    if (!isEnabled) return false;
    
    if (weekdays.isEmpty) {
      // Daily alarm
      return true;
    } else {
      // Check if day of week matches
      final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
      final sundayBasedDay = (dayOfWeek + 5) % 7; // Convert to 0 = Sunday, 1 = Monday, etc.
      return weekdays.contains(sundayBasedDay);
    }
  }
  
  // Get next trigger date
  DateTime getNextTriggerDate() {
    final now = DateTime.now();
    DateTime targetDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // If time has passed today, check tomorrow
    if (targetDate.isBefore(now)) {
      targetDate = targetDate.add(const Duration(days: 1));
    }
    
    // Find next matching day
    while (!shouldTriggerOn(targetDate)) {
      targetDate = targetDate.add(const Duration(days: 1));
    }
    
    return targetDate;
  }
  
  // Copy with
  Alarm copyWith({
    String? id,
    DateTime? time,
    List<int>? weekdays,
    String? label,
    bool? isEnabled,
    DismissMissionType? dismissMissionType,
    String? associatedHabitId,
    String? dismissMissionParam,
    int? snoozeDuration,
    int? maxVolume,
    bool? vibrate,
    String? sound,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      weekdays: weekdays ?? List.from(this.weekdays),
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      dismissMissionType: dismissMissionType ?? this.dismissMissionType,
      associatedHabitId: associatedHabitId ?? this.associatedHabitId,
      dismissMissionParam: dismissMissionParam ?? this.dismissMissionParam,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
      maxVolume: maxVolume ?? this.maxVolume,
      vibrate: vibrate ?? this.vibrate,
      sound: sound ?? this.sound,
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'weekdays': weekdays,
      'label': label,
      'isEnabled': isEnabled,
      'dismissMissionType': dismissMissionType.index,
      'associatedHabitId': associatedHabitId,
      'dismissMissionParam': dismissMissionParam,
      'snoozeDuration': snoozeDuration,
      'maxVolume': maxVolume,
      'vibrate': vibrate,
      'sound': sound,
    };
  }
  
  // Create from JSON
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'],
      time: DateTime.parse(json['time']),
      weekdays: List<int>.from(json['weekdays'] ?? []),
      label: json['label'] ?? 'Alarm',
      isEnabled: json['isEnabled'] ?? true,
      dismissMissionType: DismissMissionType.values[json['dismissMissionType'] ?? 0],
      associatedHabitId: json['associatedHabitId'],
      dismissMissionParam: json['dismissMissionParam'],
      snoozeDuration: json['snoozeDuration'] ?? 5,
      maxVolume: json['maxVolume'] ?? 100,
      vibrate: json['vibrate'] ?? true,
      sound: json['sound'] ?? 'default',
    );
  }
}
