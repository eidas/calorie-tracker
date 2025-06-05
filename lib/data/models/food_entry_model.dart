// 食事記録モデル
// データベースとの変換を担当する食事記録データモデル

import '../../domain/entities/food_entry.dart';

class FoodEntryModel {
  final String id;
  final String userId;
  final String foodId;
  final DateTime date;
  final double quantity; // 数量（g）
  final MealType mealType;
  final int calories; // 計算されたカロリー（数量に基づく）
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodEntryModel({
    required this.id,
    required this.userId,
    required this.foodId,
    required this.date,
    required this.quantity,
    required this.mealType,
    required this.calories,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  // SQLiteデータベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'food_id': foodId,
      'date': date.millisecondsSinceEpoch,
      'quantity': quantity,
      'meal_type': mealType.index,
      'calories': calories,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // SQLiteデータベースのMapからインスタンスを作成
  factory FoodEntryModel.fromMap(Map<String, dynamic> map) {
    return FoodEntryModel(
      id: map['id'],
      userId: map['user_id'],
      foodId: map['food_id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      quantity: map['quantity'],
      mealType: MealType.values[map['meal_type']],
      calories: map['calories'],
      note: map['note'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Firestoreデータベース用のJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'foodId': foodId,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'mealType': mealType.toString().split('.').last,
      'calories': calories,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // FirestoreデータベースのJSONからインスタンスを作成
  factory FoodEntryModel.fromJson(Map<String, dynamic> json) {
    return FoodEntryModel(
      id: json['id'],
      userId: json['userId'],
      foodId: json['foodId'],
      date: DateTime.parse(json['date']),
      quantity: json['quantity'],
      mealType: _mealTypeFromString(json['mealType']),
      calories: json['calories'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // 食事タイプ文字列からMealType列挙型への変換ヘルパー
  static MealType _mealTypeFromString(String mealTypeStr) {
    return MealType.values.firstWhere(
      (e) => e.toString().split('.').last == mealTypeStr,
      orElse: () => MealType.snack,
    );
  }

  // ドメインエンティティに変換
  FoodEntry toEntity() {
    return FoodEntry(
      id: id,
      userId: userId,
      foodId: foodId,
      date: date,
      quantity: quantity,
      mealType: mealType,
      calories: calories,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ドメインエンティティからインスタンスを作成
  factory FoodEntryModel.fromEntity(FoodEntry entry) {
    return FoodEntryModel(
      id: entry.id,
      userId: entry.userId,
      foodId: entry.foodId,
      date: entry.date,
      quantity: entry.quantity,
      mealType: entry.mealType,
      calories: entry.calories,
      note: entry.note,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  FoodEntryModel copyWith({
    String? id,
    String? userId,
    String? foodId,
    DateTime? date,
    double? quantity,
    MealType? mealType,
    int? calories,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
