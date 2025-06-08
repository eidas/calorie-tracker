// カロリーサービス
// カロリー計算と統計機能を提供

import 'package:flutter/foundation.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/repositories/food_entry_repository.dart';

class CalorieService {
  final FoodEntryRepository _entryRepository;

  CalorieService(this._entryRepository);

  /// 特定の日のカロリー合計を計算
  Future<int> calculateDailyCalories(DateTime date) async {
    try {
      return await _entryRepository.getTotalCaloriesByDate(date);
    } catch (e) {
      debugPrint('カロリー計算エラー: $e');
      return 0;
    }
  }

  /// 期間の平均カロリーを計算
  Future<double> calculateAverageCalories(DateTime startDate, DateTime endDate) async {
    try {
      final entries = await _entryRepository.getFoodEntriesByDateRange(startDate, endDate);
      
      if (entries.isEmpty) {
        return 0.0;
      }
      
      // 日付ごとのカロリー合計を計算
      final Map<DateTime, int> dailyCalories = {};
      
      for (var entry in entries) {
        final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
        dailyCalories[date] = (dailyCalories[date] ?? 0) + entry.calories;
      }
      
      // 平均を計算
      final totalCalories = dailyCalories.values.fold<int>(0, (sum, calories) => sum + calories);
      final daysCount = dailyCalories.length;
      
      return daysCount > 0 ? totalCalories / daysCount : 0.0;
    } catch (e) {
      debugPrint('平均カロリー計算エラー: $e');
      return 0.0;
    }
  }

  /// カロリー摂取のトレンドデータを取得
  Future<List<DataPoint>> getCalorieTrend(DateTime startDate, DateTime endDate) async {
    try {
      final entries = await _entryRepository.getFoodEntriesByDateRange(startDate, endDate);
      
      // 日付ごとのカロリー合計を計算
      final Map<DateTime, int> dailyCalories = {};
      
      for (var entry in entries) {
        final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
        dailyCalories[date] = (dailyCalories[date] ?? 0) + entry.calories;
      }
      
      // 日付でソートしたデータポイントのリストを作成
      final List<DataPoint> dataPoints = dailyCalories.entries
          .map((entry) => DataPoint(date: entry.key, value: entry.value.toDouble()))
          .toList();
      
      // 日付順にソート
      dataPoints.sort((a, b) => a.date.compareTo(b.date));
      
      return dataPoints;
    } catch (e) {
      debugPrint('カロリートレンド取得エラー: $e');
      return [];
    }
  }
}

/// データポイントクラス（グラフ表示用）
class DataPoint {
  final DateTime date;
  final double value;

  DataPoint({required this.date, required this.value});
}
