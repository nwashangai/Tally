import '../../core/result/result.dart';
import 'store_id.dart';

/// Abstract port for the lifecycle of physical store database files.
/// Manages creation, opening, closing, safe WAL checkpointing, and export of `<store_id>.db`.
abstract interface class StoreDatabaseManager {
  /// Initializes a new physical database file on disk with current schema.
  Future<Result<void>> create(StoreId storeId);

  /// Opens the store database connection for reading and mutating.
  Future<Result<void>> open(StoreId storeId);

  /// Safely closes the active database connection.
  Future<Result<void>> close(StoreId storeId);

  /// Flushes write-ahead log (WAL) pages to ensure a consistent, safe-to-copy database file.
  Future<Result<void>> checkpoint(StoreId storeId);

  /// Checks if the physical database file exists on disk.
  Future<Result<bool>> exists(StoreId storeId);

  /// Resolves the absolute filesystem path for the store database file.
  Future<Result<String>> getDatabaseFilePath(StoreId storeId);

  /// Validates that the database file exists, can be decrypted, and is not corrupt.
  Future<Result<bool>> validateIntegrity(StoreId storeId);

  /// Deletes the local store database file.
  Future<Result<void>> delete(StoreId storeId);
}
