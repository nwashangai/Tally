import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_export.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_repository.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/presentation/items/widgets/item_search_filter_bar.dart';

class _FakeItemRepository implements ItemRepository {
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
  Future<Result<void>> archive(ItemId id) => throw UnimplementedError();
  @override
  Future<Result<void>> activate(ItemId id) => throw UnimplementedError();
  @override
  Future<Result<void>> delete(ItemId id) => throw UnimplementedError();
  @override
  Future<Result<bool>> hasTransactions(ItemId id) async => const Success(false);
  @override
  Future<Result<List<String>>> getCategories() async => const Success([]);
  @override
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request) async =>
      const Success([]);
}

void main() {
  Widget buildWidget({required Size surfaceSize}) {
    return ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(_FakeItemRepository()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ItemSearchFilterBar(
                totalItems: 10,
                onAddItem: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'in mobile view, search takes up full width when focused and restores on cancel',
    (tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(surfaceSize: mobileSize));
      await tester.pumpAndSettle();

      // Initially on mobile: search bar and Filters button are present, Cancel button is not
      expect(find.byKey(const Key('item_search_field')), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.byKey(const Key('item_search_cancel_button')), findsNothing);

      // Initial search width before focus
      final initialSearchWidth =
          tester.getSize(find.byKey(const Key('item_search_field'))).width;

      // Focus the search field
      await tester.tap(find.byKey(const Key('item_search_field')));
      await tester.pumpAndSettle();

      // In focused mobile view: Cancel button appears and Filters button is hidden
      expect(
          find.byKey(const Key('item_search_cancel_button')), findsOneWidget);
      expect(find.text('Filters'), findsNothing);

      // Search bar width should now be significantly wider (taking up almost full available width)
      final focusedSearchWidth =
          tester.getSize(find.byKey(const Key('item_search_field'))).width;
      expect(focusedSearchWidth, greaterThan(initialSearchWidth));

      // Tap Cancel button
      await tester.tap(find.byKey(const Key('item_search_cancel_button')));
      await tester.pumpAndSettle();

      // Returns to unfocused state
      expect(find.byKey(const Key('item_search_cancel_button')), findsNothing);
      expect(find.text('Filters'), findsOneWidget);
    },
  );
}
