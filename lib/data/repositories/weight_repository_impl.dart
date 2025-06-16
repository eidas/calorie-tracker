// 体重記録リポジトリ実装
// SQLiteを使用した体重記録のCRUD操作を実装

import '../../domain/entities/weight_record.dart';
import '../../domain/repositories/weight_repository.dart';
import '../models/weight_record_model.dart';
import '../../database/database_helper.dart';

class WeightRepositoryImpl implements WeightRepository {
  final DatabaseHelper _databaseHelper;

  WeightRepositoryImpl(this._databaseHelper);

  @override
  Future<WeightRecord?> getWeightRecordByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final maps = await _databaseHelper.query(
      'weight_records',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return WeightRecordModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<List<WeightRecord>> getWeightRecordsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startOfDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));
    
    final maps = await _databaseHelper.query(
      'weight_records',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'date ASC',
    );
    
    return maps.map((map) => WeightRecordModel.fromMap(map).toEntity()).toList();
  }

  @override
  Future<WeightRecord?> getLatestWeightRecord() async {
    final maps = await _databaseHelper.query(
      'weight_records',
      orderBy: 'date DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return WeightRecordModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<void> saveWeightRecord(WeightRecord record) async {
    final recordModel = WeightRecordModel.fromEntity(record);
    await _databaseHelper.insert('weight_records', recordModel.toMap());
  }

  @override
  Future<void> updateWeightRecord(WeightRecord record) async {
    final recordModel = WeightRecordModel.fromEntity(record);
    await _databaseHelper.update(
      'weight_records',
      recordModel.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<void> deleteWeightRecord(String recordId) async {
    await _databaseHelper.delete(
      'weight_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<WeightRecord?> getWeightRecordById(String recordId) async {
    final maps = await _databaseHelper.query(
      'weight_records',
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return WeightRecordModel.fromMap(maps.first).toEntity();
  }

  Future<List<WeightRecord>> getWeightRecordsByUserId(String userId) async {
    final maps = await _databaseHelper.query(
      'weight_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => WeightRecordModel.fromMap(map).toEntity()).toList();
  }

  Future<List<WeightRecord>> getRecentWeightRecords({
    int limit = 30,
    String? userId,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause = 'user_id = ?';
      whereArgs.add(userId);
    }
    
    final maps = await _databaseHelper.query(
      'weight_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
      limit: limit,
    );
    
    return maps.map((map) => WeightRecordModel.fromMap(map).toEntity()).toList();
  }

  Future<double?> getAverageWeight({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    
    final result = await _databaseHelper.rawQuery(
      'SELECT AVG(weight) as average FROM weight_records' +
          (whereClause.isEmpty ? '' : ' WHERE $whereClause'),
      whereArgs.isEmpty ? null : whereArgs,
    );
    
    return result.first['average'] as double?;
  }

  Future<Map<String, dynamic>?> getWeightStats({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += 'user_id = ?';
      whereArgs.add(userId);
    }
    
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    
    final result = await _databaseHelper.rawQuery(
      'SELECT MIN(weight) as min_weight, MAX(weight) as max_weight, '
      'AVG(weight) as avg_weight, COUNT(*) as count FROM weight_records' +
          (whereClause.isEmpty ? '' : ' WHERE $whereClause'),
      whereArgs.isEmpty ? null : whereArgs,
    );
    
    final row = result.first;
    if (row['count'] == 0) return null;
    
    return {
      'minWeight': row['min_weight'] as double?,
      'maxWeight': row['max_weight'] as double?,
      'avgWeight': row['avg_weight'] as double?,
      'count': row['count'] as int,
    };
  }

  Future<int> getWeightRecordCount() async {
    final result = await _databaseHelper.rawQuery(
      'SELECT COUNT(*) as count FROM weight_records',
    );
    return result.first['count'] as int;
  }

  Future<void> deleteWeightRecordsByUserId(String userId) async {
    await _databaseHelper.delete(
      'weight_records',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> hasWeightRecordForDate(DateTime date, String userId) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final result = await _databaseHelper.rawQuery(
      'SELECT COUNT(*) as count FROM weight_records '
      'WHERE user_id = ? AND date >= ? AND date < ?',
      [
        userId,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    
    return (result.first['count'] as int) > 0;
  }
}
