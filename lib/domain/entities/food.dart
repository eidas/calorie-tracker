// 食品エンティティ
// 食品データを表すドメインエンティティクラス

enum FoodCategory {
  grain,     // 穀物
  protein,   // タンパク質
  vegetable, // 野菜
  fruit,     // 果物
  dairy,     // 乳製品
  fat,       // 脂質
  sweet,     // 甘味
  beverage,  // 飲料
  other,     // その他
}

class Food {
  final String id;
  final String name;
  final int calories; // kcal/100g
  final FoodCategory category;
  final bool isCustom; // ユーザー作成の食品かどうか
  final DateTime createdAt;
  final DateTime updatedAt;

  const Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.category,
    required this.isCustom,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  Food copyWith({
    String? id,
    String? name,
    int? calories,
    FoodCategory? category,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Food(
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
