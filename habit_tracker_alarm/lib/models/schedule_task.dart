class ScheduleTask {
  final String id;
  final String title;
  final String? note;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime date;
  final bool isCompleted;

  ScheduleTask({
    required this.id,
    required this.title,
    this.note,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.isCompleted = false,
  });

  ScheduleTask copyWith({
    String? id,
    String? title,
    Object? note = _sentinel,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? date,
    bool? isCompleted,
  }) {
    return ScheduleTask(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note == _sentinel ? this.note : note as String?,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'date': date.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory ScheduleTask.fromJson(Map<String, dynamic> json) {
    return ScheduleTask(
      id: json['id'],
      title: json['title'],
      note: json['note'] as String?,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      date: DateTime.parse(json['date']),
      isCompleted: (json['isCompleted'] as int) == 1,
    );
  }
}

const Object _sentinel = Object();
