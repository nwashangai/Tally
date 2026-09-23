import '../../core/result/result.dart';
import 'store_id.dart';

/// Abstract port for managing cryptographic keys used for SQLCipher database encryption.
abstract interface class StoreKeyManager {
  /// Gets or generates the 256-bit encryption key for [storeId].
  Future<Result<String>> getOrCreateKey(StoreId storeId);

  /// Retrieves the existing key, or returns null if no key has been generated yet.
  Future<Result<String?>> getKey(StoreId storeId);

  /// Explicitly stores a known encryption key for [storeId] (used during restore/sync).
  Future<Result<void>> setKey(StoreId storeId, String key);

  /// Clears the stored encryption key for [storeId].
  Future<Result<void>> deleteKey(StoreId storeId);
}
