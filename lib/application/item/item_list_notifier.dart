import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_id.dart';
import '../../domain/item/item_query.dart';
import '../../domain/item/item_repository.dart';

/// Manages the async paginated state of the items catalog and orchestrates mutations.
class ItemListNotifier
    extends StateNotifier<AsyncValue<PaginatedResult<Item>>> {
  final ItemRepository _repository;
  ItemQuery _currentQuery;

  ItemListNotifier({
    required ItemRepository repository,
    ItemQuery initialQuery = const ItemQuery(),
  })  : _repository = repository,
        _currentQuery = initialQuery,
        super(const AsyncValue.loading()) {
    load();
  }

  /// Updates the query and re-executes the fetch.
  Future<void> updateQuery(ItemQuery newQuery) async {
    _currentQuery = newQuery;
    await load();
  }

  /// Refreshes the items list with the current query.
  Future<void> load() async {
    state = const AsyncValue.loading();
    final result = await _repository.query(_currentQuery);
    if (!mounted) return;

    if (result.isSuccess) {
      state = AsyncValue.data(result.valueOrNull!);
    } else {
      state = AsyncValue.error(
        result.errorOrNull ?? const StorageError('Failed to load items.'),
        StackTrace.current,
      );
    }
  }

  /// Creates a new item in the active store database.
  Future<Result<Item>> createItem(Item item) async {
    final result = await _repository.create(item);
    if (result.isSuccess) {
      await load();
    }
    return result;
  }

  /// Updates an existing item.
  Future<Result<Item>> updateItem(Item item) async {
    final result = await _repository.update(item);
    if (result.isSuccess) {
      await load();
    }
    return result;
  }

  /// Archives an item (soft-delete).
  Future<Result<void>> archiveItem(ItemId id) async {
    final result = await _repository.archive(id);
    if (result.isSuccess) {
      await load();
    }
    return result;
  }

  /// Re-activates an archived item.
  Future<Result<void>> activateItem(ItemId id) async {
    final result = await _repository.activate(id);
    if (result.isSuccess) {
      await load();
    }
    return result;
  }

  /// Permanently deletes an item (safeguarded if transaction history exists).
  Future<Result<void>> deleteItem(ItemId id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      await load();
    }
    return result;
  }

  /// Bulk creates items (e.g. from Excel/CSV import) and refreshes state.
  Future<Result<List<Item>>> importItems(List<Item> items) async {
    final result = await _repository.bulkCreate(items);
    if (result.isSuccess) {
      await load();
    }
    return result;
  }
}
