import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/store/current_store_notifier.dart';
import 'package:tally/application/store/current_store_state.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/drift_store_database_manager.dart';
import 'package:tally/infrastructure/store/mock_remote_store_database_repository.dart';
import 'package:tally/infrastructure/store/secure_storage_store_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('CurrentStoreNotifier', () {
    late Directory tempDir;
    late DriftStoreDatabaseManager dbManager;
    late MockRemoteStoreDatabaseRepository remoteRepo;
    late CurrentStoreNotifier notifier;

    final testStore = Store(
      id: const StoreId('store_active_test'),
      name: 'Central Warehouse',
      ownerId: 'user_1',
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('tally_current_test_');
      final keyManager = SecureStorageStoreKeyManager();
      dbManager = DriftStoreDatabaseManager(
        baseDirectory: tempDir.path,
        keyManager: keyManager,
      );
      remoteRepo = MockRemoteStoreDatabaseRepository();
      notifier = CurrentStoreNotifier(
        dbManager: dbManager,
        remoteDbRepo: remoteRepo,
      );
    });

    tearDown(() async {
      await notifier.clearStore();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initial state is NoStoreSelected', () {
      expect(notifier.state, isA<NoStoreSelected>());
    });

    test('selectStore transitions to StoreUnavailable if local DB missing',
        () async {
      await notifier.selectStore(testStore);
      expect(notifier.state, isA<StoreUnavailable>());
    });

    test('selectStore transitions to StoreSelected when DB exists', () async {
      await dbManager.create(testStore.id);

      await notifier.selectStore(testStore);
      expect(notifier.state, isA<StoreSelected>());
      final selected = notifier.state as StoreSelected;
      expect(selected.store.id, testStore.id);
      expect(selected.dbPath, contains('store_active_test.db'));
    });

    test('clearStore closes active DB and resets to NoStoreSelected', () async {
      await dbManager.create(testStore.id);
      await notifier.selectStore(testStore);
      expect(notifier.state, isA<StoreSelected>());

      await notifier.clearStore();
      expect(notifier.state, isA<NoStoreSelected>());
    });
  });
}
