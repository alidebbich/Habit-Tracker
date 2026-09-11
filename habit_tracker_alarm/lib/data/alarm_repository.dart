import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../models/alarm.dart';
import 'database_helper.dart';

final alarmRepositoryProvider = Provider((ref) => AlarmRepository());

class AlarmRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Map<String, dynamic> _alarmToRow(Alarm alarm) => {
        'id': alarm.id,
        'time': alarm.time.toIso8601String(),
        'weekdays': jsonEncode(alarm.weekdays),
        'label': alarm.label,
        'isEnabled': alarm.isEnabled ? 1 : 0,
        'dismissMissionType': alarm.dismissMissionType.index,
        'associatedHabitId': alarm.associatedHabitId,
        'dismissMissionParam': alarm.dismissMissionParam,
        'snoozeDuration': alarm.snoozeDuration,
        'maxVolume': alarm.maxVolume,
        'vibrate': alarm.vibrate ? 1 : 0,
        'sound': alarm.sound,
      };

  Alarm _alarmFromRow(Map<String, dynamic> row) => Alarm(
        id: row['id'] as String,
        time: DateTime.parse(row['time'] as String),
        weekdays: List<int>.from(
            jsonDecode(row['weekdays'] as String? ?? '[]')),
        label: row['label'] as String? ?? 'Alarm',
        isEnabled: (row['isEnabled'] as int?) == 1,
        dismissMissionType: DismissMissionType
            .values[row['dismissMissionType'] as int? ?? 0],
        associatedHabitId: row['associatedHabitId'] as String?,
        dismissMissionParam: row['dismissMissionParam'] as String?,
        snoozeDuration: row['snoozeDuration'] as int? ?? 5,
        maxVolume: row['maxVolume'] as int? ?? 100,
        vibrate: (row['vibrate'] as int?) == 1,
        sound: row['sound'] as String? ?? 'default',
      );

  Future<void> insertAlarm(Alarm alarm) async {
    final db = await _dbHelper.database;
    await db.insert(
      'alarms',
      _alarmToRow(alarm),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Alarm>> getAlarms() async {
    final db = await _dbHelper.database;
    final rows = await db.query('alarms', orderBy: 'time ASC');
    return rows.map(_alarmFromRow).toList();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final db = await _dbHelper.database;
    await db.update(
      'alarms',
      _alarmToRow(alarm),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  Future<void> deleteAlarm(String id) async {
    final db = await _dbHelper.database;
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }
}
