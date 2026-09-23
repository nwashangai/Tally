import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/application/store/current_store_notifier.dart';
import 'package:tally/application/store/current_store_state.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_export.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_import.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_repository.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/remote_store_database_metadata.dart';
import 'package:tally/domain/store/remote_store_database_repository.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/item/item_importer.dart';
import 'package:tally/presentation/items/widgets/item_import_dialog.dart';

class _FakeItemRepository implements ItemRepository {
  final List<Item> createdItems = [];

  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async =>
      Success(PaginatedResult<Item>(
        items: createdItems,
        page: 1,
        pageSize: 25,
        totalItems: createdItems.length,
      ));

  @override
  Future<Result<Item>> getById(ItemId id) async =>
      Success(createdItems.firstWhere((i) => i.id == id));

  @override
  Future<Result<Item>> create(Item item) async {
    createdItems.add(item);
    return Success(item);
  }

  @override
  Future<Result<List<Item>>> bulkCreate(List<Item> items) async {
    createdItems.addAll(items);
    return Success(items);
  }

  @override
  Future<Result<Item>> update(Item item) async => Success(item);
  @override
  Future<Result<void>> archive(ItemId id) async => const Success(null);
  @override
  Future<Result<void>> activate(ItemId id) async => const Success(null);
  @override
  Future<Result<void>> delete(ItemId id) async => const Success(null);
  @override
  Future<Result<bool>> hasTransactions(ItemId id) async => const Success(false);
  @override
  Future<Result<List<String>>> getCategories() async => const Success([]);
  @override
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request) async =>
      Success(createdItems);
}

class _FakeItemImporter implements ItemImporter {
  _FakeItemImporter();

  @override
  Future<Result<ItemImportResult>> parse({
    required Uint8List bytes,
    required String fileName,
    required StoreId storeId,
  }) async {
    return Success(
      ItemImportResult(
        fileName: fileName,
        fileSizeBytes: bytes.length,
        totalRows: 2,
        validItems: [
          Item(
            id: const ItemId('imp-1'),
            storeId: storeId,
            name: 'Imported Tea',
            unit: ItemUnit.pack,
            pricing: ItemPricing(costPrice: 100, baseSellingPrice: 150),
            inventory: ItemInventory(quantity: 20),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        errors: const [
          ItemImportError(
            rowIndex: 3,
            fieldName: 'Name',
            rawValue: '',
            message: 'Item name is required.',
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<ExportedFile>> generateSampleTemplate(
    ItemExportFormat format,
  ) async {
    return Success(
      ExportedFile(
        fileName: 'sample_template.csv',
        bytes: Uint8List.fromList([1, 2, 3]),
        mimeType: 'text/csv',
        itemCount: 3,
        exportedAt: DateTime.now(),
      ),
    );
  }
}

class _FakeDbManager implements StoreDatabaseManager {
  @override
  Future<Result<void>> create(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> open(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> close(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> checkpoint(StoreId storeId) async => const Success(null);
  @override
  Future<Result<bool>> exists(StoreId storeId) async => const Success(true);
  @override
  Future<Result<String>> getDatabaseFilePath(StoreId storeId) async =>
      Success('/test/${storeId.value}.db');
  @override
  Future<Result<bool>> validateIntegrity(StoreId storeId) async =>
      const Success(true);
  @override
  Future<Result<void>> delete(StoreId storeId) async => const Success(null);
}

class _FakeRemoteDbRepo implements RemoteStoreDatabaseRepository {
  @override
  Future<Result<RemoteStoreDatabaseMetadata?>> getMetadata(
          StoreId storeId) async =>
      const Success(null);
  @override
  Future<Result<void>> upload({
    required StoreId storeId,
    required String localFilePath,
    required int revision,
  }) async =>
      const Success(null);
  @override
  Future<Result<void>> download({
    required StoreId storeId,
    required String destinationFilePath,
  }) async =>
      const Success(null);
}

class _FakeCurrentStoreNotifier extends CurrentStoreNotifier {
  _FakeCurrentStoreNotifier(CurrentStoreState initialState)
      : super(
          dbManager: _FakeDbManager(),
          remoteDbRepo: _FakeRemoteDbRepo(),
        ) {
    state = initialState;
  }
}

void main() {
  final sampleStore = Store(
    id: const StoreId('store-1'),
    name: 'Downtown Store',
    ownerId: 'user-1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets(
      'ItemImportDialog renders title, pick prompt, and sample templates',
      (tester) async {
    final fakeRepo = _FakeItemRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(fakeRepo),
          itemImporterProvider.overrideWithValue(_FakeItemImporter()),
          currentStoreProvider.overrideWith(
            (ref) => _FakeCurrentStoreNotifier(
              StoreSelected(store: sampleStore, dbPath: '/test/store-1.db'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ItemImportDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Import Items Catalog'), findsOneWidget);
    expect(find.text('Tap to select Excel or CSV file'), findsOneWidget);
    expect(find.text('Excel Template'), findsOneWidget);
    expect(find.text('CSV Template'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
