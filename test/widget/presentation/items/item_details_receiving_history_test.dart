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
import 'package:tally/domain/receiving/receiving_line_history.dart';
import 'package:tally/domain/receiving/receiving_query.dart';
import 'package:tally/domain/receiving/receiving_repository.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/presentation/items/item_details_screen.dart';

class _FakeReceivingRepository implements ReceivingRepository {
  final List<ReceivingLineHistory> history;

  _FakeReceivingRepository(this.history);

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 50,
  }) async =>
      Success(history);

  @override
  Future<Result<String>> getNextReferenceNumber() async =>
      const Success('REC-000001');

  @override
  Future<Result<Receiving>> create(Receiving receiving) =>
      throw UnimplementedError();

  @override
  Future<Result<Receiving>> complete(ReceivingId id) =>
      throw UnimplementedError();

  @override
  Future<Result<Receiving?>> getById(ReceivingId id) =>
      throw UnimplementedError();

  @override
  Future<Result<PaginatedResult<Receiving>>> query(ReceivingQuery query) =>
      throw UnimplementedError();

  @override
  Future<Result<Receiving>> voidReceiving(ReceivingId id, {String? reason}) =>
      throw UnimplementedError();
}

class _FakeItemRepo implements ItemRepository {
  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async =>
      const Success(PaginatedResult<Item>(
        items: [],
        page: 1,
        pageSize: 20,
        totalItems: 0,
      ));

  @override
  Future<Result<Item>> getById(ItemId id) => throw UnimplementedError();
  @override
  Future<Result<Item>> create(Item item) => throw UnimplementedError();
  @override
  Future<Result<List<Item>>> bulkCreate(List<Item> items) =>
      throw UnimplementedError();
  @override
  Future<Result<Item>> update(Item item) => throw UnimplementedError();
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
      const Success([]);
}

void main() {
  const storeId = StoreId('store-1');
  const itemId = ItemId('item-oil-1l');

  final sampleItem = Item(
    id: itemId,
    storeId: storeId,
    name: 'Vegetable Oil 1L',
    sku: 'OIL-1L',
    unit: ItemUnit.bottle,
    // Current catalog cost price is 1500, but past acquisitions had different historical costs!
    pricing: ItemPricing(costPrice: 1500, baseSellingPrice: 1900),
    inventory: ItemInventory(quantity: 40),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleHistory = [
    ReceivingLineHistory(
      receivingId: const ReceivingId('rec-past-1'),
      referenceNumber: 'REC-000010',
      receivedAt: DateTime(2026, 8, 15, 11, 0),
      supplier: 'Grand Cereals Ltd',
      quantity: 20,
      unitCost: 1200, // Historical cost when purchased in August
      lineTotal: 24000,
      unitSnapshot: 'bottle',
    ),
    ReceivingLineHistory(
      receivingId: const ReceivingId('rec-past-2'),
      referenceNumber: 'REC-000025',
      receivedAt: DateTime(2026, 9, 10, 14, 30),
      supplier: 'Grand Cereals Ltd',
      quantity: 20,
      unitCost: 1450, // Historical cost when purchased in September
      lineTotal: 29000,
      unitSnapshot: 'bottle',
    ),
  ];

  testWidgets(
      'ItemDetailsScreen displays inbound receiving history table with historical acquisition costs',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final recRepo = _FakeReceivingRepository(sampleHistory);
    final itemRepo = _FakeItemRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receivingRepositoryProvider.overrideWithValue(recRepo),
          itemRepositoryProvider.overrideWithValue(itemRepo),
        ],
        child: MaterialApp(
          home: ItemDetailsScreen(item: sampleItem),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Receiving History section
    expect(find.text('Receiving History'), findsOneWidget);
    expect(find.text('Inbound Stock'), findsOneWidget);

    // Verify historical acquisition records are preserved
    expect(find.text('REC-000010'), findsOneWidget);
    expect(find.text('REC-000025'), findsOneWidget);
    expect(find.text('₦1200'), findsOneWidget);
    expect(find.text('₦1450'), findsOneWidget);
    expect(find.text('+20 bottle'), findsNWidgets(2));
  });
}
