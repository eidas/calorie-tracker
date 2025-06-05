// 体重記録エンティティ
// ユーザーの体重記録を表すドメインエンティティクラス

class WeightRecord {
  final String id;
  final String userId;
  final DateTime date;
  final double weight; // kg
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeightRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  // コピーメソッド - 一部のプロパティを変更した新しいインスタンスを作成
  WeightRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightRecord(
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
