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
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_repository.dart';
import 'package:tally/domain/store/remote_store_database_metadata.dart';
import 'package:tally/domain/store/remote_store_database_repository.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/presentation/items/item_form_screen.dart';

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

  testWidgets('ItemFormScreen validates required fields and pricing invariant',
      (tester) async {
    final fakeRepo = _FakeItemRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(fakeRepo),
          currentStoreProvider.overrideWith(
            (ref) => _FakeCurrentStoreNotifier(
              StoreSelected(store: sampleStore, dbPath: '/test/store-1.db'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ItemFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add New Item'), findsOneWidget);

    final saveButton = find.widgetWithText(ElevatedButton, 'Save Item');

    // Attempt submission with empty fields
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Item name is required.'), findsOneWidget);
    expect(find.text('Selling price is required.'), findsOneWidget);

    // Enter Item Name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Item Name *'),
      'Coca-Cola 50cl',
    );

    // Enter Base Selling Price = 250
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Base Selling Price (₦) *'),
      '250',
    );

    // Enter Minimum Selling Price = 300 (exceeds base -> invalid)
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Minimum Selling Price (₦ - Floor Price)',
      ),
      '300',
    );

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Cannot exceed base price (₦250.0).'), findsOneWidget);

    // Correct Minimum Selling Price to 240
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Minimum Selling Price (₦ - Floor Price)',
      ),
      '240',
    );

    // Enter Cost Price = 200
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cost Price (₦)'),
      '200',
    );

    // Enter Initial Stock = 42
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Initial On-Hand Stock *'),
      '42',
    );

    // Submit valid form
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(fakeRepo.createdItems.length, 1);
    final created = fakeRepo.createdItems.first;
    expect(created.name, 'Coca-Cola 50cl');
    expect(created.pricing.costPrice, 200);
    expect(created.pricing.baseSellingPrice, 250);
    expect(created.pricing.minSellingPrice, 240);
    expect(created.inventory.quantity, 42);
  });

  testWidgets('Barcode input contains scanner suffix icon button',
      (tester) async {
    final fakeRepo = _FakeItemRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(fakeRepo),
          currentStoreProvider.overrideWith(
            (ref) => _FakeCurrentStoreNotifier(
              StoreSelected(store: sampleStore, dbPath: '/test/store-1.db'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ItemFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify barcode field is present with scan suffix icon
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Barcode'), findsOneWidget);

    // Verify tapping scan icon does not crash
    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}

