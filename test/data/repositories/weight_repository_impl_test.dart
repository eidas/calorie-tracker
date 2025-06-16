import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calorie_tracker/database/database_helper.dart';
import 'package:calorie_tracker/data/repositories/weight_repository_impl.dart';
import 'package:calorie_tracker/domain/entities/weight_record.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late WeightRepositoryImpl weightRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.deleteDatabase();
    weightRepository = WeightRepositoryImpl(databaseHelper);
    
    await databaseHelper.database;
    
    // Insert test user for foreign key constraints
    await databaseHelper.insert('users', {
      'id': 'test-user',
      'name': 'Test User',
      'email': 'test@example.com',
      'height': 170.0,
      'target_weight': 65.0,
      'target_calories': 2000,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  });

  tearDown(() async {
    await databaseHelper.closeDatabase();
  });

  group('WeightRepositoryImpl', () {
    test('should save and retrieve weight record', () async {
      final now = DateTime.now();
      final weightRecord = WeightRecord(
        id: 'weight-1',
        userId: 'test-user',
        date: now,
        weight: 68.5,
        note: 'Morning weight',
        createdAt: now,
        updatedAt: now,
      );

      await weightRepository.saveWeightRecord(weightRecord);
      
      final record = await weightRepository.getWeightRecordByDate('test-user', now);
      expect(record, isNotNull);
      expect(record!.weight, equals(68.5));
      expect(record.note, equals('Morning weight'));
    });

    test('should get weight records by date range', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final dayBeforeYesterday = today.subtract(const Duration(days: 2));
      final tomorrow = today.add(const Duration(days: 1));

      final records = [
        WeightRecord(
          id: 'weight-1',
          userId: 'test-user',
          date: dayBeforeYesterday,
          weight: 70.0,
          createdAt: dayBeforeYesterday,
          updatedAt: dayBeforeYesterday,
        ),
        WeightRecord(
          id: 'weight-2',
          userId: 'test-user',
          date: yesterday,
          weight: 69.5,
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        WeightRecord(
          id: 'weight-3',
          userId: 'test-user',
          date: today,
          weight: 69.0,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-4',
          userId: 'test-user',
          date: tomorrow,
          weight: 68.5,
          createdAt: tomorrow,
          updatedAt: tomorrow,
        ),
      ];

      for (final record in records) {
        await weightRepository.saveWeightRecord(record);
      }
      
      final rangeRecords = await weightRepository.getWeightRecordsByDateRange(
        'test-user',
        yesterday,
        today,
      );
      
      expect(rangeRecords.length, equals(2));
      expect(rangeRecords.map((r) => r.weight), containsAll([69.5, 69.0]));
    });

    test('should calculate average weight', () async {
      final today = DateTime.now();
      final records = [
        WeightRecord(
          id: 'weight-1',
          userId: 'test-user',
          date: today.subtract(const Duration(days: 2)),
          weight: 70.0,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-2',
          userId: 'test-user',
          date: today.subtract(const Duration(days: 1)),
          weight: 69.0,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-3',
          userId: 'test-user',
          date: today,
          weight: 68.0,
          createdAt: today,
          updatedAt: today,
        ),
      ];

      for (final record in records) {
        await weightRepository.saveWeightRecord(record);
      }
      
      final averageWeight = await weightRepository.getAverageWeight(
        'test-user',
        today.subtract(const Duration(days: 2)),
        today,
      );
      
      expect(averageWeight, equals(69.0));
    });

    test('should get weight statistics', () async {
      final today = DateTime.now();
      final records = [
        WeightRecord(
          id: 'weight-1',
          userId: 'test-user',
          date: today.subtract(const Duration(days: 3)),
          weight: 72.0,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-2',
          userId: 'test-user',
          date: today.subtract(const Duration(days: 2)),
          weight: 70.5,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-3',
          userId: 'test-user',
          date: today.subtract(const Duration(days: 1)),
          weight: 69.0,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-4',
          userId: 'test-user',
          date: today,
          weight: 68.5,
          createdAt: today,
          updatedAt: today,
        ),
      ];

      for (final record in records) {
        await weightRepository.saveWeightRecord(record);
      }
      
      final stats = await weightRepository.getWeightStatistics(
        'test-user',
        today.subtract(const Duration(days: 3)),
        today,
      );
      
      expect(stats['min'], equals(68.5));
      expect(stats['max'], equals(72.0));
      expect(stats['average'], equals(70.0));
      expect(stats['count'], equals(4));
    });

    test('should update weight record', () async {
      final now = DateTime.now();
      final weightRecord = WeightRecord(
        id: 'weight-1',
        userId: 'test-user',
        date: now,
        weight: 68.5,
        note: 'Morning weight',
        createdAt: now,
        updatedAt: now,
      );

      await weightRepository.saveWeightRecord(weightRecord);
      
      final updatedRecord = weightRecord.copyWith(
        weight: 69.0,
        note: 'Evening weight',
        updatedAt: DateTime.now(),
      );
      
      await weightRepository.updateWeightRecord(updatedRecord);
      
      final record = await weightRepository.getWeightRecordByDate('test-user', now);
      expect(record!.weight, equals(69.0));
      expect(record.note, equals('Evening weight'));
    });

    test('should delete weight record', () async {
      final now = DateTime.now();
      final weightRecord = WeightRecord(
        id: 'weight-1',
        userId: 'test-user',
        date: now,
        weight: 68.5,
        createdAt: now,
        updatedAt: now,
      );

      await weightRepository.saveWeightRecord(weightRecord);
      
      final recordBefore = await weightRepository.getWeightRecordByDate('test-user', now);
      expect(recordBefore, isNotNull);
      
      await weightRepository.deleteWeightRecord('weight-1');
      
      final recordAfter = await weightRepository.getWeightRecordByDate('test-user', now);
      expect(recordAfter, isNull);
    });

    test('should check if weight record exists for date', () async {
      final now = DateTime.now();
      final weightRecord = WeightRecord(
        id: 'weight-1',
        userId: 'test-user',
        date: now,
        weight: 68.5,
        createdAt: now,
        updatedAt: now,
      );

      final existsBefore = await weightRepository.hasWeightRecordForDate('test-user', now);
      expect(existsBefore, isFalse);
      
      await weightRepository.saveWeightRecord(weightRecord);
      
      final existsAfter = await weightRepository.hasWeightRecordForDate('test-user', now);
      expect(existsAfter, isTrue);
    });

    test('should get weight records by user id', () async {
      // Insert another user
      await databaseHelper.insert('users', {
        'id': 'test-user-2',
        'name': 'Test User 2',
        'email': 'test2@example.com',
        'height': 175.0,
        'target_weight': 70.0,
        'target_calories': 2200,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      final today = DateTime.now();
      final records = [
        WeightRecord(
          id: 'weight-1',
          userId: 'test-user',
          date: today.subtract(const Duration(days: 1)),
          weight: 68.5,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-2',
          userId: 'test-user-2',
          date: today.subtract(const Duration(days: 1)),
          weight: 75.0,
          createdAt: today,
          updatedAt: today,
        ),
        WeightRecord(
          id: 'weight-3',
          userId: 'test-user',
          date: today,
          weight: 68.0,
          createdAt: today,
          updatedAt: today,
        ),
      ];

      for (final record in records) {
        await weightRepository.saveWeightRecord(record);
      }
      
      final user1Records = await weightRepository.getWeightRecordsByUserId('test-user');
      expect(user1Records.length, equals(2));
      expect(user1Records.map((r) => r.weight), containsAll([68.5, 68.0]));
      
      final user2Records = await weightRepository.getWeightRecordsByUserId('test-user-2');
      expect(user2Records.length, equals(1));
      expect(user2Records.first.weight, equals(75.0));
    });
  });
}
