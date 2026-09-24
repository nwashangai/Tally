import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_export.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_repository.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/receiving/receiving.dart';
import 'package:tally/domain/receiving/receiving_id.dart';
import 'package:tally/domain/receiving/receiving_line.dart';
import 'package:tally/domain/receiving/receiving_line_history.dart';
import 'package:tally/domain/receiving/receiving_query.dart';
import 'package:tally/domain/receiving/receiving_repository.dart';
import 'package:tally/domain/receiving/receiving_status.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/presentation/receivings/new_receiving_screen.dart';

class _FakeReceivingRepository implements ReceivingRepository {
  final List<Receiving> receivings = [];

  @override
  Future<Result<String>> getNextReferenceNumber() async =>
      const Success('REC-000042');

  @override
  Future<Result<Receiving>> create(Receiving receiving) async {
    receivings.add(receiving);
    return Success(receiving);
  }

  @override
  Future<Result<Receiving>> complete(ReceivingId id) async =>
      Success(receivings.firstWhere((r) => r.id == id));

  @override
  Future<Result<Receiving?>> getById(ReceivingId id) async =>
      Success(receivings.where((r) => r.id == id).firstOrNull);

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 10,
  }) async =>
      const Success([]);

  @override
  Future<Result<PaginatedResult<Receiving>>> query(
          ReceivingQuery query) async =>
      Success(PaginatedResult<Receiving>(
        items: receivings,
        page: query.page,
        pageSize: query.pageSize,
        totalItems: receivings.length,
      ));

  @override
  Future<Result<Receiving>> voidReceiving(ReceivingId id,
          {String? reason}) async =>
      Success(receivings.firstWhere((r) => r.id == id));

  @override
  Future<Result<Receiving>> update(Receiving receiving) async {
    final idx = receivings.indexWhere((r) => r.id == receiving.id);
    if (idx != -1) {
      receivings[idx] = receiving;
    } else {
      receivings.add(receiving);
    }
    return Success(receiving);
  }

  @override
  Future<Result<void>> delete(ReceivingId id) async {
    receivings.removeWhere((r) => r.id == id);
    return const Success(null);
  }
}

class _FakeItemRepository implements ItemRepository {
  final List<Item> items;

  _FakeItemRepository(this.items);

  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async =>
      Success(PaginatedResult<Item>(
        items: items,
        page: query.page,
        pageSize: query.pageSize,
        totalItems: items.length,
      ));

  @override
  Future<Result<Item>> getById(ItemId id) async =>
      Success(items.firstWhere((i) => i.id == id));

  @override
  Future<Result<Item>> create(Item item) async => Success(item);
  @override
  Future<Result<List<Item>>> bulkCreate(List<Item> items) async =>
      Success(items);
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
      Success(items);
}

void main() {
  const storeId = StoreId('store-1');
  final testItem = Item(
    id: const ItemId('item-1'),
    storeId: storeId,
    name: 'Basmati Rice 5kg',
    sku: 'RICE-05',
    unit: ItemUnit.bottle,
    pricing: ItemPricing(costPrice: 6500, baseSellingPrice: 8500),
    inventory: ItemInventory(quantity: 15),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createSubject(
    ReceivingRepository recRepo,
    ItemRepository itemRepo,
  ) {
    return ProviderScope(
      overrides: [
        receivingRepositoryProvider.overrideWithValue(recRepo),
        itemRepositoryProvider.overrideWithValue(itemRepo),
      ],
      child: const MaterialApp(
        home: NewReceivingScreen(),
      ),
    );
  }

  testWidgets('renders form fields, action buttons, and empty items state',
      (tester) async {
    final recRepo = _FakeReceivingRepository();
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(createSubject(recRepo, itemRepo));
    await tester.pumpAndSettle();

    expect(find.text('New Receiving'), findsOneWidget);
    expect(find.text('Transaction Information'), findsOneWidget);
    expect(find.text('No products added yet'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Complete Receiving'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shows validation snackbar if completing with empty line items',
      (tester) async {
    final recRepo = _FakeReceivingRepository();
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(createSubject(recRepo, itemRepo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Complete Receiving'));
    await tester.pumpAndSettle();

    expect(find.text('Please add at least one line item.'), findsOneWidget);
  });

  testWidgets(
      'mobile screen footer displays metrics horizontally without overflow on 360dp phone',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final recRepo = _FakeReceivingRepository();
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(createSubject(recRepo, itemRepo));
    await tester.pumpAndSettle();

    // Verify horizontal metric summary strip is displayed cleanly
    expect(find.text('0 items'), findsOneWidget);
    expect(find.text('0 units'), findsOneWidget);
    expect(find.text('Total: '), findsOneWidget);

    // Verify all actions are present and accessible
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Draft'), findsOneWidget);
    expect(find.text('Complete Receiving'), findsOneWidget);

    // Verify no RenderFlex overflow occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'displays barcode scanning options in header, empty state, and picker dialog',
      (tester) async {
    final recRepo = _FakeReceivingRepository();
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(createSubject(recRepo, itemRepo));
    await tester.pumpAndSettle();

    // Verify Scan button in section header
    expect(find.text('Scan'), findsOneWidget);

    // Verify Scan Barcode button in empty state
    expect(find.text('Scan Barcode'), findsOneWidget);

    // Verify qr_code_scanner icons are present
    expect(find.byIcon(Icons.qr_code_scanner), findsAtLeastNWidgets(2));

    // Open Item Picker dialog
    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();

    // Verify scan barcode icon inside search picker dialog
    expect(find.byTooltip('Scan Barcode'), findsOneWidget);

    // Close dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('editing existing draft pre-fills data and allows updating',
      (tester) async {
    final draftReceiving = Receiving(
      id: const ReceivingId('draft-101'),
      storeId: const StoreId('store-1'),
      referenceNumber: 'REC-DRAFT-01',
      receivedAt: DateTime(2026, 9, 20),
      supplier: 'Cadbury Nigeria',
      notes: 'Draft note test',
      status: ReceivingStatus.draft,
      lines: [
        ReceivingLine(
          receivingId: const ReceivingId('draft-101'),
          itemId: const ItemId('item-1'),
          itemNameSnapshot: 'Maltina 330ml Can',
          unitSnapshot: 'can',
          quantity: 10,
          unitCost: 300,
        ),
      ],
    );

    final recRepo = _FakeReceivingRepository();
    recRepo.receivings.add(draftReceiving);
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receivingRepositoryProvider.overrideWithValue(recRepo),
          itemRepositoryProvider.overrideWithValue(itemRepo),
        ],
        child: MaterialApp(
          home: NewReceivingScreen(initialDraft: draftReceiving),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and prefilled fields
    expect(find.text('Edit Draft Receiving'), findsOneWidget);
    expect(find.text('REC-DRAFT-01'), findsOneWidget);
    expect(find.text('Cadbury Nigeria'), findsOneWidget);
    expect(find.text('Draft note test'), findsOneWidget);
    expect(find.text('Maltina 330ml Can'), findsOneWidget);

    // Verify delete draft button exists in AppBar
    expect(find.byTooltip('Delete Draft'), findsOneWidget);

    // Save Draft
    await tester.tap(find.text('Save Draft'));
    await tester.pumpAndSettle();

    expect(recRepo.receivings.length, 1);
    expect(recRepo.receivings.first.referenceNumber, 'REC-DRAFT-01');
  });

  testWidgets('deleting draft from AppBar removes draft', (tester) async {
    final draftReceiving = Receiving(
      id: const ReceivingId('draft-102'),
      storeId: const StoreId('store-1'),
      referenceNumber: 'REC-DRAFT-02',
      receivedAt: DateTime(2026, 9, 20),
      supplier: 'Cadbury Nigeria',
      status: ReceivingStatus.draft,
      lines: [
        ReceivingLine(
          receivingId: const ReceivingId('draft-102'),
          itemId: const ItemId('item-1'),
          itemNameSnapshot: 'Maltina 330ml Can',
          unitSnapshot: 'can',
          quantity: 5,
          unitCost: 300,
        ),
      ],
    );

    final recRepo = _FakeReceivingRepository();
    recRepo.receivings.add(draftReceiving);
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receivingRepositoryProvider.overrideWithValue(recRepo),
          itemRepositoryProvider.overrideWithValue(itemRepo),
        ],
        child: MaterialApp(
          home: NewReceivingScreen(initialDraft: draftReceiving),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete Draft'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Draft?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(recRepo.receivings.isEmpty, isTrue);
  });

  testWidgets(
      'adding item pre-fills current prices and defaults update catalog checkboxes to checked',
      (tester) async {
    final recRepo = _FakeReceivingRepository();
    final itemRepo = _FakeItemRepository([testItem]);

    await tester.pumpWidget(createSubject(recRepo, itemRepo));
    await tester.pumpAndSettle();

    // Open item picker dialog
    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();

    // Select the item from the dialog
    await tester.tap(find.text('Basmati Rice 5kg'));
    await tester.pumpAndSettle();

    // Verify item is added to line items
    expect(find.text('Basmati Rice 5kg'), findsOneWidget);

    // Verify unit cost is prefilled with item's costPrice (6500)
    expect(find.text('6500'), findsOneWidget);

    // Verify selling price is prefilled with item's baseSellingPrice (8500)
    expect(find.text('8500'), findsOneWidget);

    // Verify both checkboxes are present and checked by default
    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
    expect(checkboxes.length, 2);
    for (final cb in checkboxes) {
      expect(cb.value, isTrue);
    }
  });
}



