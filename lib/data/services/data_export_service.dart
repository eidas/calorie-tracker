// データエクスポートサービス
// データのエクスポートとインポート機能を提供

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/food_entry_repository.dart';
import '../../domain/repositories/weight_repository.dart';

class DataExportService {
  final FoodRepository _foodRepository;
  final FoodEntryRepository _entryRepository;
  final WeightRepository _weightRepository;

  DataExportService(
    this._foodRepository,
    this._entryRepository,
    this._weightRepository,
  );

  /// CSVファイルにデータをエクスポート
  Future<File> exportToCSV(DateTime startDate, DateTime endDate) async {
    try {
      // 期間内のデータを取得
      final entries = await _entryRepository.getFoodEntriesByDateRange(startDate, endDate);
      final weights = await _weightRepository.getWeightRecordsByDateRange(startDate, endDate);
      final foods = await _foodRepository.getAllFoods();
      
      // 食品IDをキーにしたマップを作成
      final Map<String, Food> foodMap = {
        for (var food in foods) food.id: food
      };
      
      // CSVヘッダー
      final StringBuffer csvData = StringBuffer();
      
      // 食事記録のCSV
      csvData.writeln('# 食事記録');
      csvData.writeln('日付,食事タイプ,食品名,数量,カロリー,メモ');
      
      for (var entry in entries) {
        final food = foodMap[entry.foodId];
        final foodName = food?.name ?? '不明';
        final date = _formatDate(entry.date);
        final mealType = _getMealTypeName(entry.mealType);
        
        csvData.writeln(
          '$date,$mealType,$foodName,${entry.quantity},${entry.calories},${entry.note ?? ""}'
        );
      }
      
      csvData.writeln();
      
      // 体重記録のCSV
      csvData.writeln('# 体重記録');
      csvData.writeln('日付,体重,メモ');
      
      for (var weight in weights) {
        final date = _formatDate(weight.date);
        csvData.writeln(
          '$date,${weight.weight},${weight.note ?? ""}'
        );
      }
      
      // ファイルに保存
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'zubora_calorie_export_${_formatDate(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvData.toString());
      return file;
    } catch (e) {
      debugPrint('CSVエクスポートエラー: $e');
      rethrow;
    }
  }

  /// JSONファイルにデータをエクスポート
  Future<File> exportToJSON(DateTime startDate, DateTime endDate) async {
    try {
      // 期間内のデータを取得
      final entries = await _entryRepository.getFoodEntriesByDateRange(startDate, endDate);
      final weights = await _weightRepository.getWeightRecordsByDateRange(startDate, endDate);
      final customFoods = await _foodRepository.getCustomFoods();
      
      // JSONデータを構築
      final Map<String, dynamic> jsonData = {
        'exportDate': DateTime.now().toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'foodEntries': entries.map((entry) => {
          'id': entry.id,
          'userId': entry.userId,
          'foodId': entry.foodId,
          'date': entry.date.toIso8601String(),
          'quantity': entry.quantity,
          'mealType': entry.mealType.index,
          'calories': entry.calories,
          'note': entry.note,
          'createdAt': entry.createdAt.toIso8601String(),
          'updatedAt': entry.updatedAt.toIso8601String(),
        }).toList(),
        'weightRecords': weights.map((weight) => {
          'id': weight.id,
          'userId': weight.userId,
          'date': weight.date.toIso8601String(),
          'weight': weight.weight,
          'note': weight.note,
          'createdAt': weight.createdAt.toIso8601String(),
          'updatedAt': weight.updatedAt.toIso8601String(),
        }).toList(),
        'customFoods': customFoods.map((food) => {
          'id': food.id,
          'name': food.name,
          'calories': food.calories,
          'category': food.category.index,
          'isCustom': food.isCustom,
          'createdAt': food.createdAt.toIso8601String(),
          'updatedAt': food.updatedAt.toIso8601String(),
        }).toList(),
      };
      
      // ファイルに保存
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'zubora_calorie_export_${_formatDate(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonEncode(jsonData));
      return file;
    } catch (e) {
      debugPrint('JSONエクスポートエラー: $e');
      rethrow;
    }
  }

  /// CSVファイルからデータをインポート
  Future<ImportResult> importFromCSV(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      int foodEntriesImported = 0;
      int weightRecordsImported = 0;
      
      // 現在のセクション（食事記録または体重記録）
      String currentSection = '';
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        // セクションヘッダーの検出
        if (line.startsWith('# ')) {
          currentSection = line.substring(2);
          continue;
        }
        
        // ヘッダー行をスキップ
        if (line.contains('日付,') || line.contains('Date,')) {
          continue;
        }
        
        // CSVの解析
        final values = _parseCSVLine(line);
        
        if (currentSection.contains('食事記録')) {
          if (values.length >= 5) {
            try {
              final date = _parseDate(values[0]);
              final mealType = _parseMealType(values[1]);
              final foodName = values[2];
              final quantity = double.tryParse(values[3]) ?? 1.0;
              final calories = int.tryParse(values[4]) ?? 0;
              final note = values.length > 5 ? values[5] : null;
              
              // 食品を検索または作成
              final foods = await _foodRepository.searchFoodsByName(foodName);
              String foodId;
              
              if (foods.isNotEmpty) {
                foodId = foods.first.id;
              } else {
                // 食品が見つからない場合は新規作成
                final newFood = Food(
                  id: 'import_${DateTime.now().millisecondsSinceEpoch}_${foodEntriesImported}',
                  name: foodName,
                  calories: calories,
                  category: FoodCategory.other,
                  isCustom: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await _foodRepository.saveFood(newFood);
                foodId = newFood.id;
              }
              
              // 食事記録を作成
              final entry = FoodEntry(
                id: 'import_${DateTime.now().millisecondsSinceEpoch}_${foodEntriesImported}',
                userId: 'current_user', // 現在のユーザーIDを使用
                foodId: foodId,
                date: date,
                quantity: quantity,
                mealType: mealType,
                calories: calories,
                note: note,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await _entryRepository.saveFoodEntry(entry);
              foodEntriesImported++;
            } catch (e) {
              debugPrint('食事記録インポートエラー: $e');
            }
          }
        } else if (currentSection.contains('体重記録')) {
          if (values.length >= 2) {
            try {
              final date = _parseDate(values[0]);
              final weight = double.tryParse(values[1]) ?? 0.0;
              final note = values.length > 2 ? values[2] : null;
              
              // 体重記録を作成
              final record = WeightRecord(
                id: 'import_${DateTime.now().millisecondsSinceEpoch}_${weightRecordsImported}',
                userId: 'current_user', // 現在のユーザーIDを使用
                date: date,
                weight: weight,
                note: note,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await _weightRepository.saveWeightRecord(record);
              weightRecordsImported++;
            } catch (e) {
              debugPrint('体重記録インポートエラー: $e');
            }
          }
        }
      }
      
      return ImportResult(
        success: true,
        foodEntriesImported: foodEntriesImported,
        weightRecordsImported: weightRecordsImported,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('CSVインポートエラー: $e');
      return ImportResult(
        success: false,
        foodEntriesImported: 0,
        weightRecordsImported: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// JSONファイルからデータをインポート
  Future<ImportResult> importFromJSON(File file) async {
    try {
      final content = await file.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(content);
      
      int foodEntriesImported = 0;
      int weightRecordsImported = 0;
      
      // カスタム食品のインポート
      if (jsonData.containsKey('customFoods')) {
        final List<dynamic> customFoodsData = jsonData['customFoods'];
        
        for (var foodData in customFoodsData) {
          try {
            final food = Food(
              id: 'import_${DateTime.now().millisecondsSinceEpoch}_${foodEntriesImported}',
              name: foodData['name'],
              calories: foodData['calories'],
              category: FoodCategory.values[foodData['category'] ?? 0],
              isCustom: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _foodRepository.saveFood(food);
          } catch (e) {
            debugPrint('食品インポートエラー: $e');
          }
        }
      }
      
      // 食事記録のインポート
      if (jsonData.containsKey('foodEntries')) {
        final List<dynamic> entriesData = jsonData['foodEntries'];
        
        for (var entryData in entriesData) {
          try {
            final entry = FoodEntry(
              id: 'import_${DateTime.now().millisecondsSinceEpoch}_${foodEntriesImported}',
              userId: 'current_user', // 現在のユーザーIDを使用
              foodId: entryData['foodId'],
              date: DateTime.parse(entryData['date']),
              quantity: entryData['quantity']?.toDouble() ?? 1.0,
              mealType: MealType.values[entryData['mealType'] ?? 0],
              calories: entryData['calories'] ?? 0,
              note: entryData['note'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _entryRepository.saveFoodEntry(entry);
            foodEntriesImported++;
          } catch (e) {
            debugPrint('食事記録インポートエラー: $e');
          }
        }
      }
      
      // 体重記録のインポート
      if (jsonData.containsKey('weightRecords')) {
        final List<dynamic> weightsData = jsonData['weightRecords'];
        
        for (var weightData in weightsData) {
          try {
            final record = WeightRecord(
              id: 'import_${DateTime.now().millisecondsSinceEpoch}_${weightRecordsImported}',
              userId: 'current_user', // 現在のユーザーIDを使用
              date: DateTime.parse(weightData['date']),
              weight: weightData['weight']?.toDouble() ?? 0.0,
              note: weightData['note'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _weightRepository.saveWeightRecord(record);
            weightRecordsImported++;
          } catch (e) {
            debugPrint('体重記録インポートエラー: $e');
          }
        }
      }
      
      return ImportResult(
        success: true,
        foodEntriesImported: foodEntriesImported,
        weightRecordsImported: weightRecordsImported,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('JSONインポートエラー: $e');
      return ImportResult(
        success: false,
        foodEntriesImported: 0,
        weightRecordsImported: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 文字列から日付を解析
  DateTime _parseDate(String dateStr) {
    try {
      // YYYY-MM-DD形式を解析
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      
      // DD/MM/YYYY形式を解析
      final slashParts = dateStr.split('/');
      if (slashParts.length == 3) {
        return DateTime(
          int.parse(slashParts[2]),
          int.parse(slashParts[1]),
          int.parse(slashParts[0]),
        );
      }
      
      // 解析できない場合は現在の日付を返す
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// 食事タイプ名から列挙型を解析
  MealType _parseMealType(String mealTypeName) {
    switch (mealTypeName.toLowerCase()) {
      case '朝食':
      case 'breakfast':
        return MealType.breakfast;
      case '昼食':
      case 'lunch':
        return MealType.lunch;
      case '夕食':
      case 'dinner':
        return MealType.dinner;
      case '間食':
      case 'snack':
        return MealType.snack;
      default:
        return MealType.other;
    }
  }

  /// 食事タイプの名前を取得
  String _getMealTypeName(MealType mealType) {
    switch (mealType) {
      case MealType.breakfast:
        return '朝食';
      case MealType.lunch:
        return '昼食';
      case MealType.dinner:
        return '夕食';
      case MealType.snack:
        return '間食';
      case MealType.other:
        return 'その他';
    }
  }

  /// CSVの行を解析
  List<String> _parseCSVLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer currentValue = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(currentValue.toString());
        currentValue = StringBuffer();
      } else {
        currentValue.write(char);
      }
    }
    
    result.add(currentValue.toString());
    return result;
  }
}

/// インポート結果クラス
class ImportResult {
  final bool success;
  final int foodEntriesImported;
  final int weightRecordsImported;
  final String? errorMessage;

  ImportResult({
    required this.success,
    required this.foodEntriesImported,
    required this.weightRecordsImported,
    this.errorMessage,
  });
}
