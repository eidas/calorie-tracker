// 食事記録プロバイダー
// 食事記録の管理とリポジトリとの連携を担当

import 'package:flutter/foundation.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/repositories/food_entry_repository.dart';

class EntryProvider with ChangeNotifier {
  final FoodEntryRepository _entryRepository;
  List<FoodEntry> _entries = [];
  Map<DateTime, List<FoodEntry>> _entriesByDate = {};
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  EntryProvider(this._entryRepository) {
    // 初期化時に今日の食事記録を読み込み
    loadEntriesByDate(_selectedDate);
  }

  // 全ての食事記録
  List<FoodEntry> get entries => _entries;
  
  // 日付別の食事記録
  Map<DateTime, List<FoodEntry>> get entriesByDate => _entriesByDate;
  
  // 選択中の日付
  DateTime get selectedDate => _selectedDate;
  
  // 選択中の日付の食事記録
  List<FoodEntry> get selectedDateEntries => 
      _entriesByDate[_normalizeDate(_selectedDate)] ?? [];
  
  // ローディング状態
  bool get isLoading => _isLoading;
  
  // エラーメッセージ
  String? get error => _error;

  // 日付の正規化（時間部分を削除）
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 日付を選択
  void selectDate(DateTime date) {
    _selectedDate = date;
    loadEntriesByDate(date);
  }

  // 特定の日付の食事記録を読み込み
  Future<void> loadEntriesByDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    
    // すでに読み込み済みの場合はスキップ
    if (_entriesByDate.containsKey(normalizedDate) && !_isLoading) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final entries = await _entryRepository.getFoodEntriesByDate(normalizedDate);
      _entriesByDate[normalizedDate] = entries;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 日付範囲の食事記録を読み込み
  Future<void> loadEntriesByDateRange(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final entries = await _entryRepository.getFoodEntriesByDateRange(startDate, endDate);
      _entries = entries;
      
      // 日付別にエントリを整理
      _entriesByDate = {};
      for (var entry in entries) {
        final normalizedDate = _normalizeDate(entry.date);
        if (!_entriesByDate.containsKey(normalizedDate)) {
          _entriesByDate[normalizedDate] = [];
        }
        _entriesByDate[normalizedDate]!.add(entry);
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食事タイプ別に食事記録を取得
  Future<List<FoodEntry>> getEntriesByMealType(DateTime date, MealType mealType) async {
    _isLoading = true;
    notifyListeners();

    try {
      final entries = await _entryRepository.getFoodEntriesByMealType(date, mealType);
      _error = null;
      return entries;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食事記録を保存（新規作成）
  Future<void> saveEntry(FoodEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _entryRepository.saveFoodEntry(entry);
      
      // 該当する日付のエントリを再読み込み
      final normalizedDate = _normalizeDate(entry.date);
      final entries = await _entryRepository.getFoodEntriesByDate(normalizedDate);
      _entriesByDate[normalizedDate] = entries;
      
      // 選択中の日付が同じ場合は更新
      if (_normalizeDate(_selectedDate) == normalizedDate) {
        loadEntriesByDate(_selectedDate);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食事記録を更新
  Future<void> updateEntry(FoodEntry entry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _entryRepository.updateFoodEntry(entry);
      
      // 該当する日付のエントリを再読み込み
      final normalizedDate = _normalizeDate(entry.date);
      final entries = await _entryRepository.getFoodEntriesByDate(normalizedDate);
      _entriesByDate[normalizedDate] = entries;
      
      // 選択中の日付が同じ場合は更新
      if (_normalizeDate(_selectedDate) == normalizedDate) {
        loadEntriesByDate(_selectedDate);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 食事記録を削除
  Future<void> deleteEntry(String entryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _entryRepository.deleteFoodEntry(entryId);
      
      // 選択中の日付のエントリを再読み込み
      loadEntriesByDate(_selectedDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 特定の日付の合計カロリーを取得
  Future<int> getTotalCaloriesByDate(DateTime date) async {
    try {
      return await _entryRepository.getTotalCaloriesByDate(date);
    } catch (e) {
      _error = e.toString();
      return 0;
    }
  }

  // エラーのクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 食事記録の再読み込み
  Future<void> refreshEntries() async {
    loadEntriesByDate(_selectedDate);
  }
}
