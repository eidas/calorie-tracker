// ユーザーモデル
// データベースとの変換を担当するユーザーデータモデル

import '../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final double height; // cm
  final double targetWeight; // kg
  final int targetCalories; // kcal/日
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.height,
    required this.targetWeight,
    required this.targetCalories,
    required this.createdAt,
    required this.updatedAt,
  });

  // SQLiteデータベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'height': height,
      'target_weight': targetWeight,
      'target_calories': targetCalories,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // SQLiteデータベースのMapからインスタンスを作成
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      height: map['height'],
      targetWeight: map['target_weight'],
      targetCalories: map['target_calories'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Firestoreデータベース用のJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'height': height,
      'targetWeight': targetWeight,
      'targetCalories': targetCalories,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // FirestoreデータベースのJSONからインスタンスを作成
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      height: json['height'],
      targetWeight: json['targetWeight'],
      targetCalories: json['targetCalories'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // ドメインエンティティに変換
  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      height: height,
      targetWeight: targetWeight,
      targetCalories: targetCalories,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ドメインエンティティからインスタンスを作成
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      height: user.height,
      targetWeight: user.targetWeight,
      targetCalories: user.targetCalories,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    double? height,
    double? targetWeight,
    int? targetCalories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
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
