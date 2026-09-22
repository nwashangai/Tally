import '../../core/result/result.dart';
import 'store_id.dart';
import 'store_snapshot.dart';

/// Abstract port for local store file persistence.
/// Enforces a file-per-store storage model designed for offline use,
/// corruption detection, and atomic operations.
abstract interface class StoreStorage {
  /// Reads and deserializes a local store snapshot by [storeId].
  Future<Result<StoreSnapshot?>> readStore(StoreId storeId);

  /// Atomically writes a store snapshot to disk.
  Future<Result<void>> writeStore(StoreSnapshot snapshot);

  /// Deletes a local store snapshot file.
  Future<Result<void>> deleteStore(StoreId storeId);

  /// Returns true if a local file exists for [storeId].
  Future<Result<bool>> exists(StoreId storeId);

  /// Lists all store IDs found in local storage.
  Future<Result<List<StoreId>>> listStoreIds();
}
