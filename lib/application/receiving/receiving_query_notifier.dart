import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/receiving/receiving_query.dart';
import '../../domain/receiving/receiving_status.dart';

/// Manages the current query criteria (search, status filter, date range, sort, pagination)
/// for the receivings list.
class ReceivingQueryNotifier extends StateNotifier<ReceivingQuery> {
  ReceivingQueryNotifier({ReceivingQuery initialQuery = const ReceivingQuery()})
      : super(initialQuery);

  void setSearch(String? search) {
    final value = search?.trim() ?? '';
    if (state.search == value) return;
    state = state.copyWith(search: value, page: 1);
  }

  void setStatus(ReceivingStatus? status) {
    if (state.status == status) return;
    if (status == null) {
      state = state.copyWith(clearStatus: true, page: 1);
    } else {
      state = state.copyWith(status: status, page: 1);
    }
  }

  void setSupplier(String? supplier) {
    final trimmed = supplier?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      state = state.copyWith(clearSupplier: true, page: 1);
    } else {
      state = state.copyWith(supplier: trimmed, page: 1);
    }
  }

  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    state = state.copyWith(
      startDate: startDate,
      clearStartDate: startDate == null,
      endDate: endDate,
      clearEndDate: endDate == null,
      page: 1,
    );
  }

  void clearFilters() {
    state = const ReceivingQuery();
  }

  void setSortField(ReceivingSortField field) {
    if (state.sortBy == field) {
      final newDir = state.sortDirection == ReceivingSortDirection.ascending
          ? ReceivingSortDirection.descending
          : ReceivingSortDirection.ascending;
      state = state.copyWith(sortDirection: newDir);
    } else {
      state = state.copyWith(
        sortBy: field,
        sortDirection: ReceivingSortDirection.descending,
      );
    }
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
}
