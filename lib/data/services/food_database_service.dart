// 食品データベースサービス
// 食品データベースの検索と詳細情報取得を提供

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';

class FoodDatabaseService {
  final FoodRepository _foodRepository;
  final String _apiBaseUrl;
  final String _apiKey;

  FoodDatabaseService(
    this._foodRepository, {
    required String apiBaseUrl,
    required String apiKey,
  }) : _apiBaseUrl = apiBaseUrl,
       _apiKey = apiKey;

  /// 食品データベースを検索
  Future<List<Food>> searchFoodDatabase(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      // まずローカルデータベースを検索
      final localResults = await _foodRepository.searchFoodsByName(query);
      
      // APIリクエストを構築
      final url = Uri.parse('$_apiBaseUrl/foods/search?query=${Uri.encodeComponent(query)}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode != 200) {
        debugPrint('食品データベース検索エラー: ${response.statusCode}');
        return localResults;
      }
      
      // レスポンスを解析
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      if (!data.containsKey('data') || !data['data'].containsKey('items')) {
        return localResults;
      }
      
      final List<dynamic> items = data['data']['items'];
      final List<Food> apiResults = [];
      
      for (var item in items) {
        try {
          final food = Food(
            id: item['foodId'] ?? 'api_${DateTime.now().millisecondsSinceEpoch}_${apiResults.length}',
            name: item['name'] ?? '不明',
            calories: item['calories'] ?? 0,
            category: _parseFoodCategory(item['category']),
            isCustom: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          apiResults.add(food);
        } catch (e) {
          debugPrint('食品データ解析エラー: $e');
        }
      }
      
      // ローカル結果とAPI結果を結合（重複を除去）
      final Map<String, Food> combinedResults = {};
      
      for (var food in localResults) {
        combinedResults[food.id] = food;
      }
      
      for (var food in apiResults) {
        if (!combinedResults.containsKey(food.id)) {
          combinedResults[food.id] = food;
        }
      }
      
      return combinedResults.values.toList();
    } catch (e) {
      debugPrint('食品データベース検索エラー: $e');
      
      // エラーが発生した場合はローカル結果のみを返す
      return await _foodRepository.searchFoodsByName(query);
    }
  }

  /// 食品の詳細情報を取得
  Future<FoodDetails?> getFoodDetails(String foodId) async {
    try {
      // まずローカルデータベースを検索
      final localFood = await _foodRepository.getFoodById(foodId);
      
      if (localFood != null) {
        // ローカルに存在する場合は基本的な詳細情報を返す
        return FoodDetails(
          food: localFood,
          nutrients: {
            'カロリー': '${localFood.calories} kcal',
            'タンパク質': '不明',
            '脂質': '不明',
            '炭水化物': '不明',
          },
          servingSizes: ['1人前'],
          source: 'ローカルデータベース',
        );
      }
      
      // APIリクエストを構築
      final url = Uri.parse('$_apiBaseUrl/foods/$foodId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode != 200) {
        debugPrint('食品詳細取得エラー: ${response.statusCode}');
        return null;
      }
      
      // レスポンスを解析
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      if (!data.containsKey('data')) {
        return null;
      }
      
      final item = data['data'];
      
      // 食品エンティティを作成
      final food = Food(
        id: item['foodId'] ?? foodId,
        name: item['name'] ?? '不明',
        calories: item['calories'] ?? 0,
        category: _parseFoodCategory(item['category']),
        isCustom: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 栄養素情報を解析
      final Map<String, String> nutrients = {};
      
      if (item.containsKey('nutrients')) {
        for (var nutrient in item['nutrients']) {
          nutrients[nutrient['name']] = '${nutrient['value']} ${nutrient['unit']}';
        }
      } else {
        nutrients['カロリー'] = '${food.calories} kcal';
      }
      
      // 提供サイズを解析
      final List<String> servingSizes = [];
      
      if (item.containsKey('servingSizes')) {
        for (var size in item['servingSizes']) {
          servingSizes.add('${size['description']} (${size['weight']}g)');
        }
      } else {
        servingSizes.add('1人前');
      }
      
      return FoodDetails(
        food: food,
        nutrients: nutrients,
        servingSizes: servingSizes,
        source: item['source'] ?? 'オンラインデータベース',
      );
    } catch (e) {
      debugPrint('食品詳細取得エラー: $e');
      return null;
    }
  }

  /// 食品カテゴリを解析
  FoodCategory _parseFoodCategory(String? category) {
    if (category == null) {
      return FoodCategory.other;
    }
    
    switch (category.toLowerCase()) {
      case 'grain':
      case '穀物':
        return FoodCategory.grain;
      case 'protein':
      case 'タンパク質':
        return FoodCategory.protein;
      case 'vegetable':
      case '野菜':
        return FoodCategory.vegetable;
      case 'fruit':
      case '果物':
        return FoodCategory.fruit;
      case 'dairy':
      case '乳製品':
        return FoodCategory.dairy;
      case 'fat':
      case '脂質':
        return FoodCategory.fat;
      case 'sweet':
      case 'お菓子':
        return FoodCategory.sweet;
      case 'beverage':
      case '飲料':
        return FoodCategory.beverage;
      default:
        return FoodCategory.other;
    }
  }
}

/// 食品詳細情報クラス
class FoodDetails {
  final Food food;
  final Map<String, String> nutrients;
  final List<String> servingSizes;
  final String source;

  FoodDetails({
    required this.food,
    required this.nutrients,
    required this.servingSizes,
    required this.source,
  });
}
