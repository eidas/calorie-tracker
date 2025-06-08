// 認証プロバイダー
// 認証状態の管理とリポジトリとの連携を担当

import 'package:flutter/foundation.dart';
import '../../domain/repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._userRepository) {
    // 初期化時に認証状態を確認
    _checkAuthState();
    // 認証状態の変更を監視
    _userRepository.authStateChanges.listen((isAuthenticated) {
      _isAuthenticated = isAuthenticated;
      notifyListeners();
    });
  }

  // 認証状態
  bool get isAuthenticated => _isAuthenticated;
  
  // ローディング状態
  bool get isLoading => _isLoading;
  
  // エラーメッセージ
  String? get error => _error;

  // 認証状態の確認
  Future<void> _checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _userRepository.getCurrentUser();
      _isAuthenticated = user != null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ログアウト
  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.signOut();
      _isAuthenticated = false;
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
}
