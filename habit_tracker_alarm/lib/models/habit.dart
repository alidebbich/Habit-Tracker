
class Habit {
  final String id;
  final String name;
  final String icon; // Could be asset path or icon code
  final bool isDaily;
  final List<int> weekdays; // 0 = Sunday, 1 = Monday, etc. Empty if daily
  final int timesPerWeek; // For X times per week frequency
  final bool isMorningAnchor; // If this habit gates the alarm
  final DateTime createdAt;
  
  // Streak tracking
  final Set<DateTime> completedDates; // Dates when habit was completed
  
  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.isDaily = true,
    this.weekdays = const [],
    this.timesPerWeek = 0,
    this.isMorningAnchor = false,
    DateTime? createdAt,
    Set<DateTime>? completedDates,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.completedDates = completedDates ?? {};
  
  // Check if habit is completed for a given date
  bool isCompletedOn(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return completedDates.contains(normalizedDate);
  }
  
  // Get current streak
  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = completedDates.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order
    
    int streak = 0;
    final today = DateTime.now();
    DateTime? expectedDate;
    
    for (final date in sortedDates) {
      if (streak == 0) {
        // First date - check if it's today or yesterday
        final diff = today.difference(date).inDays;
        if (diff == 0 || diff == 1) {
          streak = 1;
          expectedDate = date.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else {
        // Check if this date is exactly one day before expected
        final diff = expectedDate!.difference(date).inDays;
        if (diff == 1) {
          streak++;
          expectedDate = date.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
    
    return streak;
  }
  
  // Get best streak
  int getBestStreak() {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = completedDates.toList()
      ..sort((a, b) => a.compareTo(b)); // Ascending order
    
    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? previousDate;
    
    for (final date in sortedDates) {
      if (previousDate == null) {
        currentStreak = 1;
      } else {
        // Check if dates are consecutive
        final diff = date.difference(previousDate).inDays;
        if (diff == 1) {
          currentStreak++;
        } else {
          maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
          currentStreak = 1;
        }
      }
      previousDate = date;
    }
    
    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }
  
  // Get completion percentage for last 30 days
  double getCompletionPercentage() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    int completedInLast30Days = 0;
    
    for (final date in completedDates) {
      if (date.isAfter(thirtyDaysAgo)) {
        completedInLast30Days++;
      }
    }
    
    return (completedInLast30Days / 30) * 100;
  }
  
  // Toggle completion for a date
  Habit toggleCompletion(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final newCompletedDates = Set<DateTime>.from(completedDates);
    
    if (newCompletedDates.contains(normalizedDate)) {
      newCompletedDates.remove(normalizedDate);
    } else {
      newCompletedDates.add(normalizedDate);
    }
    
    return Habit(
      id: id,
      name: name,
      icon: icon,
      isDaily: isDaily,
      weekdays: List.from(weekdays),
      timesPerWeek: timesPerWeek,
      isMorningAnchor: isMorningAnchor,
      createdAt: createdAt,
      completedDates: newCompletedDates,
    );
  }
  
  // Copy with
  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    bool? isDaily,
    List<int>? weekdays,
    int? timesPerWeek,
    bool? isMorningAnchor,
    DateTime? createdAt,
    Set<DateTime>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDaily: isDaily ?? this.isDaily,
      weekdays: weekdays ?? List.from(this.weekdays),
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      isMorningAnchor: isMorningAnchor ?? this.isMorningAnchor,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? Set.from(this.completedDates),
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isDaily': isDaily,
      'weekdays': weekdays,
      'timesPerWeek': timesPerWeek,
      'isMorningAnchor': isMorningAnchor,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    };
  }
  
  // Create from JSON
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      isDaily: json['isDaily'] ?? true,
      weekdays: List<int>.from(json['weekdays'] ?? []),
      timesPerWeek: json['timesPerWeek'] ?? 0,
      isMorningAnchor: json['isMorningAnchor'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedDates: Set<DateTime>.from(
        (json['completedDates'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d))
                .toList() ??
            []),
    );
  }
}
