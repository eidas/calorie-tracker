// ユーザーリポジトリインターフェース
// ユーザー情報の取得・保存を担当するリポジトリの抽象定義

import '../entities/user.dart';

abstract class UserRepository {
  /// 現在のユーザー情報を取得
  Future<User?> getCurrentUser();

  /// ユーザー情報を保存
  Future<void> saveUser(User user);

  /// ユーザー情報を更新
  Future<void> updateUser(User user);

  /// ユーザーの認証状態を監視するストリーム
  Stream<bool> get authStateChanges;

  /// ユーザーをログアウト
  Future<void> signOut();
}
