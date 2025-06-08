// 体重記録プロバイダー
// 体重記録の管理とリポジトリとの連携を担当

import 'package:flutter/foundation.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/weight_repository.dart';

class WeightProvider with ChangeNotifier {
  final WeightRepository _weightRepository;
  List<WeightRecord> _weightRecords = [];
  WeightRecord? _latestRecord;
  bool _isLoading = false;
  String? _error;

  WeightProvider(this._weightRepository) {
    // 初期化時に体重記録を読み込み
    _loadLatestWeightRecord();
  }

  // 体重記録リスト
  List<WeightRecord> get weightRecords => _weightRecords;
  
  // 最新の体重記録
  WeightRecord? get latestRecord => _latestRecord;
  
  // ローディング状態
  bool get isLoading => _isLoading;
  
  // エラーメッセージ
  String? get error => _error;

  // 最新の体重記録を読み込み
  Future<void> _loadLatestWeightRecord() async {
    _isLoading = true;
    notifyListeners();

    try {
      _latestRecord = await _weightRepository.getLatestWeightRecord();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 特定の日付の体重記録を取得
  Future<WeightRecord?> getWeightRecordByDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final record = await _weightRepository.getWeightRecordByDate(date);
      _error = null;
      return record;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 日付範囲の体重記録を読み込み
  Future<void> loadWeightRecordsByDateRange(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      _weightRecords = await _weightRepository.getWeightRecordsByDateRange(startDate, endDate);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 体重記録を保存（新規作成）
  Future<void> saveWeightRecord(WeightRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _weightRepository.saveWeightRecord(record);
      await _loadLatestWeightRecord();
      
      // 日付範囲が読み込まれている場合は再読み込み
      if (_weightRecords.isNotEmpty) {
        final startDate = _weightRecords.first.date;
        final endDate = _weightRecords.last.date;
        await loadWeightRecordsByDateRange(startDate, endDate);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 体重記録を更新
  Future<void> updateWeightRecord(WeightRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _weightRepository.updateWeightRecord(record);
      await _loadLatestWeightRecord();
      
      // 日付範囲が読み込まれている場合は再読み込み
      if (_weightRecords.isNotEmpty) {
        final startDate = _weightRecords.first.date;
        final endDate = _weightRecords.last.date;
        await loadWeightRecordsByDateRange(startDate, endDate);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 体重記録を削除
  Future<void> deleteWeightRecord(String recordId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _weightRepository.deleteWeightRecord(recordId);
      await _loadLatestWeightRecord();
      
      // 日付範囲が読み込まれている場合は再読み込み
      if (_weightRecords.isNotEmpty) {
        final startDate = _weightRecords.first.date;
        final endDate = _weightRecords.last.date;
        await loadWeightRecordsByDateRange(startDate, endDate);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // エラーのクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 体重記録の再読み込み
  Future<void> refreshWeightRecords() async {
    await _loadLatestWeightRecord();
    
    // 日付範囲が読み込まれている場合は再読み込み
    if (_weightRecords.isNotEmpty) {
      final startDate = _weightRecords.first.date;
      final endDate = _weightRecords.last.date;
      await loadWeightRecordsByDateRange(startDate, endDate);
    }
  }
}
