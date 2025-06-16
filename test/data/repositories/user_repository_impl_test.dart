import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zubora_calorie/database/database_helper.dart';
import 'package:zubora_calorie/data/repositories/user_repository_impl.dart';
import 'package:zubora_calorie/domain/entities/user.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late UserRepositoryImpl userRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.deleteDatabase();
    userRepository = UserRepositoryImpl(databaseHelper);
    
    await databaseHelper.database;
  });

  tearDown(() async {
    await databaseHelper.closeDatabase();
  });

  group('UserRepositoryImpl', () {
    test('should save and get current user', () async {
      final user = User(
        id: 'user-1',
        name: 'Test User',
        email: 'test@example.com',
        height: 170.0,
        targetWeight: 65.0,
        targetCalories: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.saveUser(user);
      
      final currentUser = await userRepository.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.name, equals('Test User'));
      expect(currentUser.email, equals('test@example.com'));
      expect(currentUser.height, equals(170.0));
    });

    test('should check if user exists by id', () async {
      final user = User(
        id: 'user-1',
        name: 'Test User',
        email: 'test@example.com',
        height: 170.0,
        targetWeight: 65.0,
        targetCalories: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final existsBefore = await userRepository.userExists('user-1');
      expect(existsBefore, isFalse);
      
      await userRepository.saveUser(user);
      
      final existsAfter = await userRepository.userExists('user-1');
      expect(existsAfter, isTrue);
    });

    test('should check if user exists by email', () async {
      final user = User(
        id: 'user-1',
        name: 'Test User',
        email: 'test@example.com',
        height: 170.0,
        targetWeight: 65.0,
        targetCalories: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final existsBefore = await userRepository.userExistsByEmail('test@example.com');
      expect(existsBefore, isFalse);
      
      await userRepository.saveUser(user);
      
      final existsAfter = await userRepository.userExistsByEmail('test@example.com');
      expect(existsAfter, isTrue);
    });
  });
}
