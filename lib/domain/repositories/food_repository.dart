// 食品リポジトリインターフェース
// 食品データの検索・保存・削除を担当するリポジトリの抽象定義

import '../entities/food.dart';

abstract class FoodRepository {
  /// 全ての食品データを取得
  Future<List<Food>> getAllFoods();

  /// カテゴリ別に食品データを取得
  Future<List<Food>> getFoodsByCategory(FoodCategory category);

  /// 名前で食品を検索
  Future<List<Food>> searchFoodsByName(String query);

  /// 食品データを保存
  Future<void> saveFood(Food food);

  /// 食品データを更新
  Future<void> updateFood(Food food);

  /// 食品データを削除
  Future<void> deleteFood(String foodId);

  /// カスタム食品のみを取得
  Future<List<Food>> getCustomFoods();
}
