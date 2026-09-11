import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/schedule_task.dart';
import '../data/schedule_repository.dart';

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

final scheduleProvider = FutureProvider<List<ScheduleTask>>((ref) async {
  final repo = ref.watch(scheduleRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.getTasks(date);
});
