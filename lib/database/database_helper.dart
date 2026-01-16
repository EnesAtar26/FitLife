import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/sleep_log_model.dart';
import '../models/water_log_model.dart';
import '../models/activity_model.dart';
import '../models/reminder_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fitlife.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const intType = 'INTEGER';
    const realType = 'REAL';

    await db.execute('''
      CREATE TABLE users (
        id $idType,
        first_name $textType,
        last_name $textType,
        email $textType UNIQUE,
        password_hash $textType,
        age $intType,
        height_cm $intType,
        weight_kg $intType,
        gender $textType,
        goal_type $textType,
        daily_step_goal $intType,
        daily_calorie_goal $intType,
        daily_water_goal $intType,
        sleep_goal_minutes $intType,
        created_at $textType,
        updated_at $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE sleep_logs (
        id $idType,
        user_id $intType,
        start_time $textType,
        end_time $textType,
        duration_minutes $intType,
        date $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE water_logs (
        id $idType,
        user_id $intType,
        date $textType,
        amount_glasses $intType,
        timestamp $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE activities (
        id $idType,
        user_id $intType,
        date $textType,
        type $textType,
        duration_minutes $intType,
        distance_km $realType,
        calories $intType,
        steps $intType,
        created_at $textType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id $idType,
        user_id $intType,
        type $textType,
        time_of_day $textType,
        is_active $intType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');
  }

  Future<int> createUser(User user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> createSleepLog(SleepLog log) async {
    final db = await instance.database;
    return await db.insert('sleep_logs', log.toMap());
  }

  Future<List<SleepLog>> getSleepLogsForUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'sleep_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return result.map((json) => SleepLog.fromMap(json)).toList();
  }

  Future<int> updateSleepLog(SleepLog log) async {
    final db = await instance.database;
    return await db.update(
      'sleep_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteSleepLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'sleep_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> createWaterLog(WaterLog log) async {
    final db = await instance.database;
    return await db.insert('water_logs', log.toMap());
  }

  Future<List<WaterLog>> getWaterLogsForUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'water_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return result.map((json) => WaterLog.fromMap(json)).toList();
  }

  Future<int> updateWaterLog(WaterLog log) async {
    final db = await instance.database;
    return await db.update(
      'water_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteWaterLog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'water_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> createActivity(Activity activity) async {
    final db = await instance.database;
    return await db.insert('activities', activity.toMap());
  }

  Future<List<Activity>> getActivitiesForUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return result.map((json) => Activity.fromMap(json)).toList();
  }

  Future<int> updateActivity(Activity activity) async {
    final db = await instance.database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final db = await instance.database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<int> createReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getRemindersForUser(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
