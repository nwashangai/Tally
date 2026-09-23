import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/persisted_store_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('tally_test_stores_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PersistedStoreRepository', () {
    test('createStore saves store metadata to SharedPreferences', () async {
      final repo = PersistedStoreRepository(
        prefs: prefs,
        storesDirectoryPath: tempDir.path,
      );

      final result = await repo.createStore(
        name: 'Downtown Hardware',
        userId: 'user-42',
      );

      expect(result.isSuccess, isTrue);
      final store = result.valueOrNull!;
      expect(store.name, equals('Downtown Hardware'));
      expect(store.ownerId, equals('user-42'));

      // Check SharedPreferences content
      final savedRaw = prefs.getString(kPrefKeyStoresCatalog);
      expect(savedRaw, isNotNull);
      expect(savedRaw, contains('Downtown Hardware'));
    });

    test('persists stores across multiple repository instances', () async {
      final repo1 = PersistedStoreRepository(
        prefs: prefs,
        storesDirectoryPath: tempDir.path,
      );

      final createResult = await repo1.createStore(
        name: 'Chiagoziems Bakery',
        userId: 'user-100',
      );
      final createdStore = createResult.valueOrNull!;

      // Create brand new repo instance pointing to same SharedPreferences
      final repo2 = PersistedStoreRepository(
        prefs: prefs,
        storesDirectoryPath: tempDir.path,
      );

      final listResult = await repo2.getAccessibleStores('user-100');
      expect(listResult.isSuccess, isTrue);
      final stores = listResult.valueOrNull!;
      expect(stores.length, equals(1));
      expect(stores.first.id, equals(createdStore.id));
      expect(stores.first.name, equals('Chiagoziems Bakery'));
    });

    test('updateStore modifies persisted store data', () async {
      final repo = PersistedStoreRepository(
        prefs: prefs,
        storesDirectoryPath: tempDir.path,
      );

      final createResult = await repo.createStore(
        name: 'Original Store Name',
        userId: 'user-1',
      );
      final store = createResult.valueOrNull!;

      final updatedStore = store.copyWith(name: 'Updated Store Name');
      final updateResult = await repo.updateStore(updatedStore);

      expect(updateResult.isSuccess, isTrue);
      expect(updateResult.valueOrNull!.name, equals('Updated Store Name'));

      final listResult = await repo.getAccessibleStores('user-1');
      expect(listResult.valueOrNull!.first.name, equals('Updated Store Name'));
    });

    test('deleteStore removes store from persisted storage', () async {
      final repo = PersistedStoreRepository(
        prefs: prefs,
        storesDirectoryPath: tempDir.path,
      );

      final createResult = await repo.createStore(
        name: 'Store To Delete',
        userId: 'user-1',
      );
      final store = createResult.valueOrNull!;

      final deleteResult = await repo.deleteStore(store.id);
      expect(deleteResult.isSuccess, isTrue);

      final listResult = await repo.getAccessibleStores('user-1');
      expect(listResult.valueOrNull!, isEmpty);
    });

    test('recovers uncataloged .db files from stores directory', () async {
      // Simulate an existing .db file on disk (e.g. from restore or cold copy)
      final orphanDbFile = File('${tempDir.path}/orphan-store-99.db');
      await orphanDbFile.writeAsString('mock sqlite header');

      final repo = PersistedStoreRepository(
        prefs: prefs,
        storesDirectoryPath: tempDir.path,
      );

      final listResult = await repo.getAccessibleStores('user-recovery');
      expect(listResult.isSuccess, isTrue);

      final stores = listResult.valueOrNull!;
      expect(stores.length, equals(1));
      expect(stores.first.id, equals(const StoreId('orphan-store-99')));
      expect(stores.first.name, contains('orphan-store-99'));
    });
  });
}
