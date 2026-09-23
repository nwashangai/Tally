import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_export.dart';
import '../../domain/item/item_id.dart';
import '../../domain/item/item_inventory.dart';
import '../../domain/item/item_pricing.dart';
import '../../domain/item/item_query.dart';
import '../../domain/item/item_repository.dart';
import '../../domain/item/item_unit.dart';
import '../../domain/store/store_id.dart';
import '../database/store_database.dart';

/// SQLite and Drift implementation of [ItemRepository].
/// Operates on encrypted local store database with high-performance indexing and pagination.
class DriftItemRepository implements ItemRepository {
  final StoreDatabase _database;
  final StoreId _storeId;

  DriftItemRepository({
    required StoreDatabase database,
    required StoreId storeId,
  })  : _database = database,
        _storeId = storeId;

  Future<void> _ensureOpen() async {
    if (!_database.isOpen) {
      final openRes = await _database.open();
      if (openRes.isFailure) {
        throw openRes.errorOrNull!;
      }
    }
  }

  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async {
    try {
      await _ensureOpen();

      final whereClauses = <String>['store_id = ?'];
      final whereParams = <Object?>[_storeId.value];

      // Search across name, sku, barcode
      if (query.search.trim().isNotEmpty) {
        final term = '%${query.search.trim().toLowerCase()}%';
        whereClauses.add(
          '(LOWER(name) LIKE ? OR LOWER(sku) LIKE ? OR LOWER(barcode) LIKE ?)',
        );
        whereParams.addAll([term, term, term]);
      }

      // Filter: Category
      if (query.filter.categoryId != null &&
          query.filter.categoryId!.trim().isNotEmpty) {
        whereClauses.add('category_id = ?');
        whereParams.add(query.filter.categoryId!.trim());
      }

      // Filter: Status
      switch (query.filter.statusFilter) {
        case StatusFilter.active:
          whereClauses.add('is_active = 1');
          break;
        case StatusFilter.archived:
          whereClauses.add('is_active = 0');
          break;
        case StatusFilter.all:
          break;
      }

      // Filter: Stock
      switch (query.filter.stockFilter) {
        case StockFilter.inStock:
          whereClauses.add('quantity > 0');
          break;
        case StockFilter.lowStock:
          whereClauses.add(
            'reorder_level IS NOT NULL AND quantity > 0 AND quantity <= reorder_level',
          );
          break;
        case StockFilter.outOfStock:
          whereClauses.add('quantity <= 0');
          break;
        case StockFilter.all:
          break;
      }

      // Filter: Cost Price Range
      if (query.filter.minCostPrice != null) {
        whereClauses.add('cost_price >= ?');
        whereParams.add(query.filter.minCostPrice!);
      }
      if (query.filter.maxCostPrice != null) {
        whereClauses.add('cost_price <= ?');
        whereParams.add(query.filter.maxCostPrice!);
      }

      // Filter: Base Selling Price Range
      if (query.filter.minSellingPrice != null) {
        whereClauses.add('base_selling_price >= ?');
        whereParams.add(query.filter.minSellingPrice!);
      }
      if (query.filter.maxSellingPrice != null) {
        whereClauses.add('base_selling_price <= ?');
        whereParams.add(query.filter.maxSellingPrice!);
      }

      // Filter: Unit
      if (query.filter.unit != null) {
        whereClauses.add('unit = ?');
        whereParams.add(query.filter.unit!.value);
      }

      final whereSql = whereClauses.join(' AND ');

      // 1. Total items count query
      final countSql = 'SELECT COUNT(*) as total FROM items WHERE $whereSql;';
      final countRows =
          await _database.executor.runSelect(countSql, whereParams);
      final totalItems = (countRows.first['total'] as num?)?.toInt() ?? 0;

      // 2. Fetch page items with deterministic secondary sorting
      final sortCol = query.sort.field.dbColumn;
      final sortDir = query.sort.order == SortOrder.ascending ? 'ASC' : 'DESC';
      final offset = (query.page - 1) * query.pageSize;

      final selectSql = '''
        SELECT * FROM items
        WHERE $whereSql
        ORDER BY $sortCol $sortDir, id ASC
        LIMIT ? OFFSET ?;
      ''';

      final pageParams = [...whereParams, query.pageSize, offset];
      final itemRows =
          await _database.executor.runSelect(selectSql, pageParams);

      final items = <Item>[];
      for (final row in itemRows) {
        items.add(_rowToItem(row));
      }

      return Success(
        PaginatedResult<Item>(
          items: items,
          page: query.page,
          pageSize: query.pageSize,
          totalItems: totalItems,
        ),
      );
    } catch (e, st) {
      return Failure(
        StorageError('Failed to query items catalog: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Item>> getById(ItemId id) async {
    try {
      await _ensureOpen();
      final rows = await _database.executor.runSelect(
        'SELECT * FROM items WHERE id = ? AND store_id = ? LIMIT 1;',
        [id.value, _storeId.value],
      );

      if (rows.isEmpty) {
        return Failure(NotFoundError('Item ${id.value} not found.'));
      }

      final hasHistoryRes = await hasTransactions(id);
      final hasHistory = hasHistoryRes.valueOrNull ?? false;

      final item = _rowToItem(rows.first, hasTransactions: hasHistory);
      return Success(item);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to retrieve item ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Item>> create(Item item) async {
    try {
      await _ensureOpen();

      await _database.executor.runInsert(
        '''
        INSERT INTO items (
          id, store_id, sku, barcode, name, description, category_id,
          unit, cost_price, base_selling_price, min_selling_price,
          quantity, reorder_level, is_active, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          item.id.value,
          _storeId.value,
          item.sku,
          item.barcode,
          item.name,
          item.description,
          item.categoryId,
          item.unit.value,
          item.pricing.costPrice,
          item.pricing.baseSellingPrice,
          item.pricing.minSellingPrice,
          item.inventory.quantity,
          item.inventory.reorderLevel,
          item.isActive ? 1 : 0,
          item.createdAt.toUtc().toIso8601String(),
          item.updatedAt.toUtc().toIso8601String(),
        ],
      );

      return Success(item);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to create item in database: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<Item>>> bulkCreate(List<Item> items) async {
    try {
      await _ensureOpen();

      if (items.isEmpty) return const Success([]);

      await _database.executor.runCustom('BEGIN TRANSACTION;');
      try {
        for (final item in items) {
          await _database.executor.runInsert(
            '''
            INSERT INTO items (
              id, store_id, sku, barcode, name, description, category_id,
              unit, cost_price, base_selling_price, min_selling_price,
              quantity, reorder_level, is_active, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            ''',
            [
              item.id.value,
              _storeId.value,
              item.sku,
              item.barcode,
              item.name,
              item.description,
              item.categoryId,
              item.unit.value,
              item.pricing.costPrice,
              item.pricing.baseSellingPrice,
              item.pricing.minSellingPrice,
              item.inventory.quantity,
              item.inventory.reorderLevel,
              item.isActive ? 1 : 0,
              item.createdAt.toUtc().toIso8601String(),
              item.updatedAt.toUtc().toIso8601String(),
            ],
          );
        }
        await _database.executor.runCustom('COMMIT;');
      } catch (e) {
        await _database.executor.runCustom('ROLLBACK;');
        rethrow;
      }

      return Success(items);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to bulk insert items: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Item>> update(Item item) async {
    try {
      await _ensureOpen();

      final now = DateTime.now().toUtc();
      final updatedItem = item.copyWith(updatedAt: now);

      await _database.executor.runUpdate(
        '''
        UPDATE items SET
          sku = ?,
          barcode = ?,
          name = ?,
          description = ?,
          category_id = ?,
          unit = ?,
          cost_price = ?,
          base_selling_price = ?,
          min_selling_price = ?,
          quantity = ?,
          reorder_level = ?,
          is_active = ?,
          updated_at = ?
        WHERE id = ? AND store_id = ?;
        ''',
        [
          updatedItem.sku,
          updatedItem.barcode,
          updatedItem.name,
          updatedItem.description,
          updatedItem.categoryId,
          updatedItem.unit.value,
          updatedItem.pricing.costPrice,
          updatedItem.pricing.baseSellingPrice,
          updatedItem.pricing.minSellingPrice,
          updatedItem.inventory.quantity,
          updatedItem.inventory.reorderLevel,
          updatedItem.isActive ? 1 : 0,
          updatedItem.updatedAt.toUtc().toIso8601String(),
          updatedItem.id.value,
          _storeId.value,
        ],
      );

      return Success(updatedItem);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to update item ${item.id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> archive(ItemId id) async {
    try {
      await _ensureOpen();
      final now = DateTime.now().toUtc().toIso8601String();
      await _database.executor.runUpdate(
        'UPDATE items SET is_active = 0, updated_at = ? WHERE id = ? AND store_id = ?;',
        [now, id.value, _storeId.value],
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to archive item ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> activate(ItemId id) async {
    try {
      await _ensureOpen();
      final now = DateTime.now().toUtc().toIso8601String();
      await _database.executor.runUpdate(
        'UPDATE items SET is_active = 1, updated_at = ? WHERE id = ? AND store_id = ?;',
        [now, id.value, _storeId.value],
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to activate item ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> delete(ItemId id) async {
    try {
      await _ensureOpen();

      // Enforce Domain Rule (ADR 0012): items with historical transactions cannot be deleted
      final hasHistoryRes = await hasTransactions(id);
      if (hasHistoryRes.isSuccess && hasHistoryRes.valueOrNull == true) {
        return const Failure(
          DomainError(
            'This item has transaction history and cannot be permanently deleted. You can archive it instead.',
          ),
        );
      }

      await _database.executor.runDelete(
        'DELETE FROM items WHERE id = ? AND store_id = ?;',
        [id.value, _storeId.value],
      );

      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to delete item ${id.value}: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<bool>> hasTransactions(ItemId id) async {
    try {
      await _ensureOpen();
      final rows = await _database.executor.runSelect(
        'SELECT COUNT(*) as count FROM item_transactions WHERE item_id = ? AND store_id = ?;',
        [id.value, _storeId.value],
      );
      final count = (rows.first['count'] as num?)?.toInt() ?? 0;
      return Success(count > 0);
    } catch (_) {
      return const Success(false);
    }
  }

  @override
  Future<Result<List<String>>> getCategories() async {
    try {
      await _ensureOpen();
      final rows = await _database.executor.runSelect(
        '''
        SELECT DISTINCT category_id FROM items
        WHERE store_id = ? AND category_id IS NOT NULL AND TRIM(category_id) != ''
        ORDER BY category_id ASC;
        ''',
        [_storeId.value],
      );

      final categories = rows
          .map((r) => r['category_id'] as String?)
          .whereType<String>()
          .toList();

      return Success(categories);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to fetch categories: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request) async {
    try {
      await _ensureOpen();

      if (request.scope == ItemExportScope.selectedItems) {
        if (request.selectedItemIds.isEmpty) return const Success([]);
        final placeholders =
            List.filled(request.selectedItemIds.length, '?').join(', ');
        final params = [
          _storeId.value,
          ...request.selectedItemIds.map((id) => id.value),
        ];
        final rows = await _database.executor.runSelect(
          '''
          SELECT * FROM items
          WHERE store_id = ? AND id IN ($placeholders)
          ORDER BY name ASC;
          ''',
          params,
        );
        return Success(rows.map(_rowToItem).toList());
      } else if (request.scope == ItemExportScope.allItems) {
        final rows = await _database.executor.runSelect(
          'SELECT * FROM items WHERE store_id = ? ORDER BY name ASC;',
          [_storeId.value],
        );
        return Success(rows.map(_rowToItem).toList());
      } else {
        // currentView: execute full query without pagination limit
        final fullQuery = request.query.copyWith(page: 1, pageSize: 100000);
        final paginated = await query(fullQuery);
        if (paginated.isFailure) return Failure(paginated.errorOrNull!);
        return Success(paginated.valueOrNull!.items);
      }
    } catch (e, st) {
      return Failure(
        StorageError('Failed to retrieve items for export: $e'),
        stackTrace: st,
      );
    }
  }

  Item _rowToItem(Map<String, Object?> row, {bool hasTransactions = false}) {
    return Item(
      id: ItemId(row['id']! as String),
      storeId: StoreId(row['store_id']! as String),
      name: row['name']! as String,
      sku: row['sku'] as String?,
      barcode: row['barcode'] as String?,
      description: row['description'] as String?,
      categoryId: row['category_id'] as String?,
      unit: ItemUnit.fromString(row['unit'] as String?),
      pricing: ItemPricing(
        costPrice: (row['cost_price'] as num?)?.toDouble() ?? 0.0,
        baseSellingPrice:
            (row['base_selling_price'] as num?)?.toDouble() ?? 0.0,
        minSellingPrice: (row['min_selling_price'] as num?)?.toDouble(),
      ),
      inventory: ItemInventory(
        quantity: (row['quantity'] as num?)?.toDouble() ?? 0.0,
        reorderLevel: (row['reorder_level'] as num?)?.toDouble(),
      ),
      isActive: (row['is_active'] as num?)?.toInt() == 1,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      hasTransactions: hasTransactions,
    );
  }
}
