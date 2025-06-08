// 食品プロバイダー
// 食品データの管理とリポジトリとの連携を担当

import 'package:flutter/foundation.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';

class FoodProvider with ChangeNotifier {
  final FoodRepository _foodRepository;
  List<Food> _foods = [];
  List<Food> _customFoods = [];
  List<Food> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  FoodProvider(this._foodRepository) {
    // 初期化時に食品データを読み込み
    _loadAllFoods();
    _loadCustomFoods();
  }

  // 全ての食品
  List<Food> get foods => _foods;
  
  // カスタム食品
  List<Food> get customFoods => _customFoods;
  
  // 検索結果
  List<Food> get searchResults => _searchResults;
  
  // ローディング状態
  bool get isLoading => _isLoading;
  
  // エラーメッセージ
  String? get error => _error;
  
  // 検索クエリ
  String get searchQuery => _searchQuery;

  // 全ての食品データを読み込み
  Future<void> _loadAllFoods() async {
    _isLoading = true;
    notifyListeners();

    try {
      _foods = await _foodRepository.getAllFoods();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // カスタム食品を読み込み
  Future<void> _loadCustomFoods() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customFoods = await _foodRepository.getCustomFoods();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食品を検索
  Future<void> searchFoods(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _foodRepository.searchFoodsByName(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // カテゴリ別に食品を取得
  Future<List<Food>> getFoodsByCategory(FoodCategory category) async {
    _isLoading = true;
    notifyListeners();

    try {
      final foods = await _foodRepository.getFoodsByCategory(category);
      _error = null;
      return foods;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食品を保存（新規作成）
  Future<void> saveFood(Food food) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _foodRepository.saveFood(food);
      await _loadAllFoods();
      if (food.isCustom) {
        await _loadCustomFoods();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食品を更新
  Future<void> updateFood(Food food) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _foodRepository.updateFood(food);
      await _loadAllFoods();
      if (food.isCustom) {
        await _loadCustomFoods();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食品を削除
  Future<void> deleteFood(String foodId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _foodRepository.deleteFood(foodId);
      await _loadAllFoods();
      await _loadCustomFoods();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // エラーのクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 食品データの再読み込み
  Future<void> refreshFoods() async {
    await _loadAllFoods();
    await _loadCustomFoods();
  }
}
