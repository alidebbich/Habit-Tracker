import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../data/habit_repository.dart';

final habitListProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getHabits();
});
