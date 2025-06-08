// カロリーサービス
// カロリー計算と統計機能を提供

import 'package:flutter/foundation.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/repositories/food_entry_repository.dart';

class CalorieService {
  final FoodEntryRepository _foodEntryRepository;

  CalorieService(this._foodEntryRepository);

  /// 指定日のカロリー合計を計算
  Future<int> calculateDailyCalories(DateTime date) async {
    try {
      // 日付の時間部分をリセットして日付のみで比較できるようにする
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // リポジトリから指定日の合計カロリーを取得
      return await _foodEntryRepository.getTotalCaloriesByDate(normalizedDate);
    } catch (e) {
      debugPrint('日別カロリー計算エラー: $e');
      return 0; // エラー時は0を返す
    }
  }

  /// 期間の平均カロリーを計算
  Future<double> calculateAverageCalories(DateTime startDate, DateTime endDate) async {
    try {
      // 日付の正規化
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      // 日数の計算（終了日も含める）
      final daysDifference = normalizedEndDate.difference(normalizedStartDate).inDays + 1;
      
      if (daysDifference <= 0) {
        return 0.0;
      }
      
      // 期間内の食事記録を取得
      final entries = await _foodEntryRepository.getFoodEntriesByDateRange(
        normalizedStartDate, 
        normalizedEndDate
      );
      
      // 合計カロリーを計算
      final totalCalories = entries.fold<int>(
        0, 
        (sum, entry) => sum + entry.calories
      );
      
      // 平均を計算して返す
      return totalCalories / daysDifference;
    } catch (e) {
      debugPrint('平均カロリー計算エラー: $e');
      return 0.0; // エラー時は0.0を返す
    }
  }

  /// カロリー推移データを取得
  Future<List<DataPoint>> getCalorieTrend(DateTime startDate, DateTime endDate) async {
    try {
      // 日付の正規化
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      // 日数の計算
      final daysDifference = normalizedEndDate.difference(normalizedStartDate).inDays + 1;
      
      if (daysDifference <= 0) {
        return [];
      }
      
      // 結果を格納するリスト
      final List<DataPoint> result = [];
      
      // 各日のカロリー合計を計算
      for (int i = 0; i < daysDifference; i++) {
        final currentDate = DateTime(
          normalizedStartDate.year,
          normalizedStartDate.month,
          normalizedStartDate.day + i
        );
        
        // 当日のカロリー合計を取得
        final calories = await calculateDailyCalories(currentDate);
        
        // データポイントを追加
        result.add(DataPoint(date: currentDate, value: calories.toDouble()));
      }
      
      return result;
    } catch (e) {
      debugPrint('カロリー推移取得エラー: $e');
      return []; // エラー時は空のリストを返す
    }
  }
}

/// データポイントクラス
/// グラフ表示などに使用するデータポイントを表す
class DataPoint {
  final DateTime date;
  final double value;

  DataPoint({required this.date, required this.value});
}
