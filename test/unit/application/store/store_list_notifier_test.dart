import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/store/store_export_service.dart';
import 'package:tally/application/store/store_list_notifier.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/infrastructure/item/drift_item_repository.dart';
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

    test('importStoreFromBackup imports valid database and updates stores list',
        () async {
      // 1. Create a source store to produce a valid SQLite DB file
      final createRes = await notifier.createStore(
        name: 'Original Store',
        userId: userId,
      );
      expect(createRes.isSuccess, isTrue);
      final origStore = createRes.valueOrNull!;

      final filePathRes = await dbManager.getDatabaseFilePath(origStore.id);
      expect(filePathRes.isSuccess, isTrue);
      final sourceBytes = await File(filePathRes.valueOrNull!).readAsBytes();

      // 2. Import into a new store from the valid DB bytes
      final importRes = await notifier.importStoreFromBackup(
        fileBytes: sourceBytes,
        fileName: 'Tally_Original_Store_Backup_2026-09-24.db',
        userId: userId,
        storeName: 'Restored Store',
      );

      expect(importRes.isSuccess, isTrue);
      final importedStore = importRes.valueOrNull!;
      expect(importedStore.name, 'Restored Store');

      // Verify list has both stores now and local DB exists for both
      final items = notifier.state.value!;
      expect(items.length, 2);
      expect(items.any((item) => item.store.id == importedStore.id && item.localDbExists), isTrue);
    });

    test('importStoreFromBackup fails with ValidationError when file is empty',
        () async {
      final importRes = await notifier.importStoreFromBackup(
        fileBytes: [],
        fileName: 'empty_backup.db',
        userId: userId,
      );

      expect(importRes.isFailure, isTrue);
    });

    test('importStoreFromBackup rolls back on corrupt file and leaves store catalog clean',
        () async {
      final corruptBytes = List<int>.generate(1024, (i) => i % 256);

      final importRes = await notifier.importStoreFromBackup(
        fileBytes: corruptBytes,
        fileName: 'corrupt.db',
        userId: userId,
        storeName: 'Corrupt Store',
      );

      expect(importRes.isFailure, isTrue);
      final stores = await storeRepo.getAccessibleStores(userId);
      expect(stores.valueOrNull, isEmpty);
    });

    test('deleteStore permanently deletes database file, metadata, and updates store list',
        () async {
      // 1. Create store
      final createRes = await notifier.createStore(
        name: 'Store To Delete',
        userId: userId,
      );
      expect(createRes.isSuccess, isTrue);
      final store = createRes.valueOrNull!;

      final filePathRes = await dbManager.getDatabaseFilePath(store.id);
      final dbFile = File(filePathRes.valueOrNull!);
      expect(await dbFile.exists(), isTrue);

      expect(notifier.state.value!.length, 1);

      // 2. Delete store
      final deleteRes = await notifier.deleteStore(
        storeId: store.id,
        userId: userId,
      );
      expect(deleteRes.isSuccess, isTrue);

      // 3. Verify file deleted, metadata deleted, and state updated
      expect(await dbFile.exists(), isFalse);
      final stores = await storeRepo.getAccessibleStores(userId);
      expect(stores.valueOrNull, isEmpty);
      expect(notifier.state.value, isEmpty);
    });

    test('export and import preserves item catalog and records across stores',
        () async {
      // 1. Create source store
      final createRes = await notifier.createStore(
        name: 'Source Store with Items',
        userId: userId,
      );
      expect(createRes.isSuccess, isTrue);
      final sourceStore = createRes.valueOrNull!;

      // 2. Add an item into source store
      final sourceDbRes =
          await dbManager.getOrOpenStoreDatabase(sourceStore.id);
      expect(sourceDbRes.isSuccess, isTrue);
      final sourceDb = sourceDbRes.valueOrNull!;

      final itemRepo = DriftItemRepository(
        database: sourceDb,
        storeId: sourceStore.id,
      );

      final draftItem = Item(
        id: const ItemId('itm_rice_50kg'),
        storeId: sourceStore.id,
        name: 'Premium Parboiled Rice 50kg',
        sku: 'RICE-50KG',
        barcode: '123456789012',
        unit: ItemUnit.bag,
        pricing: ItemPricing(
          costPrice: 45000,
          baseSellingPrice: 52000,
          minSellingPrice: 48000,
        ),
        inventory: ItemInventory(
          quantity: 25,
          reorderLevel: 5,
        ),
        createdAt: DateTime.utc(2026, 9, 24),
        updatedAt: DateTime.utc(2026, 9, 24),
      );

      final saveItemRes = await itemRepo.create(draftItem);
      expect(saveItemRes.isSuccess, isTrue);

      // 3. Export source store database
      final exportService = StoreExportService(dbManager: dbManager);
      final exportRes =
          await exportService.exportStoreDatabase(sourceStore.id);
      expect(exportRes.isSuccess, isTrue);
      final exportPath = exportRes.valueOrNull!;
      final exportedBytes = await File(exportPath).readAsBytes();

      // 4. Import into new store
      final importRes = await notifier.importStoreFromBackup(
        fileBytes: exportedBytes,
        fileName: 'Tally_Source_Store_Backup.db',
        userId: userId,
        storeName: 'Restored Store with Items',
      );
      expect(importRes.isSuccess, isTrue);
      final restoredStore = importRes.valueOrNull!;

      // 5. Query items in restored store
      final restoredDbRes =
          await dbManager.getOrOpenStoreDatabase(restoredStore.id);
      expect(restoredDbRes.isSuccess, isTrue);
      final restoredDb = restoredDbRes.valueOrNull!;

      final restoredItemRepo = DriftItemRepository(
        database: restoredDb,
        storeId: restoredStore.id,
      );

      final queryRes = await restoredItemRepo.query(const ItemQuery());
      expect(queryRes.isSuccess, isTrue);
      final items = queryRes.valueOrNull!.items;

      // 6. Verify item exists and all properties match
      expect(items.length, 1);
      final importedItem = items.first;
      expect(importedItem.name, 'Premium Parboiled Rice 50kg');
      expect(importedItem.sku, 'RICE-50KG');
      expect(importedItem.barcode, '123456789012');
      expect(importedItem.pricing.costPrice, 45000);
      expect(importedItem.pricing.baseSellingPrice, 52000);
      expect(importedItem.inventory.quantity, 25);
    });
  });
}
