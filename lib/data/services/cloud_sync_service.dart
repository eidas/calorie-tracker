// クラウド同期サービス
// Firebase Firestoreとのデータ同期を管理

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/food.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/food_entry_repository.dart';
import '../../domain/repositories/weight_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/food_model.dart';
import '../models/food_entry_model.dart';
import '../models/weight_record_model.dart';
import '../models/user_model.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final UserRepository _userRepository;
  final FoodRepository _foodRepository;
  final FoodEntryRepository _entryRepository;
  final WeightRepository _weightRepository;
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _syncError;

  CloudSyncService(
    this._firestore,
    this._auth,
    this._userRepository,
    this._foodRepository,
    this._entryRepository,
    this._weightRepository,
  );

  /// 同期中かどうか
  bool get isSyncing => _isSyncing;
  
  /// 最後の同期時刻
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// 同期エラー
  String? get syncError => _syncError;

  /// データを同期
  Future<SyncResult> syncData() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同期が既に実行中です',
        syncedItems: 0,
      );
    }
    
    _isSyncing = true;
    _syncError = null;
    
    try {
      // 現在のユーザーIDを取得
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isSyncing = false;
        _syncError = '認証されていません';
        return SyncResult(
          success: false,
          message: '認証されていません',
          syncedItems: 0,
        );
      }
      
      final userId = currentUser.uid;
      
      // 最後の同期時刻を取得
      final lastSync = _lastSyncTime ?? DateTime(2000);
      
      // ローカルデータを取得
      final user = await _userRepository.getCurrentUser();
      final customFoods = await _foodRepository.getCustomFoods();
      final entries = await _entryRepository.getAllFoodEntries();
      final weights = await _weightRepository.getAllWeightRecords();
      
      // ユーザー情報を同期
      if (user != null) {
        await _syncUserData(user, userId);
      }
      
      // カスタム食品を同期
      await _syncCustomFoods(customFoods, userId, lastSync);
      
      // 食事記録を同期
      await _syncFoodEntries(entries, userId, lastSync);
      
      // 体重記録を同期
      await _syncWeightRecords(weights, userId, lastSync);
      
      // 同期完了
      _lastSyncTime = DateTime.now();
      _isSyncing = false;
      
      return SyncResult(
        success: true,
        message: '同期が完了しました',
        syncedItems: customFoods.length + entries.length + weights.length + (user != null ? 1 : 0),
      );
    } catch (e) {
      debugPrint('同期エラー: $e');
      _syncError = e.toString();
      _isSyncing = false;
      
      return SyncResult(
        success: false,
        message: '同期中にエラーが発生しました: $e',
        syncedItems: 0,
      );
    }
  }

  /// データをバックアップ
  Future<BackupResult> backupData() async {
    if (_isSyncing) {
      return BackupResult(
        success: false,
        message: '同期が既に実行中です',
        backupId: null,
      );
    }
    
    _isSyncing = true;
    _syncError = null;
    
    try {
      // 現在のユーザーIDを取得
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isSyncing = false;
        _syncError = '認証されていません';
        return BackupResult(
          success: false,
          message: '認証されていません',
          backupId: null,
        );
      }
      
      final userId = currentUser.uid;
      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // ローカルデータを取得
      final user = await _userRepository.getCurrentUser();
      final customFoods = await _foodRepository.getCustomFoods();
      final entries = await _entryRepository.getAllFoodEntries();
      final weights = await _weightRepository.getAllWeightRecords();
      
      // バックアップデータを作成
      final backupData = {
        'userId': userId,
        'backupId': backupId,
        'createdAt': FieldValue.serverTimestamp(),
        'user': user != null ? UserModel.fromEntity(user).toJson() : null,
        'customFoods': customFoods.map((food) => FoodModel.fromEntity(food).toJson()).toList(),
        'foodEntries': entries.map((entry) => FoodEntryModel.fromEntity(entry).toJson()).toList(),
        'weightRecords': weights.map((weight) => WeightRecordModel.fromEntity(weight).toJson()).toList(),
      };
      
      // Firestoreにバックアップを保存
      await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc(backupId)
        .set(backupData);
      
      _isSyncing = false;
      
      return BackupResult(
        success: true,
        message: 'バックアップが完了しました',
        backupId: backupId,
      );
    } catch (e) {
      debugPrint('バックアップエラー: $e');
      _syncError = e.toString();
      _isSyncing = false;
      
      return BackupResult(
        success: false,
        message: 'バックアップ中にエラーが発生しました: $e',
        backupId: null,
      );
    }
  }

  /// バックアップからデータを復元
  Future<RestoreResult> restoreData(String backupId) async {
    if (_isSyncing) {
      return RestoreResult(
        success: false,
        message: '同期が既に実行中です',
        restoredItems: 0,
      );
    }
    
    _isSyncing = true;
    _syncError = null;
    
    try {
      // 現在のユーザーIDを取得
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isSyncing = false;
        _syncError = '認証されていません';
        return RestoreResult(
          success: false,
          message: '認証されていません',
          restoredItems: 0,
        );
      }
      
      final userId = currentUser.uid;
      
      // バックアップデータを取得
      final backupDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .doc(backupId)
        .get();
      
      if (!backupDoc.exists) {
        _isSyncing = false;
        _syncError = '指定されたバックアップが見つかりません';
        return RestoreResult(
          success: false,
          message: '指定されたバックアップが見つかりません',
          restoredItems: 0,
        );
      }
      
      final backupData = backupDoc.data()!;
      int restoredItems = 0;
      
      // ユーザー情報を復元
      if (backupData['user'] != null) {
        final userModel = UserModel.fromJson(backupData['user']);
        await _userRepository.saveUser(userModel.toEntity());
        restoredItems++;
      }
      
      // カスタム食品を復元
      if (backupData['customFoods'] != null) {
        final List<dynamic> foodsData = backupData['customFoods'];
        for (var foodData in foodsData) {
          final foodModel = FoodModel.fromJson(foodData);
          await _foodRepository.saveFood(foodModel.toEntity());
          restoredItems++;
        }
      }
      
      // 食事記録を復元
      if (backupData['foodEntries'] != null) {
        final List<dynamic> entriesData = backupData['foodEntries'];
        for (var entryData in entriesData) {
          final entryModel = FoodEntryModel.fromJson(entryData);
          await _entryRepository.saveFoodEntry(entryModel.toEntity());
          restoredItems++;
        }
      }
      
      // 体重記録を復元
      if (backupData['weightRecords'] != null) {
        final List<dynamic> weightsData = backupData['weightRecords'];
        for (var weightData in weightsData) {
          final weightModel = WeightRecordModel.fromJson(weightData);
          await _weightRepository.saveWeightRecord(weightModel.toEntity());
          restoredItems++;
        }
      }
      
      _isSyncing = false;
      
      return RestoreResult(
        success: true,
        message: '復元が完了しました',
        restoredItems: restoredItems,
      );
    } catch (e) {
      debugPrint('復元エラー: $e');
      _syncError = e.toString();
      _isSyncing = false;
      
      return RestoreResult(
        success: false,
        message: '復元中にエラーが発生しました: $e',
        restoredItems: 0,
      );
    }
  }

  /// ユーザーデータを同期
  Future<void> _syncUserData(User user, String userId) async {
    try {
      // ユーザードキュメントを取得
      final userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
      
      // ユーザーモデルを作成
      final userModel = UserModel.fromEntity(user);
      
      if (!userDoc.exists) {
        // ユーザードキュメントが存在しない場合は作成
        await _firestore
          .collection('users')
          .doc(userId)
          .set(userModel.toJson());
      } else {
        // ユーザードキュメントが存在する場合は更新
        final firestoreData = userDoc.data()!;
        final firestoreUpdatedAt = firestoreData['updatedAt'] != null
          ? (firestoreData['updatedAt'] as Timestamp).toDate()
          : DateTime(2000);
        
        if (user.updatedAt.isAfter(firestoreUpdatedAt)) {
          // ローカルデータが新しい場合はFirestoreを更新
          await _firestore
            .collection('users')
            .doc(userId)
            .update(userModel.toJson());
        } else if (firestoreUpdatedAt.isAfter(user.updatedAt)) {
          // Firestoreデータが新しい場合はローカルを更新
          final firestoreUser = UserModel.fromJson(firestoreData).toEntity();
          await _userRepository.updateUser(firestoreUser);
        }
      }
    } catch (e) {
      debugPrint('ユーザーデータ同期エラー: $e');
      rethrow;
    }
  }

  /// カスタム食品を同期
  Future<void> _syncCustomFoods(List<Food> foods, String userId, DateTime lastSync) async {
    try {
      // カスタム食品のみを同期
      final customFoods = foods.where((food) => food.isCustom).toList();
      
      // Firestoreからカスタム食品を取得
      final foodsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('foods')
        .where('isCustom', isEqualTo: true)
        .get();
      
      // Firestoreの食品をマップに変換
      final Map<String, Map<String, dynamic>> firestoreFoods = {};
      for (var doc in foodsSnapshot.docs) {
        firestoreFoods[doc.id] = doc.data();
      }
      
      // ローカルの食品をアップロード
      for (var food in customFoods) {
        final foodModel = FoodModel.fromEntity(food);
        final foodJson = foodModel.toJson();
        
        if (firestoreFoods.containsKey(food.id)) {
          // 既存の食品を更新
          final firestoreUpdatedAt = firestoreFoods[food.id]!['updatedAt'] != null
            ? (firestoreFoods[food.id]!['updatedAt'] as Timestamp).toDate()
            : DateTime(2000);
          
          if (food.updatedAt.isAfter(firestoreUpdatedAt)) {
            // ローカルデータが新しい場合はFirestoreを更新
            await _firestore
              .collection('users')
              .doc(userId)
              .collection('foods')
              .doc(food.id)
              .update(foodJson);
          } else if (firestoreUpdatedAt.isAfter(food.updatedAt)) {
            // Firestoreデータが新しい場合はローカルを更新
            final firestoreFood = FoodModel.fromJson(firestoreFoods[food.id]!).toEntity();
            await _foodRepository.updateFood(firestoreFood);
          }
        } else {
          // 新規の食品を作成
          await _firestore
            .collection('users')
            .doc(userId)
            .collection('foods')
            .doc(food.id)
            .set(foodJson);
        }
      }
      
      // Firestoreの新しい食品をダウンロード
      for (var entry in firestoreFoods.entries) {
        final foodId = entry.key;
        final foodData = entry.value;
        final updatedAt = foodData['updatedAt'] != null
          ? (foodData['updatedAt'] as Timestamp).toDate()
          : DateTime(2000);
        
        // 最後の同期以降に更新された食品のみを処理
        if (updatedAt.isAfter(lastSync)) {
          final existingFood = customFoods.firstWhere(
            (f) => f.id == foodId,
            orElse: () => Food(
              id: '',
              name: '',
              calories: 0,
              category: FoodCategory.other,
              isCustom: true,
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );
          
          if (existingFood.id.isEmpty) {
            // ローカルに存在しない場合は新規作成
            final firestoreFood = FoodModel.fromJson(foodData).toEntity();
            await _foodRepository.saveFood(firestoreFood);
          }
        }
      }
    } catch (e) {
      debugPrint('カスタム食品同期エラー: $e');
      rethrow;
    }
  }

  /// 食事記録を同期
  Future<void> _syncFoodEntries(List<FoodEntry> entries, String userId, DateTime lastSync) async {
    try {
      // Firestoreから食事記録を取得
      final entriesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('foodEntries')
        .get();
      
      // Firestoreの食事記録をマップに変換
      final Map<String, Map<String, dynamic>> firestoreEntries = {};
      for (var doc in entriesSnapshot.docs) {
        firestoreEntries[doc.id] = doc.data();
      }
      
      // ローカルの食事記録をアップロード
      for (var entry in entries) {
        final entryModel = FoodEntryModel.fromEntity(entry);
        final entryJson = entryModel.toJson();
        
        if (firestoreEntries.containsKey(entry.id)) {
          // 既存の食事記録を更新
          final firestoreUpdatedAt = firestoreEntries[entry.id]!['updatedAt'] != null
            ? (firestoreEntries[entry.id]!['updatedAt'] as Timestamp).toDate()
            : DateTime(2000);
          
          if (entry.updatedAt.isAfter(firestoreUpdatedAt)) {
            // ローカルデータが新しい場合はFirestoreを更新
            await _firestore
              .collection('users')
              .doc(userId)
              .collection('foodEntries')
              .doc(entry.id)
              .update(entryJson);
          } else if (firestoreUpdatedAt.isAfter(entry.updatedAt)) {
            // Firestoreデータが新しい場合はローカルを更新
            final firestoreEntry = FoodEntryModel.fromJson(firestoreEntries[entry.id]!).toEntity();
            await _entryRepository.updateFoodEntry(firestoreEntry);
          }
        } else {
          // 新規の食事記録を作成
          await _firestore
            .collection('users')
            .doc(userId)
            .collection('foodEntries')
            .doc(entry.id)
            .set(entryJson);
        }
      }
      
      // Firestoreの新しい食事記録をダウンロード
      for (var entry in firestoreEntries.entries) {
        final entryId = entry.key;
        final entryData = entry.value;
        final updatedAt = entryData['updatedAt'] != null
          ? (entryData['updatedAt'] as Timestamp).toDate()
          : DateTime(2000);
        
        // 最後の同期以降に更新された食事記録のみを処理
        if (updatedAt.isAfter(lastSync)) {
          final existingEntry = entries.firstWhere(
            (e) => e.id == entryId,
            orElse: () => FoodEntry(
              id: '',
              userId: '',
              foodId: '',
              date: DateTime(2000),
              quantity: 0,
              mealType: MealType.other,
              calories: 0,
              note: null,
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );
          
          if (existingEntry.id.isEmpty) {
            // ローカルに存在しない場合は新規作成
            final firestoreEntry = FoodEntryModel.fromJson(entryData).toEntity();
            await _entryRepository.saveFoodEntry(firestoreEntry);
          }
        }
      }
    } catch (e) {
      debugPrint('食事記録同期エラー: $e');
      rethrow;
    }
  }

  /// 体重記録を同期
  Future<void> _syncWeightRecords(List<WeightRecord> weights, String userId, DateTime lastSync) async {
    try {
      // Firestoreから体重記録を取得
      final weightsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('weightRecords')
        .get();
      
      // Firestoreの体重記録をマップに変換
      final Map<String, Map<String, dynamic>> firestoreWeights = {};
      for (var doc in weightsSnapshot.docs) {
        firestoreWeights[doc.id] = doc.data();
      }
      
      // ローカルの体重記録をアップロード
      for (var weight in weights) {
        final weightModel = WeightRecordModel.fromEntity(weight);
        final weightJson = weightModel.toJson();
        
        if (firestoreWeights.containsKey(weight.id)) {
          // 既存の体重記録を更新
          final firestoreUpdatedAt = firestoreWeights[weight.id]!['updatedAt'] != null
            ? (firestoreWeights[weight.id]!['updatedAt'] as Timestamp).toDate()
            : DateTime(2000);
          
          if (weight.updatedAt.isAfter(firestoreUpdatedAt)) {
            // ローカルデータが新しい場合はFirestoreを更新
            await _firestore
              .collection('users')
              .doc(userId)
              .collection('weightRecords')
              .doc(weight.id)
              .update(weightJson);
          } else if (firestoreUpdatedAt.isAfter(weight.updatedAt)) {
            // Firestoreデータが新しい場合はローカルを更新
            final firestoreWeight = WeightRecordModel.fromJson(firestoreWeights[weight.id]!).toEntity();
            await _weightRepository.updateWeightRecord(firestoreWeight);
          }
        } else {
          // 新規の体重記録を作成
          await _firestore
            .collection('users')
            .doc(userId)
            .collection('weightRecords')
            .doc(weight.id)
            .set(weightJson);
        }
      }
      
      // Firestoreの新しい体重記録をダウンロード
      for (var entry in firestoreWeights.entries) {
        final weightId = entry.key;
        final weightData = entry.value;
        final updatedAt = weightData['updatedAt'] != null
          ? (weightData['updatedAt'] as Timestamp).toDate()
          : DateTime(2000);
        
        // 最後の同期以降に更新された体重記録のみを処理
        if (updatedAt.isAfter(lastSync)) {
          final existingWeight = weights.firstWhere(
            (w) => w.id == weightId,
            orElse: () => WeightRecord(
              id: '',
              userId: '',
              date: DateTime(2000),
              weight: 0,
              note: null,
              createdAt: DateTime(2000),
              updatedAt: DateTime(2000),
            ),
          );
          
          if (existingWeight.id.isEmpty) {
            // ローカルに存在しない場合は新規作成
            final firestoreWeight = WeightRecordModel.fromJson(weightData).toEntity();
            await _weightRepository.saveWeightRecord(firestoreWeight);
          }
        }
      }
    } catch (e) {
      debugPrint('体重記録同期エラー: $e');
      rethrow;
    }
  }
}

/// 同期結果クラス
class SyncResult {
  final bool success;
  final String message;
  final int syncedItems;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedItems,
  });
}

/// バックアップ結果クラス
class BackupResult {
  final bool success;
  final String message;
  final String? backupId;

  BackupResult({
    required this.success,
    required this.message,
    required this.backupId,
  });
}

/// 復元結果クラス
class RestoreResult {
  final bool success;
  final String message;
  final int restoredItems;

  RestoreResult({
    required this.success,
    required this.message,
    required this.restoredItems,
  });
}
