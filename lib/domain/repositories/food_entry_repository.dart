// 食事記録リポジトリインターフェース
// 食事記録の日付別取得・保存・削除を担当するリポジトリの抽象定義

import '../entities/food_entry.dart';

abstract class FoodEntryRepository {
  /// 特定の日付の食事記録を取得
  Future<List<FoodEntry>> getFoodEntriesByDate(DateTime date);

  /// 日付範囲の食事記録を取得
  Future<List<FoodEntry>> getFoodEntriesByDateRange(DateTime startDate, DateTime endDate);

  /// 食事タイプ別に食事記録を取得
  Future<List<FoodEntry>> getFoodEntriesByMealType(DateTime date, MealType mealType);

  /// 食事記録を保存
  Future<void> saveFoodEntry(FoodEntry entry);

  /// 食事記録を更新
  Future<void> updateFoodEntry(FoodEntry entry);

  /// 食事記録を削除
  Future<void> deleteFoodEntry(String entryId);

  /// 特定の日付の合計カロリーを取得
  Future<int> getTotalCaloriesByDate(DateTime date);
}
