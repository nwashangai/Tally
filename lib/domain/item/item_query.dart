import 'item_unit.dart';

/// Stock filter categories for inventory queries.
enum StockFilter {
  all('All Stock'),
  inStock('In Stock'),
  lowStock('Low Stock'),
  outOfStock('Out of Stock');

  final String label;
  const StockFilter(this.label);
}

/// Item active/archived status filter.
enum StatusFilter {
  all('All Statuses'),
  active('Active Only'),
  archived('Archived Only');

  final String label;
  const StatusFilter(this.label);
}

/// Filter criteria for querying catalog items.
class ItemFilter {
  final String? categoryId;
  final StockFilter stockFilter;
  final StatusFilter statusFilter;
  final double? minCostPrice;
  final double? maxCostPrice;
  final double? minSellingPrice;
  final double? maxSellingPrice;
  final ItemUnit? unit;

  const ItemFilter({
    this.categoryId,
    this.stockFilter = StockFilter.all,
    this.statusFilter = StatusFilter.active,
    this.minCostPrice,
    this.maxCostPrice,
    this.minSellingPrice,
    this.maxSellingPrice,
    this.unit,
  });

  /// Counts the number of active constraints (excluding default active status).
  int get activeFilterCount {
    int count = 0;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (stockFilter != StockFilter.all) count++;
    if (statusFilter != StatusFilter.active) count++;
    if (minCostPrice != null || maxCostPrice != null) count++;
    if (minSellingPrice != null || maxSellingPrice != null) count++;
    if (unit != null) count++;
    return count;
  }

  bool get isEmpty => activeFilterCount == 0;

  ItemFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    StockFilter? stockFilter,
    StatusFilter? statusFilter,
    double? minCostPrice,
    bool clearMinCostPrice = false,
    double? maxCostPrice,
    bool clearMaxCostPrice = false,
    double? minSellingPrice,
    bool clearMinSellingPrice = false,
    double? maxSellingPrice,
    bool clearMaxSellingPrice = false,
    ItemUnit? unit,
    bool clearUnit = false,
  }) {
    return ItemFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      stockFilter: stockFilter ?? this.stockFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      minCostPrice:
          clearMinCostPrice ? null : (minCostPrice ?? this.minCostPrice),
      maxCostPrice:
          clearMaxCostPrice ? null : (maxCostPrice ?? this.maxCostPrice),
      minSellingPrice: clearMinSellingPrice
          ? null
          : (minSellingPrice ?? this.minSellingPrice),
      maxSellingPrice: clearMaxSellingPrice
          ? null
          : (maxSellingPrice ?? this.maxSellingPrice),
      unit: clearUnit ? null : (unit ?? this.unit),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemFilter &&
          categoryId == other.categoryId &&
          stockFilter == other.stockFilter &&
          statusFilter == other.statusFilter &&
          minCostPrice == other.minCostPrice &&
          maxCostPrice == other.maxCostPrice &&
          minSellingPrice == other.minSellingPrice &&
          maxSellingPrice == other.maxSellingPrice &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(
        categoryId,
        stockFilter,
        statusFilter,
        minCostPrice,
        maxCostPrice,
        minSellingPrice,
        maxSellingPrice,
        unit,
      );
}

/// Available sort fields for items catalog.
enum ItemSortField {
  name('Item Name', 'name'),
  quantity('Stock Quantity', 'quantity'),
  costPrice('Cost Price', 'cost_price'),
  baseSellingPrice('Selling Price', 'base_selling_price'),
  minSellingPrice('Minimum Price', 'min_selling_price'),
  createdAt('Created Date', 'created_at'),
  updatedAt('Last Updated', 'updated_at');

  final String label;
  final String dbColumn;
  const ItemSortField(this.label, this.dbColumn);
}

/// Sort direction.
enum SortOrder {
  ascending('Ascending'),
  descending('Descending');

  final String label;
  const SortOrder(this.label);
}

/// Structured sort directive.
class ItemSort {
  final ItemSortField field;
  final SortOrder order;

  const ItemSort({
    this.field = ItemSortField.name,
    this.order = SortOrder.ascending,
  });

  ItemSort copyWith({
    ItemSortField? field,
    SortOrder? order,
  }) {
    return ItemSort(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSort && field == other.field && order == other.order;

  @override
  int get hashCode => Object.hash(field, order);
}

/// Immutable specification for querying catalog items.
class ItemQuery {
  final String search;
  final ItemFilter filter;
  final ItemSort sort;
  final int page;
  final int pageSize;

  const ItemQuery({
    this.search = '',
    this.filter = const ItemFilter(),
    this.sort = const ItemSort(),
    this.page = 1,
    this.pageSize = 25,
  })  : assert(page >= 1, 'Page must be >= 1'),
        assert(pageSize > 0, 'PageSize must be > 0');

  /// Creates a copy with specified modifications.
  /// If [search], [filter], or [sort] are updated without explicitly specifying [page],
  /// [page] automatically resets to 1 to prevent orphaned pages.
  ItemQuery copyWith({
    String? search,
    ItemFilter? filter,
    ItemSort? sort,
    int? page,
    int? pageSize,
  }) {
    final searchChanged = search != null && search != this.search;
    final filterChanged = filter != null && filter != this.filter;
    final sortChanged = sort != null && sort != this.sort;
    final shouldResetPage =
        (searchChanged || filterChanged || sortChanged) && page == null;

    return ItemQuery(
      search: search ?? this.search,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
      page: shouldResetPage ? 1 : (page ?? this.page),
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemQuery &&
          search == other.search &&
          filter == other.filter &&
          sort == other.sort &&
          page == other.page &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(search, filter, sort, page, pageSize);
}

/// Generic container for paginated query responses.
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
  });

  int get totalPages =>
      totalItems == 0 ? 1 : ((totalItems + pageSize - 1) ~/ pageSize);

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  int get startIndex => totalItems == 0 ? 0 : (page - 1) * pageSize + 1;
  int get endIndex {
    final rawEnd = page * pageSize;
    return rawEnd > totalItems ? totalItems : rawEnd;
  }
}
