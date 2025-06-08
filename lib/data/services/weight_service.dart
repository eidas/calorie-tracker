// 体重サービス
// 体重記録の分析と統計機能を提供

import 'package:flutter/foundation.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/weight_repository.dart';
import 'calorie_service.dart';

class WeightService {
  final WeightRepository _weightRepository;

  WeightService(this._weightRepository);

  /// 体重トレンドデータを取得
  Future<List<DataPoint>> getWeightTrend(DateTime startDate, DateTime endDate) async {
    try {
      final records = await _weightRepository.getWeightRecordsByDateRange(startDate, endDate);
      
      // 日付ごとの体重記録を整理（同じ日に複数記録がある場合は最新を使用）
      final Map<DateTime, WeightRecord> dailyWeights = {};
      
      for (var record in records) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        
        // 同じ日の記録がない、または既存の記録より新しい場合に更新
        if (!dailyWeights.containsKey(date) || 
            record.createdAt.isAfter(dailyWeights[date]!.createdAt)) {
          dailyWeights[date] = record;
        }
      }
      
      // 日付でソートしたデータポイントのリストを作成
      final List<DataPoint> dataPoints = dailyWeights.entries
          .map((entry) => DataPoint(date: entry.key, value: entry.value.weight))
          .toList();
      
      // 日付順にソート
      dataPoints.sort((a, b) => a.date.compareTo(b.date));
      
      return dataPoints;
    } catch (e) {
      debugPrint('体重トレンド取得エラー: $e');
      return [];
    }
  }

  /// 期間内の体重変化を計算
  Future<double> calculateWeightChange(DateTime startDate, DateTime endDate) async {
    try {
      final records = await _weightRepository.getWeightRecordsByDateRange(startDate, endDate);
      
      if (records.isEmpty) {
        return 0.0;
      }
      
      // 開始日に最も近い記録を検索
      WeightRecord? startRecord;
      WeightRecord? endRecord;
      
      for (var record in records) {
        // 開始日に最も近い記録を探す
        if (startRecord == null || 
            (record.date.difference(startDate).abs() < startRecord.date.difference(startDate).abs())) {
          startRecord = record;
        }
        
        // 終了日に最も近い記録を探す
        if (endRecord == null || 
            (record.date.difference(endDate).abs() < endRecord.date.difference(endDate).abs())) {
          endRecord = record;
        }
      }
      
      // 開始と終了の記録が同じ場合は変化なし
      if (startRecord == endRecord) {
        return 0.0;
      }
      
      // 体重変化を計算
      return endRecord!.weight - startRecord!.weight;
    } catch (e) {
      debugPrint('体重変化計算エラー: $e');
      return 0.0;
    }
  }
}
