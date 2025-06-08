// 同期プロバイダー
// データ同期の管理とリポジトリとの連携を担当

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncStatus {
  idle,      // 同期待機中
  syncing,   // 同期中
  completed, // 同期完了
  failed,    // 同期失敗
  offline,   // オフライン
}

class SyncProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  SyncStatus _status = SyncStatus.idle;
  String? _error;
  DateTime? _lastSyncTime;
  bool _isAutoSyncEnabled = true;
  
  // 同期キューの数（実際の実装ではリポジトリから取得）
  int _pendingChangesCount = 0;

  SyncProvider() {
    // 接続状態の監視を開始
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // 同期状態
  SyncStatus get status => _status;
  
  // エラーメッセージ
  String? get error => _error;
  
  // 最終同期時刻
  DateTime? get lastSyncTime => _lastSyncTime;
  
  // 自動同期の有効/無効
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  
  // 保留中の変更数
  int get pendingChangesCount => _pendingChangesCount;
  
  // オンライン状態かどうか
  bool get isOnline => _status != SyncStatus.offline;

  // 初期接続状態の確認
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _status = SyncStatus.offline;
      _error = e.toString();
      notifyListeners();
    }
  }

  // 接続状態の更新
  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      _status = SyncStatus.offline;
    } else if (_status == SyncStatus.offline) {
      _status = SyncStatus.idle;
      // オンラインに戻ったら自動同期を実行
      if (_isAutoSyncEnabled && _pendingChangesCount > 0) {
        syncData();
      }
    }
    notifyListeners();
  }

  // 自動同期の設定を変更
  void setAutoSync(bool enabled) {
    _isAutoSyncEnabled = enabled;
    notifyListeners();
  }

  // 手動同期の実行
  Future<void> syncData() async {
    // すでに同期中または接続がない場合は何もしない
    if (_status == SyncStatus.syncing || _status == SyncStatus.offline) {
      return;
    }

    _status = SyncStatus.syncing;
    _error = null;
    notifyListeners();

    try {
      // 実際の同期処理（リポジトリ実装時に置き換え）
      await Future.delayed(const Duration(seconds: 2));
      
      // 同期成功
      _status = SyncStatus.completed;
      _lastSyncTime = DateTime.now();
      _pendingChangesCount = 0;
    } catch (e) {
      _status = SyncStatus.failed;
      _error = e.toString();
    } finally {
      notifyListeners();
      
      // 一定時間後にidle状態に戻す
      if (_status == SyncStatus.completed) {
        Future.delayed(const Duration(seconds: 3), () {
          _status = SyncStatus.idle;
          notifyListeners();
        });
      }
    }
  }

  // 保留中の変更を追加（実際の実装ではリポジトリから呼び出される）
  void addPendingChange() {
    _pendingChangesCount++;
    
    // 自動同期が有効でオンラインの場合は同期を実行
    if (_isAutoSyncEnabled && _status != SyncStatus.offline && _status != SyncStatus.syncing) {
      syncData();
    }
    
    notifyListeners();
  }

  // エラーのクリア
  void clearError() {
    _error = null;
    if (_status == SyncStatus.failed) {
      _status = SyncStatus.idle;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
