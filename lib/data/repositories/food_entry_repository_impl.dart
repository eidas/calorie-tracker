// 食事記録リポジトリ実装
// SQLiteを使用した食事記録のCRUD操作を実装

import '../../domain/entities/food_entry.dart';
import '../../domain/repositories/food_entry_repository.dart';
import '../models/food_entry_model.dart';
import '../../database/database_helper.dart';

class FoodEntryRepositoryImpl implements FoodEntryRepository {
  final DatabaseHelper _databaseHelper;

  FoodEntryRepositoryImpl(this._databaseHelper);

  @override
  Future<List<FoodEntry>> getFoodEntriesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final maps = await _databaseHelper.query(
      'food_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'date ASC, meal_type ASC',
    );
    
    return maps.map((map) => FoodEntryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<FoodEntry>> getFoodEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));
    
    final maps = await _databaseHelper.query(
      'food_entries',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'date ASC, meal_type ASC',
    );
    
    return maps.map((map) => FoodEntryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<FoodEntry>> getFoodEntriesByMealType(
    DateTime date,
    MealType mealType,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final maps = await _databaseHelper.query(
      'food_entries',
      where: 'date >= ? AND date < ? AND meal_type = ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
        mealType.index,
      ],
      orderBy: 'date ASC',
    );
    
    return maps.map((map) => FoodEntryModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<void> saveFoodEntry(FoodEntry entry) async {
    final entryModel = FoodEntryModel.fromEntity(entry);
    await _databaseHelper.insert('food_entries', entryModel.toMap());
  }

  @override
  Future<void> updateFoodEntry(FoodEntry entry) async {
    final entryModel = FoodEntryModel.fromEntity(entry);
    await _databaseHelper.update(
      'food_entries',
      entryModel.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  @override
  Future<void> deleteFoodEntry(String entryId) async {
    await _databaseHelper.delete(
      'food_entries',
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  @override
  Future<int> getTotalCaloriesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await _databaseHelper.rawQuery(
      'SELECT SUM(calories) as total FROM food_entries WHERE date >= ? AND date < ?',
      [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    
    return (result.first['total'] as int?) ?? 0;
  }

  Future<FoodEntry?> getFoodEntryById(String entryId) async {
    final maps = await _databaseHelper.query(
      'food_entries',
      where: 'id = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return FoodEntryModel.fromMap(maps.first).toEntity();
  }

  Future<List<FoodEntry>> getFoodEntriesByUserId(String userId) async {
    final maps = await _databaseHelper.query(
      'food_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, meal_type ASC',
    );
    
    return maps.map((map) => FoodEntryModel.fromMap(map).toEntity()).toList();
  }

  Future<Map<MealType, int>> getCaloriesByMealType(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await _databaseHelper.rawQuery(
      'SELECT meal_type, SUM(calories) as total FROM food_entries '
      'WHERE date >= ? AND date < ? GROUP BY meal_type',
      [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    
    final caloriesByMealType = <MealType, int>{};
    for (final row in result) {
      final mealType = MealType.values[row['meal_type'] as int];
      final calories = (row['total'] as int?) ?? 0;
      caloriesByMealType[mealType] = calories;
    }
    
    return caloriesByMealType;
  }

  Future<List<Map<String, dynamic>>> getDailyCalorieTrend(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));
    
    final result = await _databaseHelper.rawQuery(
      'SELECT DATE(date/1000, "unixepoch") as date, SUM(calories) as total '
      'FROM food_entries WHERE date >= ? AND date < ? '
      'GROUP BY DATE(date/1000, "unixepoch") ORDER BY date ASC',
      [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    
    return result;
  }

  Future<int> getFoodEntryCount() async {
    final result = await _databaseHelper.rawQuery(
      'SELECT COUNT(*) as count FROM food_entries',
    );
    return result.first['count'] as int;
  }

  Future<void> deleteFoodEntriesByUserId(String userId) async {
    await _databaseHelper.delete(
      'food_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteFoodEntriesByFoodId(String foodId) async {
    await _databaseHelper.delete(
      'food_entries',
      where: 'food_id = ?',
      whereArgs: [foodId],
    );
  }
}
