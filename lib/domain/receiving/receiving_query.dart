import 'package:equatable/equatable.dart';
import 'receiving_status.dart';

enum ReceivingSortField {
  receivedAt('received_at', 'Date Received'),
  reference('reference_number', 'Reference Number'),
  totalCost('total_cost', 'Total Cost');

  final String dbColumn;
  final String label;

  const ReceivingSortField(this.dbColumn, this.label);
}

enum ReceivingSortDirection {
  ascending('ASC'),
  descending('DESC');

  final String sql;

  const ReceivingSortDirection(this.sql);

  bool get isAscending => this == ReceivingSortDirection.ascending;
  bool get isDescending => this == ReceivingSortDirection.descending;
}

/// Query and filter parameters for listing receivings with server-side pagination.
class ReceivingQuery extends Equatable {
  final String search;
  final ReceivingStatus? status;
  final String? supplier;
  final DateTime? startDate;
  final DateTime? endDate;
  final ReceivingSortField sortBy;
  final ReceivingSortDirection sortDirection;
  final int page;
  final int pageSize;

  const ReceivingQuery({
    this.search = '',
    this.status,
    this.supplier,
    this.startDate,
    this.endDate,
    this.sortBy = ReceivingSortField.receivedAt,
    this.sortDirection = ReceivingSortDirection.descending,
    this.page = 1,
    this.pageSize = 20,
  }) : assert(page >= 1, 'Page must be 1 or greater');

  ReceivingQuery copyWith({
    String? search,
    ReceivingStatus? status,
    bool clearStatus = false,
    String? supplier,
    bool clearSupplier = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    ReceivingSortField? sortBy,
    ReceivingSortDirection? sortDirection,
    int? page,
    int? pageSize,
  }) {
    return ReceivingQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      supplier: clearSupplier ? null : (supplier ?? this.supplier),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  int get offset => (page - 1) * pageSize;

  int get activeFilterCount {
    int count = 0;
    if (status != null) count++;
    if (supplier != null && supplier!.trim().isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        search,
        status,
        supplier,
        startDate,
        endDate,
        sortBy,
        sortDirection,
        page,
        pageSize,
      ];
}
