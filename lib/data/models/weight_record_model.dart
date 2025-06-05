// 体重記録モデル
// データベースとの変換を担当する体重記録データモデル

import '../../domain/entities/weight_record.dart';

class WeightRecordModel {
  final String id;
  final String userId;
  final DateTime date;
  final double weight; // kg
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeightRecordModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  // SQLiteデータベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.millisecondsSinceEpoch,
      'weight': weight,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // SQLiteデータベースのMapからインスタンスを作成
  factory WeightRecordModel.fromMap(Map<String, dynamic> map) {
    return WeightRecordModel(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      weight: map['weight'],
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
      'date': date.toIso8601String(),
      'weight': weight,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // FirestoreデータベースのJSONからインスタンスを作成
  factory WeightRecordModel.fromJson(Map<String, dynamic> json) {
    return WeightRecordModel(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      weight: json['weight'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // ドメインエンティティに変換
  WeightRecord toEntity() {
    return WeightRecord(
      id: id,
      userId: userId,
      date: date,
      weight: weight,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ドメインエンティティからインスタンスを作成
  factory WeightRecordModel.fromEntity(WeightRecord record) {
    return WeightRecordModel(
      id: record.id,
      userId: record.userId,
      date: record.date,
      weight: record.weight,
      note: record.note,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  WeightRecordModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
