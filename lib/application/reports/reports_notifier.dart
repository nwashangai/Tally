import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/reports/reports_repository.dart';
import '../../domain/reports/sales_profit_report.dart';

enum ReportsDateRange {
  allTime,
  today,
  last7Days,
  last30Days,
  custom;

  String get label {
    switch (this) {
      case ReportsDateRange.allTime:
        return 'All Time';
      case ReportsDateRange.today:
        return 'Today';
      case ReportsDateRange.last7Days:
        return 'Last 7 Days';
      case ReportsDateRange.last30Days:
        return 'Last 30 Days';
      case ReportsDateRange.custom:
        return 'Custom';
    }
  }
}

class ReportsState extends Equatable {
  final bool isLoading;
  final ReportsDateRange dateRange;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final SalesProfitReport? report;
  final String? errorMessage;
  final String searchQuery;

  const ReportsState({
    this.isLoading = false,
    this.dateRange = ReportsDateRange.allTime,
    this.customStartDate,
    this.customEndDate,
    this.report,
    this.errorMessage,
    this.searchQuery = '',
  });

  List<ItemProfitReport> get filteredItemReports {
    if (report == null) return const [];
    if (searchQuery.trim().isEmpty) return report!.itemReports;

    final query = searchQuery.toLowerCase().trim();
    return report!.itemReports.where((item) {
      final nameMatches = item.itemName.toLowerCase().contains(query);
      final skuMatches =
          item.sku != null && item.sku!.toLowerCase().contains(query);
      return nameMatches || skuMatches;
    }).toList();
  }

  ReportsState copyWith({
    bool? isLoading,
    ReportsDateRange? dateRange,
    DateTime? customStartDate,
    DateTime? customEndDate,
    SalesProfitReport? report,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      dateRange: dateRange ?? this.dateRange,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        dateRange,
        customStartDate,
        customEndDate,
        report,
        errorMessage,
        searchQuery,
      ];
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository _repository;

  ReportsNotifier({
    required ReportsRepository repository,
  })  : _repository = repository,
        super(const ReportsState()) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final rangeDates = _calculateDateRange(state.dateRange);
    final startDate = rangeDates.$1;
    final endDate = rangeDates.$2;

    final result = await _repository.getSalesProfitReport(
      startDate: startDate,
      endDate: endDate,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        report: result.valueOrNull,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessageOrNull,
      );
    }
  }

  void setDateRange(ReportsDateRange range) {
    if (range == state.dateRange) return;
    state = state.copyWith(dateRange: range);
    loadReport();
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      dateRange: ReportsDateRange.custom,
      customStartDate: start,
      customEndDate: end,
    );
    loadReport();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  (DateTime?, DateTime?) _calculateDateRange(ReportsDateRange range) {
    final now = DateTime.now();
    switch (range) {
      case ReportsDateRange.allTime:
        return (null, null);
      case ReportsDateRange.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return (start, end);
      case ReportsDateRange.last7Days:
        final start = now.subtract(const Duration(days: 7));
        return (start, now);
      case ReportsDateRange.last30Days:
        final start = now.subtract(const Duration(days: 30));
        return (start, now);
      case ReportsDateRange.custom:
        return (state.customStartDate, state.customEndDate);
    }
  }
}
