import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zubora_calorie/database/database_helper.dart';
import 'package:zubora_calorie/data/repositories/weight_repository_impl.dart';
import 'package:zubora_calorie/domain/entities/weight_record.dart';

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

  tearDown() async {
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
  });
}
