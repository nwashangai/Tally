import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item_query.dart';

void main() {
  group('ItemFilter', () {
    test('activeFilterCount computes correctly', () {
      const defaultFilter = ItemFilter();
      expect(defaultFilter.activeFilterCount, 0);
      expect(defaultFilter.isEmpty, isTrue);

      final withCategory = defaultFilter.copyWith(categoryId: 'Drinks');
      expect(withCategory.activeFilterCount, 1);
      expect(withCategory.isEmpty, isFalse);

      final withStock =
          withCategory.copyWith(stockFilter: StockFilter.lowStock);
      expect(withStock.activeFilterCount, 2);

      final withPrice = withStock.copyWith(minSellingPrice: 500);
      expect(withPrice.activeFilterCount, 3);
    });
  });

  group('ItemQuery', () {
    test('resets page to 1 on search, filter, or sort modification', () {
      const query = ItemQuery(page: 5, pageSize: 25);

      // Search change resets page
      final searchUpdated = query.copyWith(search: 'coke');
      expect(searchUpdated.page, 1);
      expect(searchUpdated.search, 'coke');

      // Filter change resets page
      final filterUpdated = query.copyWith(
          filter: const ItemFilter(stockFilter: StockFilter.lowStock));
      expect(filterUpdated.page, 1);

      // Sort change resets page
      final sortUpdated = query.copyWith(
        sort: const ItemSort(field: ItemSortField.costPrice),
      );
      expect(sortUpdated.page, 1);

      // Explicit page modification preserves specified page
      final pageExplicit = query.copyWith(page: 3);
      expect(pageExplicit.page, 3);
    });
  });

  group('PaginatedResult', () {
    test('computes totalPages, bounds, and navigation flags accurately', () {
      final result = PaginatedResult<int>(
        items: List.generate(25, (i) => i),
        page: 1,
        pageSize: 25,
        totalItems: 55,
      );

      expect(result.totalPages, 3);
      expect(result.hasNextPage, isTrue);
      expect(result.hasPreviousPage, isFalse);
      expect(result.startIndex, 1);
      expect(result.endIndex, 25);

      final lastPage = PaginatedResult<int>(
        items: List.generate(5, (i) => i),
        page: 3,
        pageSize: 25,
        totalItems: 55,
      );

      expect(lastPage.hasNextPage, isFalse);
      expect(lastPage.hasPreviousPage, isTrue);
      expect(lastPage.startIndex, 51);
      expect(lastPage.endIndex, 55);
    });
  });
}
