import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calorie_tracker/database/database_helper.dart';
import 'package:calorie_tracker/data/repositories/food_entry_repository_impl.dart';
import 'package:calorie_tracker/domain/entities/food_entry.dart';

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

    test('should get food entries by date range', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      final entries = [
        FoodEntry(
          id: 'entry-1',
          userId: 'test-user',
          foodId: 'test-food',
          date: yesterday,
          quantity: 1.0,
          mealType: MealType.breakfast,
          calories: 100,
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        FoodEntry(
          id: 'entry-2',
          userId: 'test-user',
          foodId: 'test-food',
          date: today,
          quantity: 2.0,
          mealType: MealType.lunch,
          calories: 200,
          createdAt: today,
          updatedAt: today,
        ),
        FoodEntry(
          id: 'entry-3',
          userId: 'test-user',
          foodId: 'test-food',
          date: tomorrow,
          quantity: 1.5,
          mealType: MealType.dinner,
          calories: 150,
          createdAt: tomorrow,
          updatedAt: tomorrow,
        ),
      ];

      for (final entry in entries) {
        await foodEntryRepository.saveFoodEntry(entry);
      }
      
      final rangeEntries = await foodEntryRepository.getFoodEntriesByDateRange(
        yesterday,
        today,
      );
      
      expect(rangeEntries.length, equals(2));
      expect(rangeEntries.map((e) => e.id), containsAll(['entry-1', 'entry-2']));
    });

    test('should get food entries by meal type', () async {
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
        FoodEntry(
          id: 'entry-3',
          userId: 'test-user',
          foodId: 'test-food',
          date: now,
          quantity: 1.5,
          mealType: MealType.breakfast,
          calories: 150,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final entry in entries) {
        await foodEntryRepository.saveFoodEntry(entry);
      }
      
      final breakfastEntries = await foodEntryRepository.getFoodEntriesByMealType(
        now,
        MealType.breakfast,
      );
      
      expect(breakfastEntries.length, equals(2));
      expect(breakfastEntries.map((e) => e.id), containsAll(['entry-1', 'entry-3']));
      
      final lunchEntries = await foodEntryRepository.getFoodEntriesByMealType(
        now,
        MealType.lunch,
      );
      
      expect(lunchEntries.length, equals(1));
      expect(lunchEntries.first.id, equals('entry-2'));
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
        FoodEntry(
          id: 'entry-3',
          userId: 'test-user',
          foodId: 'test-food',
          date: now,
          quantity: 1.5,
          mealType: MealType.dinner,
          calories: 150,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final entry in entries) {
        await foodEntryRepository.saveFoodEntry(entry);
      }
      
      final totalCalories = await foodEntryRepository.getTotalCaloriesForDate(now);
      expect(totalCalories, equals(450));
    });

    test('should update food entry', () async {
      final now = DateTime.now();
      final foodEntry = FoodEntry(
        id: 'entry-1',
        userId: 'test-user',
        foodId: 'test-food',
        date: now,
        quantity: 1.0,
        mealType: MealType.breakfast,
        calories: 100,
        createdAt: now,
        updatedAt: now,
      );

      await foodEntryRepository.saveFoodEntry(foodEntry);
      
      final updatedEntry = foodEntry.copyWith(
        quantity: 2.0,
        calories: 200,
        note: 'Updated note',
        updatedAt: DateTime.now(),
      );
      
      await foodEntryRepository.updateFoodEntry(updatedEntry);
      
      final entries = await foodEntryRepository.getFoodEntriesByDate(now);
      expect(entries.length, equals(1));
      expect(entries.first.quantity, equals(2.0));
      expect(entries.first.calories, equals(200));
      expect(entries.first.note, equals('Updated note'));
    });

    test('should delete food entry', () async {
      final now = DateTime.now();
      final foodEntry = FoodEntry(
        id: 'entry-1',
        userId: 'test-user',
        foodId: 'test-food',
        date: now,
        quantity: 1.0,
        mealType: MealType.breakfast,
        calories: 100,
        createdAt: now,
        updatedAt: now,
      );

      await foodEntryRepository.saveFoodEntry(foodEntry);
      
      final entriesBefore = await foodEntryRepository.getFoodEntriesByDate(now);
      expect(entriesBefore.length, equals(1));
      
      await foodEntryRepository.deleteFoodEntry('entry-1');
      
      final entriesAfter = await foodEntryRepository.getFoodEntriesByDate(now);
      expect(entriesAfter.length, equals(0));
    });

    test('should get food entries by user id', () async {
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
          userId: 'test-user-2',
          foodId: 'test-food',
          date: now,
          quantity: 2.0,
          mealType: MealType.lunch,
          calories: 200,
          createdAt: now,
          updatedAt: now,
        ),
        FoodEntry(
          id: 'entry-3',
          userId: 'test-user',
          foodId: 'test-food',
          date: now,
          quantity: 1.5,
          mealType: MealType.dinner,
          calories: 150,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final entry in entries) {
        await foodEntryRepository.saveFoodEntry(entry);
      }
      
      final user1Entries = await foodEntryRepository.getFoodEntriesByUserId('test-user');
      expect(user1Entries.length, equals(2));
      expect(user1Entries.map((e) => e.id), containsAll(['entry-1', 'entry-3']));
      
      final user2Entries = await foodEntryRepository.getFoodEntriesByUserId('test-user-2');
      expect(user2Entries.length, equals(1));
      expect(user2Entries.first.id, equals('entry-2'));
    });
  });
}
