// ユーザープロバイダー
// ユーザー情報の管理とリポジトリとの連携を担当

import 'package:flutter/foundation.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._userRepository) {
    // 初期化時にユーザー情報を取得
    _loadCurrentUser();
  }

  // 現在のユーザー
  User? get currentUser => _currentUser;
  
  // ローディング状態
  bool get isLoading => _isLoading;
  
  // エラーメッセージ
  String? get error => _error;

  // ユーザー情報の読み込み
  Future<void> _loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _userRepository.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ユーザー情報の更新
  Future<void> updateUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.updateUser(user);
      _currentUser = user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ユーザー情報の保存（新規作成）
  Future<void> saveUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepository.saveUser(user);
      _currentUser = user;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 目標カロリーの更新
  Future<void> updateTargetCalories(int calories) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      targetCalories: calories,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  // 目標体重の更新
  Future<void> updateTargetWeight(double weight) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      targetWeight: weight,
      updatedAt: DateTime.now(),
    );
    
    await updateUser(updatedUser);
  }

  // エラーのクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ユーザー情報の再読み込み
  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }
}
