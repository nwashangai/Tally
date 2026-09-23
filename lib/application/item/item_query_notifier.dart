import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/item/item_query.dart';

/// Manages the current query criteria (search, filter, sort, pagination) for the items catalog.
class ItemQueryNotifier extends StateNotifier<ItemQuery> {
  ItemQueryNotifier({ItemQuery initialQuery = const ItemQuery()})
      : super(initialQuery);

  void setSearch(String search) {
    if (state.search == search) return;
    state = state.copyWith(search: search);
  }

  void setFilter(ItemFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
  }

  void updateFilter(ItemFilter Function(ItemFilter current) updater) {
    final newFilter = updater(state.filter);
    if (state.filter == newFilter) return;
    state = state.copyWith(filter: newFilter);
  }

  void clearFilter() {
    state = state.copyWith(filter: const ItemFilter());
  }

  void setSortField(ItemSortField field) {
    if (state.sort.field == field) {
      // Toggle sort order if same field
      final newOrder = state.sort.order == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending;
      state = state.copyWith(sort: ItemSort(field: field, order: newOrder));
    } else {
      // Default to ascending for newly selected field
      state = state.copyWith(
        sort: ItemSort(field: field, order: SortOrder.ascending),
      );
    }
  }

  void setSort(ItemSort sort) {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort);
  }

  void setPage(int page) {
    if (page < 1 || state.page == page) return;
    state = state.copyWith(page: page);
  }

  void nextPage() {
    state = state.copyWith(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) {
      state = state.copyWith(page: state.page - 1);
    }
  }

  void setPageSize(int pageSize) {
    if (pageSize <= 0 || state.pageSize == pageSize) return;
    state = state.copyWith(pageSize: pageSize, page: 1);
  }

  void reset() {
    state = const ItemQuery();
  }
}
