import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/alarm.dart';
import '../data/alarm_repository.dart';

final alarmListProvider = FutureProvider<List<Alarm>>((ref) async {
  final repo = ref.watch(alarmRepositoryProvider);
  return repo.getAlarms();
});
