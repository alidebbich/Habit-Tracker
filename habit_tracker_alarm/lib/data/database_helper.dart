import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // getDatabasesPath() is provided by sqflite — no extra dependency needed
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'habit_tracker_alarm.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // SQLite has no boolean or array type — use INTEGER (0/1) and TEXT (JSON)
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        isDaily INTEGER NOT NULL DEFAULT 1,
        weekdays TEXT NOT NULL DEFAULT '[]',
        timesPerWeek INTEGER NOT NULL DEFAULT 0,
        isMorningAnchor INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedDates TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        time TEXT NOT NULL,
        weekdays TEXT NOT NULL DEFAULT '[]',
        label TEXT NOT NULL,
        isEnabled INTEGER NOT NULL DEFAULT 1,
        dismissMissionType INTEGER NOT NULL DEFAULT 0,
        associatedHabitId TEXT,
        dismissMissionParam TEXT,
        snoozeDuration INTEGER NOT NULL DEFAULT 5,
        maxVolume INTEGER NOT NULL DEFAULT 100,
        vibrate INTEGER NOT NULL DEFAULT 1,
        sound TEXT NOT NULL DEFAULT 'default'
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule_tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        date TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE alarms ADD COLUMN sound TEXT NOT NULL DEFAULT 'default'
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schedule_tasks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          note TEXT,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          date TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 3) {
      // Attempt to add note column — ignore error if it already exists.
      try {
        await db.execute('ALTER TABLE schedule_tasks ADD COLUMN note TEXT');
      } catch (_) {}
    }
  }
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
