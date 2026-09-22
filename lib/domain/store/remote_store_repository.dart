import '../../core/result/result.dart';
import 'store_id.dart';
import 'store_snapshot.dart';

/// Abstract port for remote store backup, download, and disaster recovery.
/// Implementation details (Supabase, Firebase, S3, custom edge API) are isolated behind this interface.
abstract interface class RemoteStoreRepository {
  /// Downloads the latest remote snapshot for [storeId].
  Future<Result<StoreSnapshot?>> downloadStore(StoreId storeId);

  /// Uploads a store snapshot to remote storage.
  Future<Result<void>> uploadStore(StoreSnapshot snapshot);

  /// Deletes a remote store backup.
  Future<Result<void>> deleteStore(StoreId storeId);
}
