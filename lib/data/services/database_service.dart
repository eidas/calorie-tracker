// データベースサービス
// リポジトリ間の調整とトランザクション管理を担当

import '../repositories/food_repository_impl.dart';
import '../repositories/food_entry_repository_impl.dart';
import '../repositories/user_repository_impl.dart';
import '../repositories/weight_repository_impl.dart';
import '../../database/database_helper.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  
  late final FoodRepositoryImpl _foodRepository;
  late final FoodEntryRepositoryImpl _foodEntryRepository;
  late final UserRepositoryImpl _userRepository;
  late final WeightRepositoryImpl _weightRepository;
  late final DatabaseHelper _databaseHelper;

  factory DatabaseService() => _instance;

  DatabaseService._internal() {
    _databaseHelper = DatabaseHelper();
    _foodRepository = FoodRepositoryImpl(_databaseHelper);
    _foodEntryRepository = FoodEntryRepositoryImpl(_databaseHelper);
    _userRepository = UserRepositoryImpl(_databaseHelper);
    _weightRepository = WeightRepositoryImpl(_databaseHelper);
  }

  FoodRepositoryImpl get foodRepository => _foodRepository;
  FoodEntryRepositoryImpl get foodEntryRepository => _foodEntryRepository;
  UserRepositoryImpl get userRepository => _userRepository;
  WeightRepositoryImpl get weightRepository => _weightRepository;

  Future<void> initializeDatabase() async {
    await _databaseHelper.database;
  }

  Future<T> runInTransaction<T>(Future<T> Function() action) async {
    return await _databaseHelper.transaction((txn) async {
      return await action();
    });
  }

  Future<void> clearAllData() async {
    await _databaseHelper.transaction((txn) async {
      await txn.delete('food_entries');
      await txn.delete('weight_records');
      await txn.delete('foods');
      await txn.delete('users');
    });
  }

  Future<Map<String, int>> getDataCounts() async {
    final results = await Future.wait([
      _databaseHelper.rawQuery('SELECT COUNT(*) as count FROM users'),
      _databaseHelper.rawQuery('SELECT COUNT(*) as count FROM foods'),
      _databaseHelper.rawQuery('SELECT COUNT(*) as count FROM food_entries'),
      _databaseHelper.rawQuery('SELECT COUNT(*) as count FROM weight_records'),
    ]);

    return {
      'users': results[0].first['count'] as int,
      'foods': results[1].first['count'] as int,
      'food_entries': results[2].first['count'] as int,
      'weight_records': results[3].first['count'] as int,
    };
  }

  Future<void> exportData() async {
    final data = <String, List<Map<String, dynamic>>>{};
    
    data['users'] = await _databaseHelper.query('users');
    data['foods'] = await _databaseHelper.query('foods');
    data['food_entries'] = await _databaseHelper.query('food_entries');
    data['weight_records'] = await _databaseHelper.query('weight_records');
  }

  Future<void> importData(Map<String, List<Map<String, dynamic>>> data) async {
    await _databaseHelper.transaction((txn) async {
      if (data.containsKey('users')) {
        for (final userData in data['users']!) {
          await txn.insert('users', userData);
        }
      }
      
      if (data.containsKey('foods')) {
        for (final foodData in data['foods']!) {
          await txn.insert('foods', foodData);
        }
      }
      
      if (data.containsKey('food_entries')) {
        for (final entryData in data['food_entries']!) {
          await txn.insert('food_entries', entryData);
        }
      }
      
      if (data.containsKey('weight_records')) {
        for (final recordData in data['weight_records']!) {
          await txn.insert('weight_records', recordData);
        }
      }
    });
  }

  Future<void> closeDatabase() async {
    await _databaseHelper.closeDatabase();
  }

  Future<void> deleteDatabase() async {
    await _databaseHelper.deleteDatabase();
  }
}
