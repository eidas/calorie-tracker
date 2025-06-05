// ユーザーエンティティ
// ユーザー情報を表すドメインエンティティクラス

class User {
  final String id;
  final String name;
  final String email;
  final double height; // cm
  final double targetWeight; // kg
  final int targetCalories; // kcal/日
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.height,
    required this.targetWeight,
    required this.targetCalories,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  User copyWith({
    String? id,
    String? name,
    String? email,
    double? height,
    double? targetWeight,
    int? targetCalories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      height: height ?? this.height,
      targetWeight: targetWeight ?? this.targetWeight,
      targetCalories: targetCalories ?? this.targetCalories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
