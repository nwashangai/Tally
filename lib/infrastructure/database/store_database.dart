import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store_id.dart';

/// Schema version for Tally store databases.
const int kCurrentStoreDbSchemaVersion = 1;

/// Drift-backed database instance for a single Tally store.
/// Manages connection, SQLCipher encryption pragma, and foundational schema tables.
class StoreDatabase {
  static bool _sqlCipherConfigured = false;

  static void ensureSqlCipherConfigured() {
    if (!_sqlCipherConfigured) {
      try {
        sqlite3_open.open.overrideFor(
          sqlite3_open.OperatingSystem.android,
          openCipherOnAndroid,
        );
      } catch (_) {
        // Ignored on non-Android or unit test environments
      }
      _sqlCipherConfigured = true;
    }
  }

  final StoreId storeId;
  final File databaseFile;
  final String encryptionKey;
  late final NativeDatabase _executor;
  bool _isOpen = false;

  StoreDatabase({
    required this.storeId,
    required this.databaseFile,
    required this.encryptionKey,
  }) {
    ensureSqlCipherConfigured();
    _executor = NativeDatabase(
      databaseFile,
      setup: (rawDb) {
        // Configure SQLCipher encryption key
        if (encryptionKey.isNotEmpty) {
          rawDb.execute("PRAGMA key = '$encryptionKey';");
        }
        // Enable Write-Ahead Logging for concurrency & safe checkpointing
        rawDb.execute('PRAGMA journal_mode = WAL;');
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  bool get isOpen => _isOpen;

  /// Opens the database and initializes foundational schema tables.
  Future<Result<void>> open() async {
    try {
      if (_isOpen) return const Success(null);

      // Verify directory exists
      if (!await databaseFile.parent.exists()) {
        await databaseFile.parent.create(recursive: true);
      }

      await _executor.ensureOpen(_DbUser());
      _isOpen = true;

      // Initialize base schema tables
      await _initializeSchema();

      return const Success(null);
    } catch (e, st) {
      _isOpen = false;
      return Failure(
        StorageError('Failed to open store database: $e'),
        stackTrace: st,
      );
    }
  }

  /// Initializes base metadata and health tables.
  Future<void> _initializeSchema() async {
    // Foundational table: metadata (store ID, created date, schema version)
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS store_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      );
    ''');

    // Record store ID and schema version
    await _executor.runInsert(
      '''
      INSERT OR REPLACE INTO store_metadata (key, value)
      VALUES (?, ?)
      ''',
      ['store_id', storeId.value],
    );

    await _executor.runInsert(
      '''
      INSERT OR REPLACE INTO store_metadata (key, value)
      VALUES (?, ?)
      ''',
      ['schema_version', kCurrentStoreDbSchemaVersion.toString()],
    );

    await _executor.runInsert(
      '''
      INSERT OR REPLACE INTO schema_migrations (version, applied_at)
      VALUES (?, ?)
      ''',
      [kCurrentStoreDbSchemaVersion, DateTime.now().toUtc().toIso8601String()],
    );
  }

  /// Flushes all WAL pages to ensure a consistent, safe-to-export database file.
  Future<Result<void>> checkpoint() async {
    try {
      if (!_isOpen) {
        final openResult = await open();
        if (openResult.isFailure) return openResult;
      }
      await _executor.runCustom('PRAGMA wal_checkpoint(FULL);');
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to checkpoint WAL: $e'),
        stackTrace: st,
      );
    }
  }

  /// Validates that the database file can be decrypted and queried successfully.
  Future<Result<bool>> validateIntegrity() async {
    try {
      if (!_isOpen) {
        final openResult = await open();
        if (openResult.isFailure) return const Success(false);
      }
      final rows = await _executor.runSelect(
        "SELECT value FROM store_metadata WHERE key = 'store_id';",
        [],
      );
      if (rows.isEmpty) return const Success(false);
      final storedId = rows.first['value'] as String?;
      return Success(storedId == storeId.value);
    } catch (_) {
      return const Success(false);
    }
  }

  /// Retrieves all self-describing metadata stored in this database file.
  Future<Result<Map<String, String>>> readStoreMetadata() async {
    try {
      if (!_isOpen) {
        final openResult = await open();
        if (openResult.isFailure) return Failure(openResult.errorOrNull!);
      }
      final rows = await _executor.runSelect(
        'SELECT key, value FROM store_metadata;',
        [],
      );
      final Map<String, String> result = {};
      for (final row in rows) {
        final k = row['key'] as String?;
        final v = row['value'] as String?;
        if (k != null && v != null) {
          result[k] = v;
        }
      }
      return Success(result);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to read store metadata: $e'),
        stackTrace: st,
      );
    }
  }

  /// Sets a metadata key-value pair in the database.
  Future<Result<void>> setMetadata(String key, String value) async {
    try {
      if (!_isOpen) {
        final openResult = await open();
        if (openResult.isFailure) return openResult;
      }
      await _executor.runInsert(
        '''
        INSERT OR REPLACE INTO store_metadata (key, value)
        VALUES (?, ?)
        ''',
        [key, value],
      );
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to set metadata key $key: $e'),
        stackTrace: st,
      );
    }
  }

  /// Safely closes the database connection.
  Future<Result<void>> close() async {
    try {
      if (!_isOpen) return const Success(null);
      await _executor.close();
      _isOpen = false;
      return const Success(null);
    } catch (e, st) {
      return Failure(
        StorageError('Failed to close database: $e'),
        stackTrace: st,
      );
    }
  }
}

class _DbUser extends QueryExecutorUser {
  @override
  int get schemaVersion => kCurrentStoreDbSchemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
