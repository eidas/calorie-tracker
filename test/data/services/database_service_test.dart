import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zubora_calorie/database/database_helper.dart';
import 'package:zubora_calorie/data/services/database_service.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
    await databaseService.initialize();
  });

  tearDown(() async {
    await databaseService.clearAllData();
  });

  group('DatabaseService', () {
    test('should initialize database successfully', () async {
      expect(databaseService.isInitialized, isTrue);
    });

    test('should provide access to all repositories', () async {
      expect(databaseService.foodRepository, isNotNull);
      expect(databaseService.foodEntryRepository, isNotNull);
      expect(databaseService.userRepository, isNotNull);
      expect(databaseService.weightRepository, isNotNull);
    });

    test('should handle transactions', () async {
      await databaseService.transaction((repositories) async {
        // This test verifies transaction handling works
        expect(repositories, isNotNull);
      });
    });

    test('should clear all data', () async {
      // Insert some test data first
      await databaseService.databaseHelper.insert('users', {
        'id': 'test-user',
        'name': 'Test User',
        'email': 'test@example.com',
        'height': 170.0,
        'target_weight': 65.0,
        'target_calories': 2000,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      final beforeCount = await databaseService.getDataCounts();
      expect(beforeCount['users'], equals(1));

      await databaseService.clearAllData();

      final afterCount = await databaseService.getDataCounts();
      expect(afterCount['users'], equals(0));
    });

    test('should get data counts', () async {
      final counts = await databaseService.getDataCounts();
      expect(counts, isA<Map<String, int>>());
      expect(counts.keys, containsAll(['users', 'foods', 'food_entries', 'weight_records']));
    });
  });
}
