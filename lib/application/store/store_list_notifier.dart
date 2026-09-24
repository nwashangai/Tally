import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_repository.dart';
import '../../infrastructure/database/store_database.dart';
import '../../infrastructure/store/drift_store_database_manager.dart';

/// Presentation wrapper pairing a store entity with its local physical DB presence.
class StoreItemState {
  final Store store;
  final bool localDbExists;

  const StoreItemState({
    required this.store,
    required this.localDbExists,
  });

  StoreItemState copyWith({
    Store? store,
    bool? localDbExists,
  }) {
    return StoreItemState(
      store: store ?? this.store,
      localDbExists: localDbExists ?? this.localDbExists,
    );
  }
}

/// Manages the list of accessible stores, store creation, and backup restoration.
class StoreListNotifier
    extends StateNotifier<AsyncValue<List<StoreItemState>>> {
  final StoreRepository _storeRepo;
  final StoreDatabaseManager _dbManager;

  StoreListNotifier({
    required StoreRepository storeRepo,
    required StoreDatabaseManager dbManager,
  })  : _storeRepo = storeRepo,
        _dbManager = dbManager,
        super(const AsyncValue.loading());

  /// Discovers all stores accessible by [userId] and checks local DB file presence.
  Future<void> loadStores(String userId) async {
    state = const AsyncValue.loading();
    final result = await _storeRepo.getAccessibleStores(userId);

    if (result.isFailure) {
      state = AsyncValue.error(
        result.errorOrNull!,
        StackTrace.current,
      );
      return;
    }

    final stores = result.valueOrNull ?? [];
    final items = <StoreItemState>[];

    for (final store in stores) {
      final existsResult = await _dbManager.exists(store.id);
      final hasLocalDb = existsResult.valueOrNull ?? false;
      items.add(StoreItemState(store: store, localDbExists: hasLocalDb));
    }

    state = AsyncValue.data(items);
  }

  /// Creates a new store and provisions its local encrypted database.
  /// Uses a compensating transaction if database initialization fails.
  Future<Result<Store>> createStore({
    required String name,
    required String userId,
  }) async {
    // 1. Create metadata record
    final createResult =
        await _storeRepo.createStore(name: name, userId: userId);
    if (createResult.isFailure) {
      return createResult;
    }
    final store = createResult.valueOrNull!;

    // 2. Initialize local encrypted database file
    final dbResult = await _dbManager.create(store.id);
    if (dbResult.isFailure) {
      // Compensating action: roll back metadata
      await _storeRepo.deleteStore(store.id);
      return Failure(
        StorageError(
          'Failed to initialize store database: ${dbResult.errorOrNull}',
        ),
      );
    }

    // 3. Refresh stores list
    await loadStores(userId);
    return Success(store);
  }

  /// Imports a store database from raw backup bytes, registers it in store metadata,
  /// saves the SQLite file into the local store directory, and verifies database integrity.
  Future<Result<Store>> importStoreFromBackup({
    required List<int> fileBytes,
    required String fileName,
    required String userId,
    String? storeName,
  }) async {
    if (fileBytes.isEmpty) {
      return const Failure(
        ValidationError('Backup file is empty.', field: 'file'),
      );
    }

    // 1. Determine clean store name
    String effectiveName = (storeName ?? '').trim();
    if (effectiveName.isEmpty) {
      effectiveName = fileName
          .replaceAll(
              RegExp(r'\.(db|sqlite|tally|sqlite3)$', caseSensitive: false), '')
          .replaceAll(RegExp(r'^(Tally|Backup)_', caseSensitive: false), '')
          .replaceAll(RegExp(r'_export_\d+$'), '')
          .replaceAll('_', ' ')
          .trim();
      if (effectiveName.isEmpty) {
        effectiveName = 'Imported Store';
      }
    }

    // 2. Create metadata record
    final createResult = await _storeRepo.createStore(
      name: effectiveName,
      userId: userId,
    );
    if (createResult.isFailure) {
      return createResult;
    }
    final store = createResult.valueOrNull!;

    // 3. Resolve destination file path
    final pathResult = await _dbManager.getDatabaseFilePath(store.id);
    if (pathResult.isFailure) {
      await _storeRepo.deleteStore(store.id);
      return Failure(pathResult.errorOrNull!);
    }
    final destPath = pathResult.valueOrNull!;

    try {
      final destFile = File(destPath);
      if (!await destFile.parent.exists()) {
        await destFile.parent.create(recursive: true);
      }

      // 4. Write database bytes to disk
      await destFile.writeAsBytes(fileBytes, flush: true);

      // 5. If DriftStoreDatabaseManager, migrate table rows and handle re-encryption
      if (_dbManager is DriftStoreDatabaseManager) {
        final keyResult = await _dbManager.keyManager.getOrCreateKey(store.id);
        final destKey = keyResult.valueOrNull ?? '';

        final tempDbPlain = StoreDatabase(
          storeId: store.id,
          databaseFile: destFile,
          encryptionKey: '',
        );

        final plainOpenRes = await tempDbPlain.open();
        if (plainOpenRes.isSuccess) {
          // 1. Migrate all table records (items, item_transactions, receivings, receiving_lines) to the new store ID
          await tempDbPlain.migrateStoreId(store.id);

          // 2. Re-encrypt with destKey if encryption is active on device
          if (destKey.isNotEmpty) {
            final tempEncFile = File('${destFile.path}_reenc');
            final encResult = await tempDbPlain.exportEncrypted(
              targetFile: tempEncFile,
              newKey: destKey,
            );
            await tempDbPlain.close();
            if (encResult.isSuccess && await tempEncFile.exists()) {
              await tempEncFile.copy(destFile.path);
              await tempEncFile.delete();
            }
          } else {
            await tempDbPlain.close();
          }
        } else {
          // If already encrypted, open with destKey and migrate store ID
          final dbRes = await _dbManager.getOrOpenStoreDatabase(store.id);
          if (dbRes.isSuccess) {
            final db = dbRes.valueOrNull!;
            await db.migrateStoreId(store.id);
          }
        }
      }

      // 6. Validate integrity
      final integrityResult = await _dbManager.validateIntegrity(store.id);
      final isValid = integrityResult.valueOrNull ?? false;
      if (!isValid) {
        await _dbManager.delete(store.id);
        await _storeRepo.deleteStore(store.id);
        return const Failure(
          StorageError(
            'The selected backup file is corrupted or not a valid Tally database.',
          ),
        );
      }

      // 7. Refresh stores list
      await loadStores(userId);
      return Success(store);
    } catch (e, st) {
      try {
        await _dbManager.delete(store.id);
        await _storeRepo.deleteStore(store.id);
      } catch (_) {}
      return Failure(
        StorageError('Failed to import store database: $e'),
        stackTrace: st,
      );
    }
  }

  /// Permanently deletes a store: removes its local SQLite database and WAL files,
  /// deletes its encryption keys, removes the metadata record, and refreshes the store list.
  Future<Result<void>> deleteStore({
    required StoreId storeId,
    required String userId,
  }) async {
    // 1. Delete physical database file and encryption keys
    final dbDeleteResult = await _dbManager.delete(storeId);
    if (dbDeleteResult.isFailure) {
      // Continue to metadata deletion attempt so the user does not remain stuck with a ghost entry
    }

    // 2. Delete metadata record
    final repoDeleteResult = await _storeRepo.deleteStore(storeId);
    if (repoDeleteResult.isFailure) {
      return repoDeleteResult;
    }

    if (dbDeleteResult.isFailure) {
      return dbDeleteResult;
    }

    // 3. Refresh stores list
    await loadStores(userId);
    return const Success(null);
  }
}
