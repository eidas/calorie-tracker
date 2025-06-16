import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zubora_calorie/database/database_helper.dart';
import 'package:zubora_calorie/data/repositories/food_entry_repository_impl.dart';
import 'package:zubora_calorie/domain/entities/food_entry.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late FoodEntryRepositoryImpl foodEntryRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.deleteDatabase();
    foodEntryRepository = FoodEntryRepositoryImpl(databaseHelper);
    
    await databaseHelper.database;
    
    // Insert test user and food for foreign key constraints
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
    
    await databaseHelper.insert('foods', {
      'id': 'test-food',
      'name': 'Test Food',
      'calories': 100,
      'category': 0,
      'is_custom': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
  });

  tearDown(() async {
    await databaseHelper.closeDatabase();
  });

  group('FoodEntryRepositoryImpl', () {
    test('should save and retrieve food entry', () async {
      final now = DateTime.now();
      final foodEntry = FoodEntry(
        id: 'entry-1',
        userId: 'test-user',
        foodId: 'test-food',
        date: now,
        quantity: 1.5,
        mealType: MealType.breakfast,
        calories: 150,
        note: 'Test note',
        createdAt: now,
        updatedAt: now,
      );

      await foodEntryRepository.saveFoodEntry(foodEntry);
      
      final entries = await foodEntryRepository.getFoodEntriesByDate(now);
      expect(entries.length, equals(1));
      expect(entries.first.quantity, equals(1.5));
      expect(entries.first.mealType, equals(MealType.breakfast));
      expect(entries.first.calories, equals(150));
      expect(entries.first.note, equals('Test note'));
    });

    test('should calculate total calories for date', () async {
      final now = DateTime.now();
      final entries = [
        FoodEntry(
          id: 'entry-1',
          userId: 'test-user',
          foodId: 'test-food',
          date: now,
          quantity: 1.0,
          mealType: MealType.breakfast,
          calories: 100,
          createdAt: now,
          updatedAt: now,
        ),
        FoodEntry(
          id: 'entry-2',
          userId: 'test-user',
          foodId: 'test-food',
          date: now,
          quantity: 2.0,
          mealType: MealType.lunch,
          calories: 200,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final entry in entries) {
        await foodEntryRepository.saveFoodEntry(entry);
      }
      
      final totalCalories = await foodEntryRepository.getTotalCaloriesByDate(now);
      expect(totalCalories, equals(300));
    });
  });
}
