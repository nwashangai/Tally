import '../../core/result/result.dart';
import 'item.dart';
import 'item_export.dart';
import 'item_id.dart';
import 'item_query.dart';

/// Repository boundary for inventory items in a store database.
abstract interface class ItemRepository {
  /// Executes a paginated, filtered, and sorted query against the items table.
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query);

  /// Retrieves an item by its unique ID.
  Future<Result<Item>> getById(ItemId id);

  /// Creates a new item in the catalog.
  Future<Result<Item>> create(Item item);

  /// Creates multiple items atomically in a single batch transaction.
  Future<Result<List<Item>>> bulkCreate(List<Item> items);

  /// Updates an existing item's current attributes.
  Future<Result<Item>> update(Item item);

  /// Archives an item so it is hidden from default views while preserving history.
  Future<Result<void>> archive(ItemId id);

  /// Re-activates a previously archived item.
  Future<Result<void>> activate(ItemId id);

  /// Permanently removes an item.
  /// **Domain Rule**: Fails with [DomainError] if the item has associated transaction history.
  Future<Result<void>> delete(ItemId id);

  /// Checks if an item has associated transaction history (Receiving, Sale, Adjustment).
  Future<Result<bool>> hasTransactions(ItemId id);

  /// Retrieves all distinct categories currently in use.
  Future<Result<List<String>>> getCategories();

  /// Retrieves all items matching an export request specification.
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request);
}
