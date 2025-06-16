// データベースマイグレーション
// スキーマのバージョン管理とマイグレーション処理を担当

import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static const int currentVersion = 1;

  static Future<void> runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigration(db, version);
    }
  }

  static Future<void> _runMigration(Database db, int version) async {
    switch (version) {
      case 1:
        await _createInitialTables(db);
        break;
      default:
        throw Exception('Unknown migration version: $version');
    }
  }

  static Future<void> _createInitialTables(Database db) async {
    await _createUsersTable(db);
    await _createFoodsTable(db);
    await _createFoodEntriesTable(db);
    await _createWeightRecordsTable(db);
    await _createIndexes(db);
  }

  static Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        height REAL NOT NULL,
        target_weight REAL NOT NULL,
        target_calories INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createFoodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE foods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        category INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createFoodEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE food_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        food_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        quantity REAL NOT NULL,
        meal_type INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createWeightRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE weight_records (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        weight REAL NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_foods_name ON foods (name)');
    await db.execute('CREATE INDEX idx_foods_category ON foods (category)');
    await db.execute('CREATE INDEX idx_foods_is_custom ON foods (is_custom)');
    
    await db.execute('CREATE INDEX idx_food_entries_user_id ON food_entries (user_id)');
    await db.execute('CREATE INDEX idx_food_entries_date ON food_entries (date)');
    await db.execute('CREATE INDEX idx_food_entries_user_date ON food_entries (user_id, date)');
    await db.execute('CREATE INDEX idx_food_entries_meal_type ON food_entries (meal_type)');
    
    await db.execute('CREATE INDEX idx_weight_records_user_id ON weight_records (user_id)');
    await db.execute('CREATE INDEX idx_weight_records_date ON weight_records (date)');
    await db.execute('CREATE INDEX idx_weight_records_user_date ON weight_records (user_id, date)');
    
    await db.execute('CREATE UNIQUE INDEX idx_weight_records_user_date_unique ON weight_records (user_id, date)');
  }
}
