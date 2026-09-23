import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/drift_store_database_manager.dart';
import 'package:tally/infrastructure/store/secure_storage_store_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('DriftStoreDatabaseManager', () {
    late Directory tempDir;
    late SecureStorageStoreKeyManager keyManager;
    late DriftStoreDatabaseManager dbManager;
    const testStoreId = StoreId('store_test_001');

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('tally_db_test_');
      keyManager = SecureStorageStoreKeyManager();
      dbManager = DriftStoreDatabaseManager(
        baseDirectory: tempDir.path,
        keyManager: keyManager,
      );
    });

    tearDown(() async {
      await dbManager.close(testStoreId);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('create initializes physical .db file and tables', () async {
      expect((await dbManager.exists(testStoreId)).valueOrNull, isFalse);

      final createResult = await dbManager.create(testStoreId);
      expect(createResult.isSuccess, isTrue);

      expect((await dbManager.exists(testStoreId)).valueOrNull, isTrue);
      final filePath =
          (await dbManager.getDatabaseFilePath(testStoreId)).valueOrNull;
      expect(filePath, contains('store_test_001.db'));
      expect(File(filePath!).existsSync(), isTrue);
    });

    test('validateIntegrity returns true for valid created store database',
        () async {
      await dbManager.create(testStoreId);
      final integrity = await dbManager.validateIntegrity(testStoreId);
      expect(integrity.isSuccess, isTrue);
      expect(integrity.valueOrNull, isTrue);
    });

    test('checkpoint flushes WAL without errors', () async {
      await dbManager.create(testStoreId);
      final checkpointResult = await dbManager.checkpoint(testStoreId);
      expect(checkpointResult.isSuccess, isTrue);
    });

    test('delete closes and removes physical database file', () async {
      await dbManager.create(testStoreId);
      expect((await dbManager.exists(testStoreId)).valueOrNull, isTrue);

      final deleteResult = await dbManager.delete(testStoreId);
      expect(deleteResult.isSuccess, isTrue);
      expect((await dbManager.exists(testStoreId)).valueOrNull, isFalse);
    });
  });
}
