import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:calorie_tracker/database/database_helper.dart';
import 'package:calorie_tracker/data/repositories/food_repository_impl.dart';
import 'package:calorie_tracker/domain/entities/food.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late FoodRepositoryImpl foodRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.deleteDatabase();
    foodRepository = FoodRepositoryImpl(databaseHelper);
    
    await databaseHelper.database;
  });

  tearDown(() async {
    await databaseHelper.closeDatabase();
  });

  group('FoodRepositoryImpl', () {
    test('should save and retrieve food', () async {
      final food = Food(
        id: 'food-1',
        name: 'Apple',
        calories: 52,
        category: FoodCategory.fruit,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await foodRepository.saveFood(food);
      
      final foods = await foodRepository.getAllFoods();
      expect(foods.length, equals(1));
      expect(foods.first.name, equals('Apple'));
      expect(foods.first.calories, equals(52));
      expect(foods.first.category, equals(FoodCategory.fruits));
    });

    test('should get foods by category', () async {
      final apple = Food(
        id: 'food-1',
        name: 'Apple',
        calories: 52,
        category: FoodCategory.fruit,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final chicken = Food(
        id: 'food-2',
        name: 'Chicken Breast',
        calories: 165,
        category: FoodCategory.protein,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await foodRepository.saveFood(apple);
      await foodRepository.saveFood(chicken);
      
      final fruits = await foodRepository.getFoodsByCategory(FoodCategory.fruit);
      expect(fruits.length, equals(1));
      expect(fruits.first.name, equals('Apple'));
      
      final proteins = await foodRepository.getFoodsByCategory(FoodCategory.protein);
      expect(proteins.length, equals(1));
      expect(proteins.first.name, equals('Chicken Breast'));
    });

    test('should search foods by name', () async {
      final foods = [
        Food(
          id: 'food-1',
          name: 'Apple',
          calories: 52,
          category: FoodCategory.fruit,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Food(
          id: 'food-2',
          name: 'Apple Pie',
          calories: 237,
          category: FoodCategory.sweet,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Food(
          id: 'food-3',
          name: 'Banana',
          calories: 89,
          category: FoodCategory.fruit,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final food in foods) {
        await foodRepository.saveFood(food);
      }
      
      final appleResults = await foodRepository.searchFoodsByName('Apple');
      expect(appleResults.length, equals(2));
      expect(appleResults.map((f) => f.name), containsAll(['Apple', 'Apple Pie']));
      
      final bananaResults = await foodRepository.searchFoodsByName('Banana');
      expect(bananaResults.length, equals(1));
      expect(bananaResults.first.name, equals('Banana'));
    });

    test('should update food', () async {
      final food = Food(
        id: 'food-1',
        name: 'Apple',
        calories: 52,
        category: FoodCategory.fruit,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await foodRepository.saveFood(food);
      
      final updatedFood = food.copyWith(
        name: 'Green Apple',
        calories: 58,
        updatedAt: DateTime.now(),
      );
      
      await foodRepository.updateFood(updatedFood);
      
      final foods = await foodRepository.getAllFoods();
      expect(foods.length, equals(1));
      expect(foods.first.name, equals('Green Apple'));
      expect(foods.first.calories, equals(58));
    });

    test('should delete food', () async {
      final food = Food(
        id: 'food-1',
        name: 'Apple',
        calories: 52,
        category: FoodCategory.fruit,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await foodRepository.saveFood(food);
      
      final foodsBefore = await foodRepository.getAllFoods();
      expect(foodsBefore.length, equals(1));
      
      await foodRepository.deleteFood('food-1');
      
      final foodsAfter = await foodRepository.getAllFoods();
      expect(foodsAfter.length, equals(0));
    });

    test('should get custom foods only', () async {
      final regularFood = Food(
        id: 'food-1',
        name: 'Apple',
        calories: 52,
        category: FoodCategory.fruit,
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customFood = Food(
        id: 'food-2',
        name: 'My Special Recipe',
        calories: 300,
        category: FoodCategory.other,
        isCustom: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await foodRepository.saveFood(regularFood);
      await foodRepository.saveFood(customFood);
      
      final customFoods = await foodRepository.getCustomFoods();
      expect(customFoods.length, equals(1));
      expect(customFoods.first.name, equals('My Special Recipe'));
      expect(customFoods.first.isCustom, isTrue);
    });
  });
}
