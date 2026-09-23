import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_key_manager.dart';

/// SecureStorage-backed implementation of [StoreKeyManager].
/// Stores per-store 256-bit encryption keys in the platform keychain/keystore.
class SecureStorageStoreKeyManager implements StoreKeyManager {
  final FlutterSecureStorage _storage;
  static const _keyPrefix = 'tally_store_key_';

  SecureStorageStoreKeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _storageKey(StoreId storeId) => '$_keyPrefix${storeId.value}';

  @override
  Future<Result<String>> getOrCreateKey(StoreId storeId) async {
    try {
      final existing = await _storage.read(key: _storageKey(storeId));
      if (existing != null && existing.isNotEmpty) {
        return Success(existing);
      }
      final newKey = _generateRandomKey();
      await _storage.write(key: _storageKey(storeId), value: newKey);
      return Success(newKey);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to generate or retrieve store key: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<String?>> getKey(StoreId storeId) async {
    try {
      final key = await _storage.read(key: _storageKey(storeId));
      return Success(key);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to read store key: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> setKey(StoreId storeId, String key) async {
    try {
      await _storage.write(key: _storageKey(storeId), value: key);
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to store encryption key: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> deleteKey(StoreId storeId) async {
    try {
      await _storage.delete(key: _storageKey(storeId));
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to delete store key: $e'),
        stackTrace: st,
      );
    }
  }

  String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}
