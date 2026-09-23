import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/database/store_database.dart';
import 'package:tally/infrastructure/item/drift_item_repository.dart';

void main() {
  late Directory tempDir;
  late StoreDatabase db;
  late DriftItemRepository repo;
  const storeId = StoreId('test-store-repo');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tally_item_repo_test_');
    final dbFile = File('${tempDir.path}/test_store.db');
    db = StoreDatabase(
      storeId: storeId,
      databaseFile: dbFile,
      encryptionKey: 'test-passphrase-repo',
    );
    await db.open();
    repo = DriftItemRepository(database: db, storeId: storeId);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Item createSampleItem({
    required String id,
    required String name,
    String? sku,
    String? barcode,
    String? category,
    double cost = 100,
    double base = 150,
    double? minPrice = 120,
    double qty = 10,
    double? reorder = 5,
    bool isActive = true,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: ItemId(id),
      storeId: storeId,
      name: name,
      sku: sku,
      barcode: barcode,
      categoryId: category,
      unit: ItemUnit.piece,
      pricing: ItemPricing(
        costPrice: cost,
        baseSellingPrice: base,
        minSellingPrice: minPrice,
      ),
      inventory: ItemInventory(quantity: qty, reorderLevel: reorder),
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('create, getById, and update item lifecycle', () async {
    final item = createSampleItem(
      id: 'coke-1',
      name: 'Coca-Cola 50cl',
      sku: 'COKE-50',
      category: 'Drinks',
    );

    final createResult = await repo.create(item);
    expect(createResult.isSuccess, isTrue);

    final fetchResult = await repo.getById(const ItemId('coke-1'));
    expect(fetchResult.isSuccess, isTrue);
    final fetched = fetchResult.valueOrNull!;
    expect(fetched.name, 'Coca-Cola 50cl');
    expect(fetched.pricing.baseSellingPrice, 150);

    // Update item
    final updated = fetched.copyWith(
      name: 'Coca-Cola 50cl Plastic Bottle',
      pricing: fetched.pricing.copyWith(baseSellingPrice: 180),
    );
    final updateResult = await repo.update(updated);
    expect(updateResult.isSuccess, isTrue);

    final refetched = (await repo.getById(const ItemId('coke-1'))).valueOrNull!;
    expect(refetched.name, 'Coca-Cola 50cl Plastic Bottle');
    expect(refetched.pricing.baseSellingPrice, 180);
  });

  test('search across name, sku, and barcode', () async {
    await repo.create(createSampleItem(
      id: 'item-1',
      name: 'Peak Milk 400g Tin',
      sku: 'PEAK-400',
      barcode: '111222333',
    ));
    await repo.create(createSampleItem(
      id: 'item-2',
      name: 'Milo 500g Refill',
      sku: 'MILO-500',
      barcode: '444555666',
    ));

    // Search by name
    final nameSearch = await repo.query(const ItemQuery(search: 'peak'));
    expect(nameSearch.valueOrNull!.items.length, 1);
    expect(nameSearch.valueOrNull!.items.first.name, 'Peak Milk 400g Tin');

    // Search by SKU
    final skuSearch = await repo.query(const ItemQuery(search: 'MILO-500'));
    expect(skuSearch.valueOrNull!.items.length, 1);
    expect(skuSearch.valueOrNull!.items.first.name, 'Milo 500g Refill');

    // Search by Barcode
    final barcodeSearch = await repo.query(const ItemQuery(search: '111222'));
    expect(barcodeSearch.valueOrNull!.items.length, 1);
    expect(barcodeSearch.valueOrNull!.items.first.name, 'Peak Milk 400g Tin');
  });

  test('filter by stock level and category', () async {
    await repo.create(createSampleItem(
      id: 'healthy-1',
      name: 'Rice 50kg',
      category: 'Grains',
      qty: 50,
      reorder: 10,
    ));
    await repo.create(createSampleItem(
      id: 'low-1',
      name: 'Beans 50kg',
      category: 'Grains',
      qty: 5,
      reorder: 10,
    ));
    await repo.create(createSampleItem(
      id: 'out-1',
      name: 'Sugar 1kg',
      category: 'Provisions',
      qty: 0,
      reorder: 10,
    ));

    // Filter low stock
    final lowQuery = await repo.query(const ItemQuery(
      filter: ItemFilter(stockFilter: StockFilter.lowStock),
    ));
    expect(lowQuery.valueOrNull!.items.length, 1);
    expect(lowQuery.valueOrNull!.items.first.name, 'Beans 50kg');

    // Filter out of stock
    final outQuery = await repo.query(const ItemQuery(
      filter: ItemFilter(stockFilter: StockFilter.outOfStock),
    ));
    expect(outQuery.valueOrNull!.items.length, 1);
    expect(outQuery.valueOrNull!.items.first.name, 'Sugar 1kg');

    // Filter category
    final grainsQuery = await repo.query(const ItemQuery(
      filter: ItemFilter(categoryId: 'Grains'),
    ));
    expect(grainsQuery.valueOrNull!.items.length, 2);
  });

  test('archive and reactivate items', () async {
    final item = createSampleItem(
      id: 'archive-test',
      name: 'Seasonal Drink',
    );
    await repo.create(item);

    // Archive
    final archiveRes = await repo.archive(const ItemId('archive-test'));
    expect(archiveRes.isSuccess, isTrue);

    // Default query (active only) should not include it
    final activeOnly = await repo.query(const ItemQuery());
    expect(activeOnly.valueOrNull!.items.isEmpty, isTrue);

    // Filter status archived
    final archivedOnly = await repo.query(const ItemQuery(
      filter: ItemFilter(statusFilter: StatusFilter.archived),
    ));
    expect(archivedOnly.valueOrNull!.items.length, 1);

    // Reactivate
    final activateRes = await repo.activate(const ItemId('archive-test'));
    expect(activateRes.isSuccess, isTrue);

    final reactivated = await repo.query(const ItemQuery());
    expect(reactivated.valueOrNull!.items.length, 1);
  });

  test('safe delete protects items with transaction history', () async {
    final item = createSampleItem(
      id: 'has-history-1',
      name: 'Historical Item',
    );
    await repo.create(item);

    // Insert historical transaction
    await db.executor.runInsert(
      '''
      INSERT INTO item_transactions (
        id, store_id, item_id, type, quantity_delta, unit_cost, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        'trans-1',
        storeId.value,
        'has-history-1',
        'receiving',
        100.0,
        150.0,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );

    // Attempt delete -> should fail per ADR 0012
    final deleteResult = await repo.delete(const ItemId('has-history-1'));
    expect(deleteResult.isFailure, isTrue);
    expect(
      deleteResult.errorMessageOrNull,
      contains('transaction history'),
    );

    // Item should still exist in database
    final stillExists = await repo.getById(const ItemId('has-history-1'));
    expect(stillExists.isSuccess, isTrue);
  });

  test('empty item without transactions can be permanently deleted', () async {
    final item = createSampleItem(
      id: 'no-history-1',
      name: 'Disposable Test Item',
    );
    await repo.create(item);

    final deleteResult = await repo.delete(const ItemId('no-history-1'));
    expect(deleteResult.isSuccess, isTrue);

    final fetchResult = await repo.getById(const ItemId('no-history-1'));
    expect(fetchResult.isFailure, isTrue);
  });

  test('bulkCreate inserts multiple items in a single transaction', () async {
    final items = [
      createSampleItem(
          id: 'bulk-1', name: 'Bulk Item 1', base: 150, minPrice: 120),
      createSampleItem(
          id: 'bulk-2', name: 'Bulk Item 2', base: 200, minPrice: 150),
      createSampleItem(
          id: 'bulk-3', name: 'Bulk Item 3', base: 300, minPrice: 250),
    ];

    final result = await repo.bulkCreate(items);
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.length, 3);

    final queryRes = await repo.query(const ItemQuery());
    expect(queryRes.isSuccess, isTrue);
    expect(queryRes.valueOrNull!.totalItems, 3);
  });
}
