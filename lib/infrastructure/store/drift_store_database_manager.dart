import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_key_manager.dart';
import '../database/store_database.dart';

/// Drift & SQLCipher implementation of [StoreDatabaseManager].
/// Manages isolated `<store_id>.db` files per store.
class DriftStoreDatabaseManager implements StoreDatabaseManager {
  final String _baseDirectory;
  final StoreKeyManager _keyManager;
  final Map<StoreId, StoreDatabase> _openDatabases = {};

  DriftStoreDatabaseManager({
    required String baseDirectory,
    required StoreKeyManager keyManager,
  })  : _baseDirectory = baseDirectory,
        _keyManager = keyManager;

  /// Convenience factory resolving application documents directory.
  static Future<DriftStoreDatabaseManager> initialize({
    required StoreKeyManager keyManager,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final storesDir = Directory('${docs.path}/tally/stores');
    if (!await storesDir.exists()) {
      await storesDir.create(recursive: true);
    }
    return DriftStoreDatabaseManager(
      baseDirectory: storesDir.path,
      keyManager: keyManager,
    );
  }

  File _fileFor(StoreId storeId) => File('$_baseDirectory/${storeId.value}.db');

  @override
  Future<Result<void>> create(StoreId storeId) async {
    try {
      final file = _fileFor(storeId);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      // Generate or retrieve encryption key
      final keyResult = await _keyManager.getOrCreateKey(storeId);
      if (keyResult.isFailure) return Failure(keyResult.errorOrNull!);
      final key = keyResult.valueOrNull!;

      final db = StoreDatabase(
        storeId: storeId,
        databaseFile: file,
        encryptionKey: key,
      );

      final openResult = await db.open();
      if (openResult.isFailure) return openResult;

      _openDatabases[storeId] = db;
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to create store database: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> open(StoreId storeId) async {
    try {
      if (_openDatabases.containsKey(storeId) &&
          _openDatabases[storeId]!.isOpen) {
        return const Success(null);
      }

      final file = _fileFor(storeId);
      if (!await file.exists()) {
        return Failure(
          NotFoundError('Database file for store ${storeId.value} not found.'),
        );
      }

      final keyResult = await _keyManager.getKey(storeId);
      if (keyResult.isFailure) return Failure(keyResult.errorOrNull!);
      final key = keyResult.valueOrNull ?? '';

      final db = StoreDatabase(
        storeId: storeId,
        databaseFile: file,
        encryptionKey: key,
      );

      final openResult = await db.open();
      if (openResult.isFailure) return openResult;

      _openDatabases[storeId] = db;
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to open store database: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> close(StoreId storeId) async {
    try {
      final db = _openDatabases.remove(storeId);
      if (db != null) {
        return await db.close();
      }
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to close store database: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<void>> checkpoint(StoreId storeId) async {
    try {
      final db = _openDatabases[storeId];
      if (db != null) {
        return await db.checkpoint();
      }
      // If not currently open, open briefly to flush checkpoint then close
      final openRes = await open(storeId);
      if (openRes.isFailure) return openRes;
      final activeDb = _openDatabases[storeId];
      return await activeDb?.checkpoint() ?? const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to checkpoint store database: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<bool>> exists(StoreId storeId) async {
    try {
      final file = _fileFor(storeId);
      return Success(await file.exists());
    } catch (e, st) {
      return Failure(
        StorageError('Failed to check database existence: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<String>> getDatabaseFilePath(StoreId storeId) async {
    try {
      final file = _fileFor(storeId);
      return Success(file.path);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to resolve database file path: $e'),
        stackTrace: st,
      );
    }
  }

  @override
  Future<Result<bool>> validateIntegrity(StoreId storeId) async {
    try {
      final file = _fileFor(storeId);
      if (!await file.exists()) return const Success(false);

      final db = _openDatabases[storeId];
      if (db != null) {
        return await db.validateIntegrity();
      }

      final openRes = await open(storeId);
      if (openRes.isFailure) return const Success(false);

      final activeDb = _openDatabases[storeId];
      return await activeDb?.validateIntegrity() ?? const Success(false);
    } catch (_) {
      return const Success(false);
    }
  }

  @override
  Future<Result<void>> delete(StoreId storeId) async {
    try {
      await close(storeId);
      final file = _fileFor(storeId);
      if (await file.exists()) {
        await file.delete();
      }
      // Delete associated WAL and SHM files if they exist
      final walFile = File('${file.path}-wal');
      if (await walFile.exists()) await walFile.delete();
      final shmFile = File('${file.path}-shm');
      if (await shmFile.exists()) await shmFile.delete();

      await _keyManager.deleteKey(storeId);
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to delete store database: $e'),
        stackTrace: st,
      );
    }
  }
}
