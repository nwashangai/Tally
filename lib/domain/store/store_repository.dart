import '../../core/result/result.dart';
import 'store.dart';
import 'store_id.dart';

/// Abstract port for store discovery and metadata management.
/// Resolves accessible stores for an authenticated user.
abstract interface class StoreRepository {
  /// Fetches all stores accessible by [userId].
  Future<Result<List<Store>>> getAccessibleStores(String userId);

  /// Retrieves a specific store by [storeId].
  Future<Result<Store?>> getStore(StoreId storeId);

  /// Registers/creates a new store owned by [userId].
  Future<Result<Store>> createStore({
    required String name,
    required String userId,
  });

  /// Updates store metadata.
  Future<Result<Store>> updateStore(Store store);

  /// Deletes a store record.
  Future<Result<void>> deleteStore(StoreId storeId);
}
