import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zubora_calorie/data/services/database_service.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
    await databaseService.initializeDatabase();
  });

  tearDown(() async {
    await databaseService.clearAllData();
  });

  group('DatabaseService', () {
    test('should provide access to all repositories', () {
      expect(databaseService.foodRepository, isNotNull);
      expect(databaseService.foodEntryRepository, isNotNull);
      expect(databaseService.userRepository, isNotNull);
      expect(databaseService.weightRepository, isNotNull);
    });

    test('should handle transactions', () async {
      final result = await databaseService.runInTransaction(() async {
        return 'transaction_completed';
      });
      expect(result, equals('transaction_completed'));
    });

    test('should clear all data', () async {
      final beforeCount = await databaseService.getDataCounts();
      
      await databaseService.clearAllData();

      final afterCount = await databaseService.getDataCounts();
      expect(afterCount['users'], equals(0));
      expect(afterCount['foods'], equals(0));
      expect(afterCount['food_entries'], equals(0));
      expect(afterCount['weight_records'], equals(0));
    });

    test('should get data counts', () async {
      final counts = await databaseService.getDataCounts();
      expect(counts, isA<Map<String, int>>());
      expect(counts.keys, containsAll(['users', 'foods', 'food_entries', 'weight_records']));
      expect(counts['users'], isA<int>());
      expect(counts['foods'], isA<int>());
      expect(counts['food_entries'], isA<int>());
      expect(counts['weight_records'], isA<int>());
    });
  });
}
