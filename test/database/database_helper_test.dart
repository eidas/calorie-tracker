import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calorie_tracker/database/database_helper.dart';

void main() {
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.deleteDatabase();
  });

  tearDown(() async {
    await databaseHelper.closeDatabase();
  });

  group('DatabaseHelper', () {
    test('should initialize database successfully', () async {
      final db = await databaseHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('should create all required tables', () async {
      final db = await databaseHelper.database;
      
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableNames = tables.map((table) => table['name']).toSet();
      expect(tableNames, containsAll(['users', 'foods', 'food_entries', 'weight_records']));
    });

    test('should enable foreign key constraints', () async {
      final db = await databaseHelper.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], equals(1));
    });

    test('should insert and query data', () async {
      final testData = {
        'id': 'test-id',
        'name': 'Test User',
        'email': 'test@example.com',
        'height': 170.0,
        'target_weight': 65.0,
        'target_calories': 2000,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      await databaseHelper.insert('users', testData);
      
      final results = await databaseHelper.query('users', where: 'id = ?', whereArgs: ['test-id']);
      expect(results.length, equals(1));
      expect(results.first['name'], equals('Test User'));
    });

    test('should update data', () async {
      final testData = {
        'id': 'test-id',
        'name': 'Test User',
        'email': 'test@example.com',
        'height': 170.0,
        'target_weight': 65.0,
        'target_calories': 2000,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      await databaseHelper.insert('users', testData);
      
      final updatedData = {
        'name': 'Updated User',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      final rowsAffected = await databaseHelper.update(
        'users', 
        updatedData, 
        where: 'id = ?', 
        whereArgs: ['test-id']
      );
      
      expect(rowsAffected, equals(1));
      
      final results = await databaseHelper.query('users', where: 'id = ?', whereArgs: ['test-id']);
      expect(results.first['name'], equals('Updated User'));
    });

    test('should delete data', () async {
      final testData = {
        'id': 'test-id',
        'name': 'Test User',
        'email': 'test@example.com',
        'height': 170.0,
        'target_weight': 65.0,
        'target_calories': 2000,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      await databaseHelper.insert('users', testData);
      
      final rowsAffected = await databaseHelper.delete('users', where: 'id = ?', whereArgs: ['test-id']);
      expect(rowsAffected, equals(1));
      
      final results = await databaseHelper.query('users', where: 'id = ?', whereArgs: ['test-id']);
      expect(results.isEmpty, isTrue);
    });

    test('should handle transactions', () async {
      await databaseHelper.transaction((txn) async {
        await txn.insert('users', {
          'id': 'user-1',
          'name': 'User 1',
          'email': 'user1@example.com',
          'height': 170.0,
          'target_weight': 65.0,
          'target_calories': 2000,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
        
        await txn.insert('users', {
          'id': 'user-2',
          'name': 'User 2',
          'email': 'user2@example.com',
          'height': 175.0,
          'target_weight': 70.0,
          'target_calories': 2200,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      });
      
      final results = await databaseHelper.query('users');
      expect(results.length, equals(2));
    });
  });
}
