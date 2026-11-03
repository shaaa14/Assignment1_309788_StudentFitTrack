import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FitTrackDatabase {
  static final FitTrackDatabase instance = FitTrackDatabase._init();

  static Database? _database;

  FitTrackDatabase._init();

  // Open database
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'student_fittrack.db');

    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDatabase,
    );

    return db;
  }

  // Create table
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fit_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_name TEXT NOT NULL,
        category TEXT NOT NULL,
        duration INTEGER NOT NULL,
        workout_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Insert workout
  Future<int> insertWorkout(Map<String, dynamic> workout) async {
    final db = await database;

    workout['created_at'] = DateTime.now().toIso8601String();

    return await db.insert('fit_tracks', workout);
  }

  // Retrieve workout with pagination
  Future<List<Map<String, dynamic>>> getWorkouts(int page) async {
    final db = await database;

    const limit = 10;
    final offset = (page - 1) * limit;

    return await db.query(
      'fit_tracks',
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Count all workouts
  Future<int> getWorkoutCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM fit_tracks',
    );

    return result.first['total'] as int;
  }

  // Update workout
  Future<int> updateWorkout(int id, Map<String, dynamic> workout) async {
    final db = await database;

    return await db.update(
      'fit_tracks',
      workout,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete workout
  Future<int> deleteWorkout(int id) async {
    final db = await database;

    return await db.delete('fit_tracks', where: 'id = ?', whereArgs: [id]);
  }
}
