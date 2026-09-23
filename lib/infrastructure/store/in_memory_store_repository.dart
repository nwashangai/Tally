import 'package:uuid/uuid.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_repository.dart';

/// In-memory & seed-capable implementation of [StoreRepository] for development and testing.
class InMemoryStoreRepository implements StoreRepository {
  final Map<StoreId, Store> _stores = {};
  final Uuid _uuid;

  InMemoryStoreRepository({
    List<Store> initialStores = const [],
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid() {
    for (final store in initialStores) {
      _stores[store.id] = store;
    }
  }

  @override
  Future<Result<List<Store>>> getAccessibleStores(String userId) async {
    try {
      final accessible = _stores.values
          .where((store) => store.ownerId == userId)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Success(accessible);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to retrieve accessible stores: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Store?>> getStore(StoreId storeId) async {
    try {
      return Success(_stores[storeId]);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to get store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Store>> createStore({
    required String name,
    required String userId,
  }) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return const Failure(
            ValidationError('Store name cannot be empty.', field: 'name'));
      }

      final storeId =
          StoreId('store_${_uuid.v4().replaceAll('-', '').substring(0, 12)}');
      final now = DateTime.now().toUtc();
      final newStore = Store(
        id: storeId,
        name: trimmedName,
        ownerId: userId,
        createdAt: now,
        updatedAt: now,
        revision: 1,
      );

      _stores[storeId] = newStore;
      return Success(newStore);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to create store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<Store>> updateStore(Store store) async {
    try {
      if (!_stores.containsKey(store.id)) {
        return Failure(NotFoundError('Store ${store.id.value} not found.'));
      }
      final updated = store.copyWith(updatedAt: DateTime.now().toUtc());
      _stores[store.id] = updated;
      return Success(updated);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to update store: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> deleteStore(StoreId storeId) async {
    try {
      _stores.remove(storeId);
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to delete store: $e'),
        stackTrace: st,
      );
    }
  }
}
