// データエクスポートサービス
// データのエクスポートとインポート機能を提供

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/food_entry_repository.dart';
import '../../domain/repositories/weight_repository.dart';

class DataExportService {
  final FoodRepository _foodRepository;
  final FoodEntryRepository _foodEntryRepository;
  final WeightRepository _weightRepository;

  DataExportService(
    this._foodRepository,
    this._foodEntryRepository,
    this._weightRepository,
  );

  /// CSVファイルにデータをエクスポート
  Future<File> exportToCSV(DateTime startDate, DateTime endDate) async {
    try {
      // 日付の正規化
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      // データの取得
      final foodEntries = await _foodEntryRepository.getFoodEntriesByDateRange(
        normalizedStartDate, 
        normalizedEndDate
      );
      final weightRecords = await _weightRepository.getWeightRecordsByDateRange(
        normalizedStartDate, 
        normalizedEndDate
      );
      
      // 食品データの取得（カスタム食品のみ）
      final customFoods = await _foodRepository.getCustomFoods();
      
      // CSVデータの構築
      final StringBuffer csvData = StringBuffer();
      
      // ヘッダー
      csvData.writeln('# ずぼらカロリー エクスポートデータ');
      csvData.writeln('# エクスポート日時: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      csvData.writeln('# 期間: ${DateFormat('yyyy-MM-dd').format(normalizedStartDate)} から ${DateFormat('yyyy-MM-dd').format(normalizedEndDate)}');
      csvData.writeln();
      
      // カスタム食品データ
      csvData.writeln('## カスタム食品');
      csvData.writeln('id,名前,カロリー,カテゴリ,作成日');
      
      for (var food in customFoods) {
        csvData.writeln([
          food.id,
          _escapeCsvField(food.name),
          food.calories.toString(),
          food.category.toString().split('.').last,
          DateFormat('yyyy-MM-dd').format(food.createdAt),
        ].join(','));
      }
      
      csvData.writeln();
      
      // 食事記録データ
      csvData.writeln('## 食事記録');
      csvData.writeln('id,日付,食品ID,数量,食事タイプ,カロリー,メモ');
      
      for (var entry in foodEntries) {
        csvData.writeln([
          entry.id,
          DateFormat('yyyy-MM-dd').format(entry.date),
          entry.foodId,
          entry.quantity.toString(),
          entry.mealType.toString().split('.').last,
          entry.calories.toString(),
          _escapeCsvField(entry.note ?? ''),
        ].join(','));
      }
      
      csvData.writeln();
      
      // 体重記録データ
      csvData.writeln('## 体重記録');
      csvData.writeln('id,日付,体重,メモ');
      
      for (var record in weightRecords) {
        csvData.writeln([
          record.id,
          DateFormat('yyyy-MM-dd').format(record.date),
          record.weight.toString(),
          _escapeCsvField(record.note ?? ''),
        ].join(','));
      }
      
      // ファイルの保存
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'zubora_calorie_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
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
      // 日付の正規化
      final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
      
      // データの取得
      final foodEntries = await _foodEntryRepository.getFoodEntriesByDateRange(
        normalizedStartDate, 
        normalizedEndDate
      );
      final weightRecords = await _weightRepository.getWeightRecordsByDateRange(
        normalizedStartDate, 
        normalizedEndDate
      );
      
      // 食品データの取得（カスタム食品のみ）
      final customFoods = await _foodRepository.getCustomFoods();
      
      // JSONデータの構築
      final Map<String, dynamic> jsonData = {
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'startDate': normalizedStartDate.toIso8601String(),
          'endDate': normalizedEndDate.toIso8601String(),
          'appVersion': '1.0.0',
        },
        'customFoods': customFoods.map((food) => {
          'id': food.id,
          'name': food.name,
          'calories': food.calories,
          'category': food.category.toString().split('.').last,
          'createdAt': food.createdAt.toIso8601String(),
          'updatedAt': food.updatedAt.toIso8601String(),
        }).toList(),
        'foodEntries': foodEntries.map((entry) => {
          'id': entry.id,
          'userId': entry.userId,
          'foodId': entry.foodId,
          'date': entry.date.toIso8601String(),
          'quantity': entry.quantity,
          'mealType': entry.mealType.toString().split('.').last,
          'calories': entry.calories,
          'note': entry.note,
          'createdAt': entry.createdAt.toIso8601String(),
          'updatedAt': entry.updatedAt.toIso8601String(),
        }).toList(),
        'weightRecords': weightRecords.map((record) => {
          'id': record.id,
          'userId': record.userId,
          'date': record.date.toIso8601String(),
          'weight': record.weight,
          'note': record.note,
          'createdAt': record.createdAt.toIso8601String(),
          'updatedAt': record.updatedAt.toIso8601String(),
        }).toList(),
      };
      
      // ファイルの保存
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'zubora_calorie_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.json';
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
      final String content = await file.readAsString();
      final List<String> lines = content.split('\n');
      
      int customFoodsCount = 0;
      int foodEntriesCount = 0;
      int weightRecordsCount = 0;
      final List<String> errors = [];
      
      // セクション識別用の変数
      String currentSection = '';
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        // 空行またはコメント行をスキップ
        if (line.isEmpty || line.startsWith('#')) {
          continue;
        }
        
        // セクションヘッダーの検出
        if (line.startsWith('##')) {
          currentSection = line.substring(2).trim();
          continue;
        }
        
        // ヘッダー行をスキップ
        if (line.contains('id,') || line.contains('ID,')) {
          continue;
        }
        
        // セクションに応じたデータ処理
        try {
          if (currentSection == 'カスタム食品') {
            await _processCustomFoodCsvLine(line);
            customFoodsCount++;
          } else if (currentSection == '食事記録') {
            await _processFoodEntryCsvLine(line);
            foodEntriesCount++;
          } else if (currentSection == '体重記録') {
            await _processWeightRecordCsvLine(line);
            weightRecordsCount++;
          }
        } catch (e) {
          errors.add('行 ${i + 1}: $e');
        }
      }
      
      return ImportResult(
        success: errors.isEmpty,
        customFoodsCount: customFoodsCount,
        foodEntriesCount: foodEntriesCount,
        weightRecordsCount: weightRecordsCount,
        errors: errors,
      );
    } catch (e) {
      debugPrint('CSVインポートエラー: $e');
      return ImportResult(
        success: false,
        customFoodsCount: 0,
        foodEntriesCount: 0,
        weightRecordsCount: 0,
        errors: ['ファイル読み込みエラー: $e'],
      );
    }
  }

  /// JSONファイルからデータをインポート
  Future<ImportResult> importFromJSON(File file) async {
    try {
      final String content = await file.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(content);
      
      int customFoodsCount = 0;
      int foodEntriesCount = 0;
      int weightRecordsCount = 0;
      final List<String> errors = [];
      
      // カスタム食品のインポート
      if (jsonData.containsKey('customFoods')) {
        final List<dynamic> customFoods = jsonData['customFoods'];
        
        for (var foodData in customFoods) {
          try {
            final food = Food(
              id: foodData['id'],
              name: foodData['name'],
              calories: foodData['calories'],
              category: _parseFoodCategory(foodData['category']),
              isCustom: true,
              createdAt: DateTime.parse(foodData['createdAt']),
              updatedAt: DateTime.parse(foodData['updatedAt']),
            );
            
            await _foodRepository.saveFood(food);
            customFoodsCount++;
          } catch (e) {
            errors.add('カスタム食品インポートエラー: $e');
          }
        }
      }
      
      // 食事記録のインポート
      if (jsonData.containsKey('foodEntries')) {
        final List<dynamic> foodEntries = jsonData['foodEntries'];
        
        for (var entryData in foodEntries) {
          try {
            final entry = FoodEntry(
              id: entryData['id'],
              userId: entryData['userId'],
              foodId: entryData['foodId'],
              date: DateTime.parse(entryData['date']),
              quantity: entryData['quantity'].toDouble(),
              mealType: _parseMealType(entryData['mealType']),
              calories: entryData['calories'],
              note: entryData['note'],
              createdAt: DateTime.parse(entryData['createdAt']),
              updatedAt: DateTime.parse(entryData['updatedAt']),
            );
            
            await _foodEntryRepository.saveFoodEntry(entry);
            foodEntriesCount++;
          } catch (e) {
            errors.add('食事記録インポートエラー: $e');
          }
        }
      }
      
      // 体重記録のインポート
      if (jsonData.containsKey('weightRecords')) {
        final List<dynamic> weightRecords = jsonData['weightRecords'];
        
        for (var recordData in weightRecords) {
          try {
            final record = WeightRecord(
              id: recordData['id'],
              userId: recordData['userId'],
              date: DateTime.parse(recordData['date']),
              weight: recordData['weight'].toDouble(),
              note: recordData['note'],
              createdAt: DateTime.parse(recordData['createdAt']),
              updatedAt: DateTime.parse(recordData['updatedAt']),
            );
            
            await _weightRepository.saveWeightRecord(record);
            weightRecordsCount++;
          } catch (e) {
            errors.add('体重記録インポートエラー: $e');
          }
        }
      }
      
      return ImportResult(
        success: errors.isEmpty,
        customFoodsCount: customFoodsCount,
        foodEntriesCount: foodEntriesCount,
        weightRecordsCount: weightRecordsCount,
        errors: errors,
      );
    } catch (e) {
      debugPrint('JSONインポートエラー: $e');
      return ImportResult(
        success: false,
        customFoodsCount: 0,
        foodEntriesCount: 0,
        weightRecordsCount: 0,
        errors: ['ファイル読み込みエラー: $e'],
      );
    }
  }

  /// CSV行からカスタム食品を処理
  Future<void> _processCustomFoodCsvLine(String line) async {
    final fields = _parseCsvLine(line);
    
    if (fields.length < 5) {
      throw '不正なカスタム食品データ形式';
    }
    
    final food = Food(
      id: fields[0],
      name: fields[1],
      calories: int.parse(fields[2]),
      category: _parseFoodCategory(fields[3]),
      isCustom: true,
      createdAt: DateFormat('yyyy-MM-dd').parse(fields[4]),
      updatedAt: DateTime.now(),
    );
    
    await _foodRepository.saveFood(food);
  }

  /// CSV行から食事記録を処理
  Future<void> _processFoodEntryCsvLine(String line) async {
    final fields = _parseCsvLine(line);
    
    if (fields.length < 6) {
      throw '不正な食事記録データ形式';
    }
    
    final entry = FoodEntry(
      id: fields[0],
      userId: 'current_user', // 現在のユーザーIDを使用
      foodId: fields[2],
      date: DateFormat('yyyy-MM-dd').parse(fields[1]),
      quantity: double.parse(fields[3]),
      mealType: _parseMealType(fields[4]),
      calories: int.parse(fields[5]),
      note: fields.length > 6 ? fields[6] : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _foodEntryRepository.saveFoodEntry(entry);
  }

  /// CSV行から体重記録を処理
  Future<void> _processWeightRecordCsvLine(String line) async {
    final fields = _parseCsvLine(line);
    
    if (fields.length < 3) {
      throw '不正な体重記録データ形式';
    }
    
    final record = WeightRecord(
      id: fields[0],
      userId: 'current_user', // 現在のユーザーIDを使用
      date: DateFormat('yyyy-MM-dd').parse(fields[1]),
      weight: double.parse(fields[2]),
      note: fields.length > 3 ? fields[3] : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _weightRepository.saveWeightRecord(record);
  }

  /// CSV行をフィールドに分割
  List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer field = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(field.toString());
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    
    result.add(field.toString());
    return result;
  }

  /// CSVフィールドをエスケープ
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// 食品カテゴリを解析
  FoodCategory _parseFoodCategory(String? category) {
    if (category == null) {
      return FoodCategory.other;
    }
    
    switch (category.toLowerCase()) {
      case 'grain':
        return FoodCategory.grain;
      case 'protein':
        return FoodCategory.protein;
      case 'vegetable':
        return FoodCategory.vegetable;
      case 'fruit':
        return FoodCategory.fruit;
      case 'dairy':
        return FoodCategory.dairy;
      case 'fat':
        return FoodCategory.fat;
      case 'sweet':
        return FoodCategory.sweet;
      case 'beverage':
        return FoodCategory.beverage;
      default:
        return FoodCategory.other;
    }
  }

  /// 食事タイプを解析
  MealType _parseMealType(String? mealType) {
    if (mealType == null) {
      return MealType.snack;
    }
    
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      default:
        return MealType.snack;
    }
  }
}

/// インポート結果クラス
class ImportResult {
  final bool success;
  final int customFoodsCount;
  final int foodEntriesCount;
  final int weightRecordsCount;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.customFoodsCount,
    required this.foodEntriesCount,
    required this.weightRecordsCount,
    required this.errors,
  });
}
