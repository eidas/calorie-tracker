// 食事記録エンティティ
// ユーザーの食事記録を表すドメインエンティティクラス

enum MealType {
  breakfast, // 朝食
  lunch,     // 昼食
  dinner,    // 夕食
  snack,     // 間食
}

class FoodEntry {
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

  const FoodEntry({
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

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  FoodEntry copyWith({
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
    return FoodEntry(
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
