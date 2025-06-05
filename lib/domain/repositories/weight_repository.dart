// 体重記録リポジトリインターフェース
// 体重記録の日付別取得・保存・削除を担当するリポジトリの抽象定義

import '../entities/weight_record.dart';

abstract class WeightRepository {
  /// 特定の日付の体重記録を取得
  Future<WeightRecord?> getWeightRecordByDate(DateTime date);

  /// 日付範囲の体重記録を取得
  Future<List<WeightRecord>> getWeightRecordsByDateRange(DateTime startDate, DateTime endDate);

  /// 最新の体重記録を取得
  Future<WeightRecord?> getLatestWeightRecord();

  /// 体重記録を保存
  Future<void> saveWeightRecord(WeightRecord record);

  /// 体重記録を更新
  Future<void> updateWeightRecord(WeightRecord record);

  /// 体重記録を削除
  Future<void> deleteWeightRecord(String recordId);
}
