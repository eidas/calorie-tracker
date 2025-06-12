// クラウド同期サービス
// Firebase Firestoreとのデータ同期機能を提供

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/food_entry.dart';
import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/repositories/food_entry_repository.dart';
import '../../domain/repositories/weight_repository.dart';

class CloudSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FoodRepository _foodRepository;
  final FoodEntryRepository _foodEntryRepository;
  final WeightRepository _weightRepository;

  CloudSyncService(
    this._foodRepository,
    this._foodEntryRepository,
    this._weightRepository, {
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// データを同期
  Future<SyncResult> syncData() async {
    try {
      // 認証チェック
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return SyncResult(
          success: false,
          message: '認証されていません。ログインしてください。',
          syncedItems: 0,
        );
      }

      final userId = currentUser.uid;
      int syncedItems = 0;

      // カスタム食品の同期
      syncedItems += await _syncCustomFoods(userId);

      // 食事記録の同期
      syncedItems += await _syncFoodEntries(userId);

      // 体重記録の同期
      syncedItems += await _syncWeightRecords(userId);

      return SyncResult(
        success: true,
        message: '$syncedItems 件のデータを同期しました。',
        syncedItems: syncedItems,
      );
    } catch (e) {
      debugPrint('データ同期エラー: $e');
      return SyncResult(
        success: false,
        message: '同期中にエラーが発生しました: $e',
        syncedItems: 0,
      );
    }
  }

  /// データをバックアップ
  Future<BackupResult> backupData() async {
    try {
      // 認証チェック
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return BackupResult(
          success: false,
          message: '認証されていません。ログインしてください。',
          backupId: null,
        );
      }

      final userId = currentUser.uid;
      final timestamp = DateTime.now();
      final backupId = 'backup_${timestamp.millisecondsSinceEpoch}';

      // バックアップメタデータを作成
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .set({
        'timestamp': timestamp,
        'backupId': backupId,
        'userId': userId,
        'deviceInfo': await _getDeviceInfo(),
      });

      // カスタム食品のバックアップ
      await _backupCustomFoods(userId, backupId);

      // 食事記録のバックアップ
      await _backupFoodEntries(userId, backupId);

      // 体重記録のバックアップ
      await _backupWeightRecords(userId, backupId);

      return BackupResult(
        success: true,
        message: 'バックアップが正常に作成されました。',
        backupId: backupId,
      );
    } catch (e) {
      debugPrint('バックアップエラー: $e');
      return BackupResult(
        success: false,
        message: 'バックアップ中にエラーが発生しました: $e',
        backupId: null,
      );
    }
  }

  /// バックアップからデータを復元
  Future<RestoreResult> restoreData(String backupId) async {
    try {
      // 認証チェック
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return RestoreResult(
          success: false,
          message: '認証されていません。ログインしてください。',
          restoredItems: 0,
        );
      }

      final userId = currentUser.uid;
      int restoredItems = 0;

      // バックアップの存在確認
      final backupDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        return RestoreResult(
          success: false,
          message: '指定されたバックアップが見つかりません。',
          restoredItems: 0,
        );
      }

      // カスタム食品の復元
      restoredItems += await _restoreCustomFoods(userId, backupId);

      // 食事記録の復元
      restoredItems += await _restoreFoodEntries(userId, backupId);

      // 体重記録の復元
      restoredItems += await _restoreWeightRecords(userId, backupId);

      return RestoreResult(
        success: true,
        message: '$restoredItems 件のデータを復元しました。',
        restoredItems: restoredItems,
      );
    } catch (e) {
      debugPrint('復元エラー: $e');
      return RestoreResult(
        success: false,
        message: '復元中にエラーが発生しました: $e',
        restoredItems: 0,
      );
    }
  }

  /// カスタム食品を同期
  Future<int> _syncCustomFoods(String userId) async {
    int syncedItems = 0;

    try {
      // ローカルのカスタム食品を取得
      final localFoods = await _foodRepository.getCustomFoods();
      
      // Firestoreのカスタム食品を取得
      final firestoreFoodsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foods')
          .where('isCustom', isEqualTo: true)
          .get();
      
      // Firestoreの食品をマップに変換
      final Map<String, Map<String, dynamic>> firestoreFoods = {};
      for (var doc in firestoreFoodsSnapshot.docs) {
        firestoreFoods[doc.id] = doc.data();
      }
      
      // ローカルの食品をFirestoreに同期
      for (var localFood in localFoods) {
        final firestoreFood = firestoreFoods[localFood.id];
        
        // Firestoreに存在しない、または更新が必要な場合
        if (firestoreFood == null || 
            DateTime.parse(firestoreFood['updatedAt']).isBefore(localFood.updatedAt)) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('foods')
              .doc(localFood.id)
              .set({
            'name': localFood.name,
            'calories': localFood.calories,
            'category': localFood.category.toString().split('.').last,
            'isCustom': true,
            'createdAt': localFood.createdAt.toIso8601String(),
            'updatedAt': localFood.updatedAt.toIso8601String(),
          });
          syncedItems++;
        }
      }
      
      // Firestoreの食品をローカルに同期
      for (var entry in firestoreFoods.entries) {
        final foodId = entry.key;
        final firestoreFood = entry.value;
        
        // ローカルに存在するか確認
        final localFood = localFoods.firstWhere(
          (food) => food.id == foodId,
          orElse: () => Food(
            id: '',
            name: '',
            calories: 0,
            category: FoodCategory.other,
            isCustom: true,
            createdAt: DateTime(1970),
            updatedAt: DateTime(1970),
          ),
        );
        
        // ローカルに存在しない、または更新が必要な場合
        if (localFood.id.isEmpty || 
            localFood.updatedAt.isBefore(DateTime.parse(firestoreFood['updatedAt']))) {
          final food = Food(
            id: foodId,
            name: firestoreFood['name'],
            calories: firestoreFood['calories'],
            category: _parseFoodCategory(firestoreFood['category']),
            isCustom: true,
            createdAt: DateTime.parse(firestoreFood['createdAt']),
            updatedAt: DateTime.parse(firestoreFood['updatedAt']),
          );
          
          await _foodRepository.saveFood(food);
          syncedItems++;
        }
      }
      
      return syncedItems;
    } catch (e) {
      debugPrint('カスタム食品同期エラー: $e');
      return syncedItems;
    }
  }

  /// 食事記録を同期
  Future<int> _syncFoodEntries(String userId) async {
    int syncedItems = 0;

    try {
      // 過去30日間の食事記録のみ同期
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      
      // ローカルの食事記録を取得
      final localEntries = await _foodEntryRepository.getFoodEntriesByDateRange(
        thirtyDaysAgo,
        now,
      );
      
      // Firestoreの食事記録を取得
      final firestoreEntriesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foodEntries')
          .where('date', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
          .get();
      
      // Firestoreの食事記録をマップに変換
      final Map<String, Map<String, dynamic>> firestoreEntries = {};
      for (var doc in firestoreEntriesSnapshot.docs) {
        firestoreEntries[doc.id] = doc.data();
      }
      
      // ローカルの食事記録をFirestoreに同期
      for (var localEntry in localEntries) {
        final firestoreEntry = firestoreEntries[localEntry.id];
        
        // Firestoreに存在しない、または更新が必要な場合
        if (firestoreEntry == null || 
            DateTime.parse(firestoreEntry['updatedAt']).isBefore(localEntry.updatedAt)) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('foodEntries')
              .doc(localEntry.id)
              .set({
            'userId': userId,
            'foodId': localEntry.foodId,
            'date': localEntry.date.toIso8601String(),
            'quantity': localEntry.quantity,
            'mealType': localEntry.mealType.toString().split('.').last,
            'calories': localEntry.calories,
            'note': localEntry.note,
            'createdAt': localEntry.createdAt.toIso8601String(),
            'updatedAt': localEntry.updatedAt.toIso8601String(),
          });
          syncedItems++;
        }
      }
      
      // Firestoreの食事記録をローカルに同期
      for (var entry in firestoreEntries.entries) {
        final entryId = entry.key;
        final firestoreEntry = entry.value;
        
        // ローカルに存在するか確認
        final localEntry = localEntries.firstWhere(
          (e) => e.id == entryId,
          orElse: () => FoodEntry(
            id: '',
            userId: '',
            foodId: '',
            date: DateTime(1970),
            quantity: 0,
            mealType: MealType.snack,
            calories: 0,
            createdAt: DateTime(1970),
            updatedAt: DateTime(1970),
          ),
        );
        
        // ローカルに存在しない、または更新が必要な場合
        if (localEntry.id.isEmpty || 
            localEntry.updatedAt.isBefore(DateTime.parse(firestoreEntry['updatedAt']))) {
          final entry = FoodEntry(
            id: entryId,
            userId: userId,
            foodId: firestoreEntry['foodId'],
            date: DateTime.parse(firestoreEntry['date']),
            quantity: firestoreEntry['quantity'].toDouble(),
            mealType: _parseMealType(firestoreEntry['mealType']),
            calories: firestoreEntry['calories'],
            note: firestoreEntry['note'],
            createdAt: DateTime.parse(firestoreEntry['createdAt']),
            updatedAt: DateTime.parse(firestoreEntry['updatedAt']),
          );
          
          await _foodEntryRepository.saveFoodEntry(entry);
          syncedItems++;
        }
      }
      
      return syncedItems;
    } catch (e) {
      debugPrint('食事記録同期エラー: $e');
      return syncedItems;
    }
  }

  /// 体重記録を同期
  Future<int> _syncWeightRecords(String userId) async {
    int syncedItems = 0;

    try {
      // 過去90日間の体重記録のみ同期
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));
      
      // ローカルの体重記録を取得
      final localRecords = await _weightRepository.getWeightRecordsByDateRange(
        ninetyDaysAgo,
        now,
      );
      
      // Firestoreの体重記録を取得
      final firestoreRecordsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weightRecords')
          .where('date', isGreaterThanOrEqualTo: ninetyDaysAgo.toIso8601String())
          .get();
      
      // Firestoreの体重記録をマップに変換
      final Map<String, Map<String, dynamic>> firestoreRecords = {};
      for (var doc in firestoreRecordsSnapshot.docs) {
        firestoreRecords[doc.id] = doc.data();
      }
      
      // ローカルの体重記録をFirestoreに同期
      for (var localRecord in localRecords) {
        final firestoreRecord = firestoreRecords[localRecord.id];
        
        // Firestoreに存在しない、または更新が必要な場合
        if (firestoreRecord == null || 
            DateTime.parse(firestoreRecord['updatedAt']).isBefore(localRecord.updatedAt)) {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('weightRecords')
              .doc(localRecord.id)
              .set({
            'userId': userId,
            'date': localRecord.date.toIso8601String(),
            'weight': localRecord.weight,
            'note': localRecord.note,
            'createdAt': localRecord.createdAt.toIso8601String(),
            'updatedAt': localRecord.updatedAt.toIso8601String(),
          });
          syncedItems++;
        }
      }
      
      // Firestoreの体重記録をローカルに同期
      for (var entry in firestoreRecords.entries) {
        final recordId = entry.key;
        final firestoreRecord = entry.value;
        
        // ローカルに存在するか確認
        final localRecord = localRecords.firstWhere(
          (r) => r.id == recordId,
          orElse: () => WeightRecord(
            id: '',
            userId: '',
            date: DateTime(1970),
            weight: 0,
            createdAt: DateTime(1970),
            updatedAt: DateTime(1970),
          ),
        );
        
        // ローカルに存在しない、または更新が必要な場合
        if (localRecord.id.isEmpty || 
            localRecord.updatedAt.isBefore(DateTime.parse(firestoreRecord['updatedAt']))) {
          final record = WeightRecord(
            id: recordId,
            userId: userId,
            date: DateTime.parse(firestoreRecord['date']),
            weight: firestoreRecord['weight'].toDouble(),
            note: firestoreRecord['note'],
            createdAt: DateTime.parse(firestoreRecord['createdAt']),
            updatedAt: DateTime.parse(firestoreRecord['updatedAt']),
          );
          
          await _weightRepository.saveWeightRecord(record);
          syncedItems++;
        }
      }
      
      return syncedItems;
    } catch (e) {
      debugPrint('体重記録同期エラー: $e');
      return syncedItems;
    }
  }

  /// カスタム食品をバックアップ
  Future<void> _backupCustomFoods(String userId, String backupId) async {
    try {
      // ローカルのカスタム食品を取得
      final foods = await _foodRepository.getCustomFoods();
      
      // バッチ処理用のリファレンス
      final backupRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .collection('foods');
      
      // 一括書き込み
      final batch = _firestore.batch();
      
      for (var food in foods) {
        final docRef = backupRef.doc(food.id);
        batch.set(docRef, {
          'name': food.name,
          'calories': food.calories,
          'category': food.category.toString().split('.').last,
          'isCustom': true,
          'createdAt': food.createdAt.toIso8601String(),
          'updatedAt': food.updatedAt.toIso8601String(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('カスタム食品バックアップエラー: $e');
    }
  }

  /// 食事記録をバックアップ
  Future<void> _backupFoodEntries(String userId, String backupId) async {
    try {
      // 全ての食事記録を取得
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      final entries = await _foodEntryRepository.getFoodEntriesByDateRange(
        oneYearAgo,
        now,
      );
      
      // バッチ処理用のリファレンス
      final backupRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .collection('foodEntries');
      
      // 一括書き込み（500件ずつ）
      const batchSize = 500;
      for (var i = 0; i < entries.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < entries.length) ? i + batchSize : entries.length;
        
        for (var j = i; j < end; j++) {
          final entry = entries[j];
          final docRef = backupRef.doc(entry.id);
          batch.set(docRef, {
            'userId': userId,
            'foodId': entry.foodId,
            'date': entry.date.toIso8601String(),
            'quantity': entry.quantity,
            'mealType': entry.mealType.toString().split('.').last,
            'calories': entry.calories,
            'note': entry.note,
            'createdAt': entry.createdAt.toIso8601String(),
            'updatedAt': entry.updatedAt.toIso8601String(),
          });
        }
        
        await batch.commit();
      }
    } catch (e) {
      debugPrint('食事記録バックアップエラー: $e');
    }
  }

  /// 体重記録をバックアップ
  Future<void> _backupWeightRecords(String userId, String backupId) async {
    try {
      // 全ての体重記録を取得
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      final records = await _weightRepository.getWeightRecordsByDateRange(
        oneYearAgo,
        now,
      );
      
      // バッチ処理用のリファレンス
      final backupRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .collection('weightRecords');
      
      // 一括書き込み
      final batch = _firestore.batch();
      
      for (var record in records) {
        final docRef = backupRef.doc(record.id);
        batch.set(docRef, {
          'userId': userId,
          'date': record.date.toIso8601String(),
          'weight': record.weight,
          'note': record.note,
          'createdAt': record.createdAt.toIso8601String(),
          'updatedAt': record.updatedAt.toIso8601String(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('体重記録バックアップエラー: $e');
    }
  }

  /// カスタム食品を復元
  Future<int> _restoreCustomFoods(String userId, String backupId) async {
    int restoredItems = 0;

    try {
      // バックアップからカスタム食品を取得
      final foodsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .collection('foods')
          .get();
      
      for (var doc in foodsSnapshot.docs) {
        final data = doc.data();
        
        final food = Food(
          id: doc.id,
          name: data['name'],
          calories: data['calories'],
          category: _parseFoodCategory(data['category']),
          isCustom: true,
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
        
        await _foodRepository.saveFood(food);
        restoredItems++;
      }
      
      return restoredItems;
    } catch (e) {
      debugPrint('カスタム食品復元エラー: $e');
      return restoredItems;
    }
  }

  /// 食事記録を復元
  Future<int> _restoreFoodEntries(String userId, String backupId) async {
    int restoredItems = 0;

    try {
      // バックアップから食事記録を取得
      final entriesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .collection('foodEntries')
          .get();
      
      for (var doc in entriesSnapshot.docs) {
        final data = doc.data();
        
        final entry = FoodEntry(
          id: doc.id,
          userId: userId,
          foodId: data['foodId'],
          date: DateTime.parse(data['date']),
          quantity: data['quantity'].toDouble(),
          mealType: _parseMealType(data['mealType']),
          calories: data['calories'],
          note: data['note'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
        
        await _foodEntryRepository.saveFoodEntry(entry);
        restoredItems++;
      }
      
      return restoredItems;
    } catch (e) {
      debugPrint('食事記録復元エラー: $e');
      return restoredItems;
    }
  }

  /// 体重記録を復元
  Future<int> _restoreWeightRecords(String userId, String backupId) async {
    int restoredItems = 0;

    try {
      // バックアップから体重記録を取得
      final recordsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .collection('weightRecords')
          .get();
      
      for (var doc in recordsSnapshot.docs) {
        final data = doc.data();
        
        final record = WeightRecord(
          id: doc.id,
          userId: userId,
          date: DateTime.parse(data['date']),
          weight: data['weight'].toDouble(),
          note: data['note'],
          createdAt: DateTime.parse(data['createdAt']),
          updatedAt: DateTime.parse(data['updatedAt']),
        );
        
        await _weightRepository.saveWeightRecord(record);
        restoredItems++;
      }
      
      return restoredItems;
    } catch (e) {
      debugPrint('体重記録復元エラー: $e');
      return restoredItems;
    }
  }

  /// デバイス情報を取得
  Future<Map<String, String>> _getDeviceInfo() async {
    // 実際のアプリではdevice_infoパッケージなどを使用して
    // より詳細なデバイス情報を取得することが望ましい
    return {
      'platform': 'Flutter',
      'appVersion': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
    };
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
