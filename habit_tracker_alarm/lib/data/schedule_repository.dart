import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/schedule_task.dart';
import 'database_helper.dart';

final scheduleRepositoryProvider = Provider((ref) => ScheduleRepository());

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insertTask(ScheduleTask task) async {
    final db = await _dbHelper.database;
    await db.insert(
      'schedule_tasks',
      task.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScheduleTask>> getTasks(DateTime date) async {
    final db = await _dbHelper.database;
    final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
    
    final rows = await db.query(
      'schedule_tasks',
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'startTime ASC',
    );
    return rows.map(ScheduleTask.fromJson).toList();
  }

  Future<void> updateTask(ScheduleTask task) async {
    final db = await _dbHelper.database;
    await db.update(
      'schedule_tasks',
      task.toJson(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await _dbHelper.database;
    await db.delete('schedule_tasks', where: 'id = ?', whereArgs: [id]);
  }
}
