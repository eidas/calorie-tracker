// ユーザーリポジトリ実装
// SQLiteを使用したユーザーデータのCRUD操作と認証状態管理を実装

import 'dart:async';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import '../../database/database_helper.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseHelper _databaseHelper;
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  User? _currentUser;

  UserRepositoryImpl(this._databaseHelper);

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    final maps = await _databaseHelper.query(
      'users',
      limit: 1,
      orderBy: 'created_at DESC',
    );
    
    if (maps.isEmpty) return null;
    
    _currentUser = UserModel.fromMap(maps.first).toEntity();
    return _currentUser;
  }

  @override
  Future<void> saveUser(User user) async {
    final userModel = UserModel.fromEntity(user);
    await _databaseHelper.insert('users', userModel.toMap());
    _currentUser = user;
    _authStateController.add(true);
  }

  @override
  Future<void> updateUser(User user) async {
    final userModel = UserModel.fromEntity(user);
    await _databaseHelper.update(
      'users',
      userModel.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    _currentUser = user;
  }

  @override
  Stream<bool> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(false);
  }

  Future<User?> getUserById(String userId) async {
    final maps = await _databaseHelper.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first).toEntity();
  }

  Future<User?> getUserByEmail(String email) async {
    final maps = await _databaseHelper.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first).toEntity();
  }

  Future<List<User>> getAllUsers() async {
    final maps = await _databaseHelper.query(
      'users',
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => UserModel.fromMap(map).toEntity()).toList();
  }

  Future<void> deleteUser(String userId) async {
    await _databaseHelper.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (_currentUser?.id == userId) {
      _currentUser = null;
      _authStateController.add(false);
    }
  }

  Future<bool> userExists(String userId) async {
    final result = await _databaseHelper.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE id = ?',
      [userId],
    );
    
    return (result.first['count'] as int) > 0;
  }

  Future<bool> emailExists(String email) async {
    final result = await _databaseHelper.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE email = ?',
      [email],
    );
    
    return (result.first['count'] as int) > 0;
  }

  Future<int> getUserCount() async {
    final result = await _databaseHelper.rawQuery(
      'SELECT COUNT(*) as count FROM users',
    );
    return result.first['count'] as int;
  }

  Future<void> clearCurrentUser() async {
    _currentUser = null;
  }

  Future<void> setCurrentUser(User user) async {
    _currentUser = user;
    _authStateController.add(true);
  }

  bool get isAuthenticated => _currentUser != null;

  void dispose() {
    _authStateController.close();
  }
}
