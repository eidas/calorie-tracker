// 分析サービス
// カロリーと体重の相関分析と予測機能を提供

import 'package:flutter/foundation.dart';
import 'calorie_service.dart';
import 'weight_service.dart';

class AnalyticsService {
  final CalorieService _calorieService;
  final WeightService _weightService;

  AnalyticsService(this._calorieService, this._weightService);

  /// カロリーと体重の相関データを取得
  Future<CorrelationData> getCalorieWeightCorrelation(DateTime startDate, DateTime endDate) async {
    try {
      // カロリーと体重のトレンドデータを取得
      final calorieData = await _calorieService.getCalorieTrend(startDate, endDate);
      final weightData = await _weightService.getWeightTrend(startDate, endDate);
      
      if (calorieData.isEmpty || weightData.isEmpty) {
        return CorrelationData(
          correlationCoefficient: 0.0,
          calorieData: calorieData,
          weightData: weightData,
          correlationStrength: CorrelationStrength.insufficient,
        );
      }
      
      // 相関係数を計算
      final coefficient = _calculateCorrelation(calorieData, weightData);
      
      // 相関の強さを判定
      final strength = _determineCorrelationStrength(coefficient);
      
      return CorrelationData(
        correlationCoefficient: coefficient,
        calorieData: calorieData,
        weightData: weightData,
        correlationStrength: strength,
      );
    } catch (e) {
      debugPrint('相関分析エラー: $e');
      return CorrelationData(
        correlationCoefficient: 0.0,
        calorieData: [],
        weightData: [],
        correlationStrength: CorrelationStrength.insufficient,
      );
    }
  }

  /// 体重トレンドを予測
  Future<List<DataPoint>> predictWeightTrend(double currentWeight, int targetCalories, int days) async {
    try {
      // 過去30日間のデータを取得して予測の基礎とする
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      final calorieData = await _calorieService.getCalorieTrend(startDate, endDate);
      final weightData = await _weightService.getWeightTrend(startDate, endDate);
      
      if (calorieData.isEmpty || weightData.isEmpty) {
        // 十分なデータがない場合は単純な線形予測を行う
        return _simpleLinearPrediction(currentWeight, targetCalories, days);
      }
      
      // 過去のデータに基づいて予測係数を計算
      final averageCalories = calorieData.fold<double>(0, (sum, point) => sum + point.value) / calorieData.length;
      final weightChange = weightData.last.value - weightData.first.value;
      final daysElapsed = weightData.last.date.difference(weightData.first.date).inDays;
      
      // 1日あたりの体重変化率を計算
      final dailyWeightChangeRate = daysElapsed > 0 ? weightChange / daysElapsed : 0.0;
      
      // カロリー差による体重変化の係数を計算（7700kcalで約1kgの体重変化という一般的な目安を使用）
      final calorieEffect = (targetCalories - averageCalories) / 7700.0;
      
      // 予測データポイントを生成
      final List<DataPoint> predictions = [];
      final today = DateTime(endDate.year, endDate.month, endDate.day);
      
      for (int i = 0; i < days; i++) {
        final date = today.add(Duration(days: i + 1));
        final predictedWeight = currentWeight + (dailyWeightChangeRate + calorieEffect) * (i + 1);
        predictions.add(DataPoint(date: date, value: predictedWeight));
      }
      
      return predictions;
    } catch (e) {
      debugPrint('体重予測エラー: $e');
      return [];
    }
  }

  /// 単純な線形予測（十分なデータがない場合）
  List<DataPoint> _simpleLinearPrediction(double currentWeight, int targetCalories, int days) {
    // 基礎代謝を2000kcalと仮定
    const basalMetabolicRate = 2000;
    // カロリー差による1日あたりの体重変化（7700kcalで約1kg）
    final dailyWeightChange = (targetCalories - basalMetabolicRate) / 7700.0;
    
    final List<DataPoint> predictions = [];
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i + 1));
      final predictedWeight = currentWeight + dailyWeightChange * (i + 1);
      predictions.add(DataPoint(date: date, value: predictedWeight));
    }
    
    return predictions;
  }

  /// 相関係数を計算
  double _calculateCorrelation(List<DataPoint> calorieData, List<DataPoint> weightData) {
    // 日付をキーにしたマップを作成
    final Map<String, double> calorieByDate = {};
    final Map<String, double> weightByDate = {};
    
    for (var point in calorieData) {
      final dateKey = '${point.date.year}-${point.date.month}-${point.date.day}';
      calorieByDate[dateKey] = point.value;
    }
    
    for (var point in weightData) {
      final dateKey = '${point.date.year}-${point.date.month}-${point.date.day}';
      weightByDate[dateKey] = point.value;
    }
    
    // 共通の日付のデータポイントのみを使用
    final List<double> calorieValues = [];
    final List<double> weightValues = [];
    
    for (var dateKey in calorieByDate.keys) {
      if (weightByDate.containsKey(dateKey)) {
        calorieValues.add(calorieByDate[dateKey]!);
        weightValues.add(weightByDate[dateKey]!);
      }
    }
    
    if (calorieValues.length < 3) {
      // 相関を計算するには少なくとも3つのデータポイントが必要
      return 0.0;
    }
    
    // ピアソン相関係数を計算
    final int n = calorieValues.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += calorieValues[i];
      sumY += weightValues[i];
      sumXY += calorieValues[i] * weightValues[i];
      sumX2 += calorieValues[i] * calorieValues[i];
      sumY2 += weightValues[i] * weightValues[i];
    }
    
    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    
    return denominator != 0 ? numerator / denominator : 0;
  }

  /// 相関の強さを判定
  CorrelationStrength _determineCorrelationStrength(double coefficient) {
    final absCoefficient = coefficient.abs();
    
    if (absCoefficient < 0.3) {
      return CorrelationStrength.weak;
    } else if (absCoefficient < 0.7) {
      return CorrelationStrength.moderate;
    } else {
      return CorrelationStrength.strong;
    }
  }

  /// 平方根を計算
  double sqrt(double value) {
    return value <= 0 ? 0 : value.sqrt();
  }
}

/// 相関データクラス
class CorrelationData {
  final double correlationCoefficient;
  final List<DataPoint> calorieData;
  final List<DataPoint> weightData;
  final CorrelationStrength correlationStrength;

  CorrelationData({
    required this.correlationCoefficient,
    required this.calorieData,
    required this.weightData,
    required this.correlationStrength,
  });
}

/// 相関の強さを表す列挙型
enum CorrelationStrength {
  insufficient, // データ不足
  weak,         // 弱い相関
  moderate,     // 中程度の相関
  strong,       // 強い相関
}
