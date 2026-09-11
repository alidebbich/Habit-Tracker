import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habit.dart';
import 'database_helper.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository());

class HabitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic> _habitToRow(Habit habit) => {
        'id': habit.id,
        'name': habit.name,
        'icon': habit.icon,
        'isDaily': habit.isDaily ? 1 : 0,
        'weekdays': jsonEncode(habit.weekdays),
        'timesPerWeek': habit.timesPerWeek,
        'isMorningAnchor': habit.isMorningAnchor ? 1 : 0,
        'createdAt': habit.createdAt.toIso8601String(),
        'completedDates': jsonEncode(
          habit.completedDates.map((d) => d.toIso8601String()).toList(),
        ),
      };

  Habit _habitFromRow(Map<String, dynamic> row) => Habit(
        id: row['id'] as String,
        name: row['name'] as String,
        icon: row['icon'] as String,
        isDaily: (row['isDaily'] as int) == 1,
        weekdays: List<int>.from(
            jsonDecode(row['weekdays'] as String? ?? '[]')),
        timesPerWeek: row['timesPerWeek'] as int? ?? 0,
        isMorningAnchor: (row['isMorningAnchor'] as int?) == 1,
        createdAt: DateTime.parse(row['createdAt'] as String),
        completedDates: Set<DateTime>.from(
          (jsonDecode(row['completedDates'] as String? ?? '[]') as List)
              .map((d) => DateTime.parse(d as String)),
        ),
      );

  Future<void> insertHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.insert(
      'habits',
      _habitToRow(habit),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Habit>> getHabits() async {
    final db = await _dbHelper.database;
    final rows = await db.query('habits', orderBy: 'createdAt ASC');
    return rows.map(_habitFromRow).toList();
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.update(
      'habits',
      _habitToRow(habit),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final db = await _dbHelper.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }
}
