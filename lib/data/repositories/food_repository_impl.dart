// 食品リポジトリ実装
// SQLiteを使用した食品データのCRUD操作を実装

import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../models/food_model.dart';
import '../../database/database_helper.dart';

class FoodRepositoryImpl implements FoodRepository {
  final DatabaseHelper _databaseHelper;

  FoodRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Food>> getAllFoods() async {
    final maps = await _databaseHelper.query(
      'foods',
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => FoodModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<Food>> getFoodsByCategory(FoodCategory category) async {
    final maps = await _databaseHelper.query(
      'foods',
      where: 'category = ?',
      whereArgs: [category.index],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => FoodModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<List<Food>> searchFoodsByName(String query) async {
    final maps = await _databaseHelper.query(
      'foods',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => FoodModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<void> saveFood(Food food) async {
    final foodModel = FoodModel.fromEntity(food);
    await _databaseHelper.insert('foods', foodModel.toMap());
  }

  @override
  Future<void> updateFood(Food food) async {
    final foodModel = FoodModel.fromEntity(food);
    await _databaseHelper.update(
      'foods',
      foodModel.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  @override
  Future<void> deleteFood(String foodId) async {
    await _databaseHelper.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [foodId],
    );
  }

  @override
  Future<List<Food>> getCustomFoods() async {
    final maps = await _databaseHelper.query(
      'foods',
      where: 'is_custom = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => FoodModel.fromMap(map).toEntity()).toList();
  }

  Future<Food?> getFoodById(String foodId) async {
    final maps = await _databaseHelper.query(
      'foods',
      where: 'id = ?',
      whereArgs: [foodId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return FoodModel.fromMap(maps.first).toEntity();
  }

  Future<List<Food>> getFoodsById(List<String> foodIds) async {
    if (foodIds.isEmpty) return [];
    
    final placeholders = foodIds.map((_) => '?').join(',');
    final maps = await _databaseHelper.rawQuery(
      'SELECT * FROM foods WHERE id IN ($placeholders) ORDER BY name ASC',
      foodIds,
    );
    
    return maps.map((map) => FoodModel.fromMap(map).toEntity()).toList();
  }

  Future<int> getFoodCount() async {
    final result = await _databaseHelper.rawQuery('SELECT COUNT(*) as count FROM foods');
    return result.first['count'] as int;
  }

  Future<List<Food>> getFoodsPaginated({
    int offset = 0,
    int limit = 20,
    FoodCategory? category,
    bool? isCustom,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (category != null) {
      whereClause += 'category = ?';
      whereArgs.add(category.index);
    }
    
    if (isCustom != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_custom = ?';
      whereArgs.add(isCustom ? 1 : 0);
    }
    
    final maps = await _databaseHelper.query(
      'foods',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => FoodModel.fromMap(map).toEntity()).toList();
  }
}
