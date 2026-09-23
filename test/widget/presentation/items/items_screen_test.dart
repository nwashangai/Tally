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
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/presentation/items/items_screen.dart';
import 'package:tally/presentation/items/widgets/item_desktop_table.dart';
import 'package:tally/presentation/items/widgets/item_mobile_card.dart';

class _FakeItemRepository implements ItemRepository {
  final List<Item> _items;

  _FakeItemRepository(this._items);

  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async {
    return Success(PaginatedResult<Item>(
      items: _items,
      page: query.page,
      pageSize: query.pageSize,
      totalItems: _items.length,
    ));
  }

  @override
  Future<Result<Item>> getById(ItemId id) async {
    final item = _items.firstWhere((i) => i.id == id);
    return Success(item);
  }

  @override
  Future<Result<Item>> create(Item item) async {
    _items.add(item);
    return Success(item);
  }

  @override
  Future<Result<List<Item>>> bulkCreate(List<Item> items) async {
    _items.addAll(items);
    return Success(items);
  }

  @override
  Future<Result<Item>> update(Item item) async {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) _items[idx] = item;
    return Success(item);
  }

  @override
  Future<Result<void>> archive(ItemId id) async => const Success(null);
  @override
  Future<Result<void>> activate(ItemId id) async => const Success(null);
  @override
  Future<Result<void>> delete(ItemId id) async => const Success(null);
  @override
  Future<Result<bool>> hasTransactions(ItemId id) async => const Success(false);
  @override
  Future<Result<List<String>>> getCategories() async =>
      Success(_items.map((i) => i.categoryId ?? '').toSet().toList());
  @override
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request) async =>
      Success(_items);
}

void main() {
  final sampleItems = [
    Item(
      id: const ItemId('item-1'),
      storeId: const StoreId('store-1'),
      name: 'Coca-Cola 50cl',
      sku: 'COKE-50',
      categoryId: 'Drinks',
      unit: ItemUnit.bottle,
      pricing: ItemPricing(
        costPrice: 200,
        baseSellingPrice: 250,
        minSellingPrice: 240,
      ),
      inventory: ItemInventory(quantity: 42, reorderLevel: 10),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Item(
      id: const ItemId('item-2'),
      storeId: const StoreId('store-1'),
      name: 'Peak Milk 400g',
      sku: 'PEAK-400',
      categoryId: 'Provisions',
      unit: ItemUnit.can,
      pricing: ItemPricing(
        costPrice: 1500,
        baseSellingPrice: 1800,
      ),
      inventory: ItemInventory(quantity: 5, reorderLevel: 10), // Low stock
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  testWidgets('ItemsScreen renders empty state when catalog has no items',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(_FakeItemRepository([])),
        ],
        child: const MaterialApp(
          home: ItemsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Items Catalog'), findsOneWidget);
    expect(find.text('No items yet'), findsOneWidget);
    expect(find.text('Add First Item'), findsOneWidget);
  });

  testWidgets('ItemsScreen renders desktop data table on desktop viewport',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider
              .overrideWithValue(_FakeItemRepository(sampleItems)),
        ],
        child: const MaterialApp(
          home: ItemsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ItemDesktopTable), findsOneWidget);
    expect(find.text('Coca-Cola 50cl'), findsOneWidget);
    expect(find.text('Peak Milk 400g'), findsOneWidget);
    expect(find.text('Showing 1–2 of 2 items'), findsOneWidget);
  });

  testWidgets('ItemsScreen renders mobile cards on mobile viewport',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider
              .overrideWithValue(_FakeItemRepository(sampleItems)),
        ],
        child: const MaterialApp(
          home: ItemsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ItemMobileCard), findsNWidgets(2));
    expect(find.text('Coca-Cola 50cl'), findsOneWidget);
    expect(find.text('Peak Milk 400g'), findsOneWidget);
  });
}
