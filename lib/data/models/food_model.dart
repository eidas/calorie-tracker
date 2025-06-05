// 食品モデル
// データベースとの変換を担当する食品データモデル

import '../../domain/entities/food.dart';

class FoodModel {
  final String id;
  final String name;
  final int calories; // kcal/100g
  final FoodCategory category;
  final bool isCustom; // ユーザー作成の食品かどうか
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.category,
    required this.isCustom,
    required this.createdAt,
    required this.updatedAt,
  });

  // SQLiteデータベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'category': category.index,
      'is_custom': isCustom ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // SQLiteデータベースのMapからインスタンスを作成
  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      category: FoodCategory.values[map['category']],
      isCustom: map['is_custom'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Firestoreデータベース用のJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'category': category.toString().split('.').last,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // FirestoreデータベースのJSONからインスタンスを作成
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      category: _categoryFromString(json['category']),
      isCustom: json['isCustom'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // カテゴリ文字列からFoodCategory列挙型への変換ヘルパー
  static FoodCategory _categoryFromString(String categoryStr) {
    return FoodCategory.values.firstWhere(
      (e) => e.toString().split('.').last == categoryStr,
      orElse: () => FoodCategory.other,
    );
  }

  // ドメインエンティティに変換
  Food toEntity() {
    return Food(
      id: id,
      name: name,
      calories: calories,
      category: category,
      isCustom: isCustom,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ドメインエンティティからインスタンスを作成
  factory FoodModel.fromEntity(Food food) {
    return FoodModel(
      id: food.id,
      name: food.name,
      calories: food.calories,
      category: food.category,
      isCustom: food.isCustom,
      createdAt: food.createdAt,
      updatedAt: food.updatedAt,
    );
  }

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  FoodModel copyWith({
    String? id,
    String? name,
    int? calories,
    FoodCategory? category,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
