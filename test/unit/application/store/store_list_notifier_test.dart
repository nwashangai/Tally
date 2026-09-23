import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/store/store_list_notifier.dart';
import 'package:tally/infrastructure/store/drift_store_database_manager.dart';
import 'package:tally/infrastructure/store/in_memory_store_repository.dart';
import 'package:tally/infrastructure/store/secure_storage_store_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('StoreListNotifier', () {
    late Directory tempDir;
    late InMemoryStoreRepository storeRepo;
    late DriftStoreDatabaseManager dbManager;
    late StoreListNotifier notifier;
    const userId = 'usr_owner_1';

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('tally_list_test_');
      final keyManager = SecureStorageStoreKeyManager();
      dbManager = DriftStoreDatabaseManager(
        baseDirectory: tempDir.path,
        keyManager: keyManager,
      );
      storeRepo = InMemoryStoreRepository();
      notifier = StoreListNotifier(
        storeRepo: storeRepo,
        dbManager: dbManager,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadStores discovers stores and marks localDbExists accurately',
        () async {
      await notifier.loadStores(userId);
      expect(notifier.state.value, isEmpty);

      // Create a store through notifier (provisions metadata AND DB file)
      final createdResult = await notifier.createStore(
        name: 'Flagship Store',
        userId: userId,
      );
      expect(createdResult.isSuccess, isTrue);

      final items = notifier.state.value!;
      expect(items.length, 1);
      expect(items.first.store.name, 'Flagship Store');
      expect(items.first.localDbExists, isTrue);
    });
  });
}
