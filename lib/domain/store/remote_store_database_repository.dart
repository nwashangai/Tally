import '../../core/result/result.dart';
import 'remote_store_database_metadata.dart';
import 'store_id.dart';

/// Abstract port for remote store database file operations in serverless object storage.
/// All remote operations enforce server-side user authorization.
abstract interface class RemoteStoreDatabaseRepository {
  /// Fetches metadata for a remote store database file.
  Future<Result<RemoteStoreDatabaseMetadata?>> getMetadata(StoreId storeId);

  /// Uploads a local database file to remote serverless storage.
  Future<Result<void>> upload({
    required StoreId storeId,
    required String localFilePath,
    required int revision,
  });

  /// Downloads a remote database file to a local destination.
  Future<Result<void>> download({
    required StoreId storeId,
    required String destinationFilePath,
  });
}
