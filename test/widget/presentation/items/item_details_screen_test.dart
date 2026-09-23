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
import 'package:tally/presentation/items/item_details_screen.dart';

class _FakeItemRepository implements ItemRepository {
  bool archiveCalled = false;
  bool deleteCalled = false;

  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async =>
      const Success(PaginatedResult<Item>(
        items: [],
        page: 1,
        pageSize: 25,
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
  Future<Result<void>> archive(ItemId id) async {
    archiveCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> activate(ItemId id) async => const Success(null);

  @override
  Future<Result<void>> delete(ItemId id) async {
    deleteCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasTransactions(ItemId id) async => const Success(false);
  @override
  Future<Result<List<String>>> getCategories() async => const Success([]);
  @override
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request) async =>
      const Success([]);
}

void main() {
  final sampleItem = Item(
    id: const ItemId('test-item-123456789'),
    storeId: const StoreId('store-1'),
    name: 'Milo Refill 500g',
    sku: 'MIL-500',
    barcode: '7613035912301',
    categoryId: 'Beverages',
    unit: ItemUnit.pack,
    pricing: ItemPricing(
      costPrice: 2200,
      baseSellingPrice: 2600,
      minSellingPrice: 2500,
    ),
    inventory: ItemInventory(
      quantity: 25,
      reorderLevel: 10,
    ),
    isActive: true,
    createdAt: DateTime.utc(2026, 9, 20, 10, 30),
    updatedAt: DateTime.utc(2026, 9, 22, 14, 15),
  );

  Widget buildWidget({required Size surfaceSize}) {
    return ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(_FakeItemRepository()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: ItemDetailsScreen(item: sampleItem),
        ),
      ),
    );
  }

  testWidgets(
    'ItemDetailsScreen renders redesigned audit timestamps and danger zone card on mobile',
    (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(surfaceSize: mobileSize));
      await tester.pumpAndSettle();

      // Check item header info
      expect(find.text('Milo Refill 500g'), findsWidgets);

      // Scroll down to view audit & danger zone
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Check Record Audit card & timestamps
      expect(find.text('Record Audit'), findsOneWidget);
      expect(find.textContaining('ID: test-ite'), findsOneWidget);
      expect(find.text('Created on'), findsOneWidget);
      expect(find.text('Last updated'), findsOneWidget);

      // Check Danger Zone card
      expect(find.text('Item Removal & Danger Zone'), findsOneWidget);
      expect(
        find.byKey(const Key('item_details_delete_archive_button')),
        findsOneWidget,
      );

      // Tap Danger Zone action button opens confirm dialog
      final deleteBtn =
          find.byKey(const Key('item_details_delete_archive_button'));
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Delete or Archive'), findsOneWidget);
    },
  );

  testWidgets(
    'ItemDetailsScreen renders properly without overflow on tablet',
    (tester) async {
      const tabletSize = Size(800, 1024);
      tester.view.physicalSize = tabletSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(surfaceSize: tabletSize));
      await tester.pumpAndSettle();

      expect(find.text('Record Audit'), findsOneWidget);
      expect(find.text('Item Removal & Danger Zone'), findsOneWidget);
      expect(
        find.byKey(const Key('item_details_delete_archive_button')),
        findsOneWidget,
      );
    },
  );
}
