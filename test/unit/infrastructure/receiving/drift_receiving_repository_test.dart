import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/receiving/receiving.dart';
import 'package:tally/domain/receiving/receiving_id.dart';
import 'package:tally/domain/receiving/receiving_line.dart';
import 'package:tally/domain/receiving/receiving_query.dart';
import 'package:tally/domain/receiving/receiving_status.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/database/store_database.dart';
import 'package:tally/infrastructure/item/drift_item_repository.dart';
import 'package:tally/infrastructure/receiving/drift_receiving_repository.dart';

void main() {
  late Directory tempDir;
  late StoreDatabase db;
  late DriftItemRepository itemRepo;
  late DriftReceivingRepository receivingRepo;
  const storeId = StoreId('store-receiving-test');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tally_rec_repo_test_');
    final dbFile = File('${tempDir.path}/test_store.db');
    db = StoreDatabase(
      storeId: storeId,
      databaseFile: dbFile,
      encryptionKey: 'test-passphrase-rec',
    );
    await db.open();
    itemRepo = DriftItemRepository(database: db, storeId: storeId);
    receivingRepo = DriftReceivingRepository(database: db, storeId: storeId);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Item createTestItem({
    required String id,
    required String name,
    double cost = 200,
    double base = 250,
    double qty = 48,
  }) {
    final now = DateTime.now().toUtc();
    return Item(
      id: ItemId(id),
      storeId: storeId,
      name: name,
      sku: 'SKU-$id',
      unit: ItemUnit.bottle,
      pricing: ItemPricing(
        costPrice: cost,
        baseSellingPrice: base,
      ),
      inventory: ItemInventory(
        quantity: qty,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DriftReceivingRepository Tests', () {
    test('generates sequential reference numbers safely', () async {
      final ref1 = await receivingRepo.getNextReferenceNumber();
      expect(ref1.valueOrNull, 'REC-000001');

      final rec1 = Receiving(
        storeId: storeId,
        referenceNumber: 'REC-000001',
        supplier: 'ABC Supplier',
      );
      await receivingRepo.create(rec1);

      final ref2 = await receivingRepo.getNextReferenceNumber();
      expect(ref2.valueOrNull, 'REC-000002');
    });

    test('creates and retrieves a draft receiving with lines', () async {
      final item = createTestItem(id: 'coke', name: 'Coca-Cola 50cl');
      await itemRepo.create(item);

      const recId = ReceivingId('rec-test-1');
      final line1 = ReceivingLine(
        receivingId: recId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        skuSnapshot: item.sku,
        unitSnapshot: item.unit.value,
        quantity: 24,
        unitCost: 200.0,
      );

      final receiving = Receiving(
        id: recId,
        storeId: storeId,
        referenceNumber: 'REC-000100',
        supplier: 'Coca-Cola Bottling',
        notes: 'Delivery notes',
        lines: [line1],
      );

      final createRes = await receivingRepo.create(receiving);
      expect(createRes.isSuccess, isTrue);

      final fetchRes = await receivingRepo.getById(recId);
      expect(fetchRes.isSuccess, isTrue);
      final fetched = fetchRes.valueOrNull!;
      expect(fetched.referenceNumber, 'REC-000100');
      expect(fetched.supplier, 'Coca-Cola Bottling');
      expect(fetched.totalCost, 4800.0);
      expect(fetched.lines.length, 1);
      expect(fetched.lines.first.quantity, 24);
      expect(fetched.lines.first.unitCost, 200.0);
    });

    test(
        'completes receiving: updates inventory, records stock movement, preserves snapshot',
        () async {
      // 1. Initial State: Coca-Cola quantity = 48, cost = 200, selling = 250
      final item = createTestItem(
        id: 'coke-1',
        name: 'Coca-Cola 50cl',
        qty: 48,
        cost: 200,
        base: 250,
      );
      await itemRepo.create(item);

      const recId = ReceivingId('rec-complete-1');
      final line = ReceivingLine(
        receivingId: recId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        skuSnapshot: item.sku,
        unitSnapshot: item.unit.value,
        quantity: 24,
        unitCost: 215.0, // New acquisition cost
        updateItemCost: false, // Do not update catalog cost
      );

      final receiving = Receiving(
        id: recId,
        storeId: storeId,
        referenceNumber: 'REC-000101',
        status: ReceivingStatus.draft,
        lines: [line],
      );
      await receivingRepo.create(receiving);

      // 2. Complete the receiving
      final completeRes = await receivingRepo.complete(recId);
      expect(completeRes.isSuccess, isTrue);
      final completed = completeRes.valueOrNull!;
      expect(completed.isCompleted, isTrue);

      // 3. Verify Item stock increased from 48 -> 72
      final updatedItemRes = await itemRepo.getById(item.id);
      final updatedItem = updatedItemRes.valueOrNull!;
      expect(updatedItem.inventory.quantity, 72.0);

      // Cost price remained 200 because updateItemCost was false
      expect(updatedItem.pricing.costPrice, 200.0);
      // Selling price remained completely unchanged
      expect(updatedItem.pricing.baseSellingPrice, 250.0);

      // 4. Verify Stock Movement in item_transactions
      final txRows = await db.executor.runSelect(
        'SELECT * FROM item_transactions WHERE reference_id = ?;',
        [recId.value],
      );
      expect(txRows.length, 1);
      expect(txRows.first['type'], 'RECEIVING');
      expect(txRows.first['quantity_delta'], 24.0);
      expect(txRows.first['unit_cost'], 215.0);
      expect(txRows.first['item_id'], item.id.value);

      // 5. Verify Historical Receiving Snapshot in getItemReceivingHistory
      final historyRes = await receivingRepo.getItemReceivingHistory(item.id);
      expect(historyRes.isSuccess, isTrue);
      final history = historyRes.valueOrNull!;
      expect(history.length, 1);
      expect(history.first.referenceNumber, 'REC-000101');
      expect(history.first.quantity, 24.0);
      expect(history.first.unitCost, 215.0);

      // 6. Mutate Item cost in catalog later -> history must remain 215!
      await itemRepo.update(
        updatedItem.copyWith(
          pricing: updatedItem.pricing.copyWith(
            costPrice: 240.0,
            baseSellingPrice: 300.0,
          ),
        ),
      );

      final historyAfterEdit =
          await receivingRepo.getItemReceivingHistory(item.id);
      expect(historyAfterEdit.valueOrNull!.first.unitCost, 215.0);
    });

    test('updates item catalog cost_price when updateItemCost is true',
        () async {
      final item = createTestItem(
        id: 'peak-milk',
        name: 'Peak Milk 160g',
        qty: 10,
        cost: 320,
        base: 400,
      );
      await itemRepo.create(item);

      const recId = ReceivingId('rec-cost-update');
      final line = ReceivingLine(
        receivingId: recId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        unitSnapshot: 'can',
        quantity: 15,
        unitCost: 350.0,
        updateItemCost: true, // User opt-in to update catalog cost
      );

      final receiving = Receiving(
        id: recId,
        storeId: storeId,
        referenceNumber: 'REC-000102',
        lines: [line],
      );
      await receivingRepo.create(receiving);
      await receivingRepo.complete(recId);

      final updatedItem = (await itemRepo.getById(item.id)).valueOrNull!;
      expect(updatedItem.inventory.quantity, 25.0); // 10 + 15
      expect(updatedItem.pricing.costPrice, 350.0); // Updated to 350
      expect(updatedItem.pricing.baseSellingPrice, 400.0); // Untouched
    });

    test(
        'updates item catalog base_selling_price and min_selling_price when updateItemPrice is true',
        () async {
      final item = createTestItem(
        id: 'malt-drink',
        name: 'Malt Drink 33cl',
        qty: 20,
        cost: 250,
        base: 300,
      );
      await itemRepo.create(item);

      const recId = ReceivingId('rec-price-update');
      final line = ReceivingLine(
        receivingId: recId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        unitSnapshot: 'can',
        quantity: 10,
        unitCost: 280.0,
        updateItemCost: true,
        newBaseSellingPrice: 380.0,
        newMinSellingPrice: 340.0,
        updateItemPrice: true,
      );

      final receiving = Receiving(
        id: recId,
        storeId: storeId,
        referenceNumber: 'REC-000199',
        lines: [line],
      );
      await receivingRepo.create(receiving);
      await receivingRepo.complete(recId);

      final updatedItem = (await itemRepo.getById(item.id)).valueOrNull!;
      expect(updatedItem.inventory.quantity, 30.0);
      expect(updatedItem.pricing.costPrice, 280.0);
      expect(updatedItem.pricing.baseSellingPrice, 380.0);
      expect(updatedItem.pricing.minSellingPrice, 340.0);

      // Verify item_transactions recorded both unit_cost and unit_price
      final txRows = await db.executor.runSelect(
        'SELECT * FROM item_transactions WHERE reference_id = ?;',
        [recId.value],
      );
      expect(txRows.length, 1);
      expect(txRows.first['unit_cost'], 280.0);
      expect(txRows.first['unit_price'], 380.0);
    });

    test('enforces idempotency on complete(): does not double inventory',
        () async {
      final item = createTestItem(
        id: 'milo',
        name: 'Milo 500g',
        qty: 20,
      );
      await itemRepo.create(item);

      const recId = ReceivingId('rec-idempotent');
      final line = ReceivingLine(
        receivingId: recId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        unitSnapshot: 'pack',
        quantity: 10,
        unitCost: 2000.0,
      );

      final receiving = Receiving(
        id: recId,
        storeId: storeId,
        referenceNumber: 'REC-000103',
        lines: [line],
      );
      await receivingRepo.create(receiving);

      // First completion
      await receivingRepo.complete(recId);
      final itemAfterFirst = (await itemRepo.getById(item.id)).valueOrNull!;
      expect(itemAfterFirst.inventory.quantity, 30.0);

      // Second completion (e.g. network retry / duplicate click)
      final secondRes = await receivingRepo.complete(recId);
      expect(secondRes.isSuccess, isTrue);

      final itemAfterSecond = (await itemRepo.getById(item.id)).valueOrNull!;
      expect(itemAfterSecond.inventory.quantity, 30.0); // NOT 40.0!

      // Transactions count must still be 1
      final txRows = await db.executor.runSelect(
        'SELECT * FROM item_transactions WHERE reference_id = ?;',
        [recId.value],
      );
      expect(txRows.length, 1);
    });

    test('voidReceiving() creates reversal stock movement and reverts stock',
        () async {
      final item = createTestItem(
        id: 'malt',
        name: 'Malta Guinness',
        qty: 50,
      );
      await itemRepo.create(item);

      const recId = ReceivingId('rec-void-test');
      final line = ReceivingLine(
        receivingId: recId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        unitSnapshot: 'can',
        quantity: 20,
        unitCost: 250.0,
      );

      final receiving = Receiving(
        id: recId,
        storeId: storeId,
        referenceNumber: 'REC-000104',
        lines: [line],
      );
      await receivingRepo.create(receiving);
      await receivingRepo.complete(recId);

      // Stock is now 70
      expect((await itemRepo.getById(item.id)).valueOrNull!.inventory.quantity,
          70.0);

      // Void the receiving
      final voidRes = await receivingRepo.voidReceiving(
        recId,
        reason: 'Damaged shipment returned to supplier',
      );
      expect(voidRes.isSuccess, isTrue);
      expect(voidRes.valueOrNull!.isVoided, isTrue);

      // Stock reverted to 50
      final revertedItem = (await itemRepo.getById(item.id)).valueOrNull!;
      expect(revertedItem.inventory.quantity, 50.0);

      // Verify Compensating Reversal Movement in item_transactions
      final txRows = await db.executor.runSelect(
        'SELECT * FROM item_transactions WHERE reference_id = ? ORDER BY rowid ASC;',
        [recId.value],
      );
      expect(txRows.length, 2);
      expect(txRows[0]['type'], 'RECEIVING');
      expect(txRows[0]['quantity_delta'], 20.0);
      expect(txRows[1]['type'], 'RECEIVING_VOID');
      expect(txRows[1]['quantity_delta'], -20.0);
    });

    test('query() supports pagination, search, status, and supplier filtering',
        () async {
      final item = createTestItem(id: 'query-item', name: 'Query Item');
      await itemRepo.create(item);

      final r1 = Receiving(
        id: const ReceivingId('rec-q1'),
        storeId: storeId,
        referenceNumber: 'REC-000010',
        supplier: 'Nestle Nigeria',
        status: ReceivingStatus.completed,
        totalCost: 15000,
        lines: [
          ReceivingLine(
            receivingId: const ReceivingId('rec-q1'),
            itemId: item.id,
            itemNameSnapshot: item.name,
            unitSnapshot: 'bottle',
            quantity: 10,
            unitCost: 1500,
          ),
        ],
      );
      final r2 = Receiving(
        storeId: storeId,
        referenceNumber: 'REC-000011',
        supplier: 'Unilever Dist',
        status: ReceivingStatus.draft,
        totalCost: 8000,
        lines: const [],
      );
      await receivingRepo.create(r1);
      await receivingRepo.create(r2);

      // Filter by supplier
      final res1 = await receivingRepo
          .query(const ReceivingQuery(supplier: 'Nestle Nigeria'));
      expect(res1.valueOrNull!.items.length, 1);
      expect(res1.valueOrNull!.items.first.referenceNumber, 'REC-000010');

      // Filter by status
      final res2 = await receivingRepo
          .query(const ReceivingQuery(status: ReceivingStatus.draft));
      expect(res2.valueOrNull!.items.length, 1);
      expect(res2.valueOrNull!.items.first.referenceNumber, 'REC-000011');

      // Search
      final res3 =
          await receivingRepo.query(const ReceivingQuery(search: 'Unilever'));
      expect(res3.valueOrNull!.items.length, 1);
    });
  });
}
