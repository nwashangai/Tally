import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/store/remote_store_database_repository.dart';
import '../../domain/store/store.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/sync/store_sync_state.dart';
import 'current_store_state.dart';

/// Preference key for the currently active store ID.
const String kPrefKeyActiveStoreId = 'tally_active_store_id_v1';

/// Manages the currently selected active store, its database lifecycle, and sync status.
class CurrentStoreNotifier extends StateNotifier<CurrentStoreState> {
  final StoreDatabaseManager _dbManager;
  final RemoteStoreDatabaseRepository _remoteDbRepo;
  final SharedPreferences? _prefs;

  CurrentStoreNotifier({
    required StoreDatabaseManager dbManager,
    required RemoteStoreDatabaseRepository remoteDbRepo,
    SharedPreferences? prefs,
  })  : _dbManager = dbManager,
        _remoteDbRepo = remoteDbRepo,
        _prefs = prefs,
        super(const NoStoreSelected());

  /// Attempts to restore the previously active store from local preferences.
  Future<bool> restoreActiveStore(List<Store> accessibleStores) async {
    final activeId = _prefs?.getString(kPrefKeyActiveStoreId);
    if (activeId == null || activeId.isEmpty) return false;

    final match =
        accessibleStores.where((s) => s.id.value == activeId).firstOrNull;
    if (match != null) {
      await selectStore(match);
      return true;
    }
    return false;
  }

  /// Selects and activates a store, verifying its local database file and opening it.
  Future<void> selectStore(Store store) async {
    // Close previous store DB if active
    if (state is StoreSelected) {
      final prevStore = (state as StoreSelected).store;
      if (prevStore.id != store.id) {
        await _dbManager.close(prevStore.id);
      }
    }

    state = SelectingStore(store);

    // Verify local database existence
    final existsResult = await _dbManager.exists(store.id);
    if (existsResult.isFailure) {
      state = CurrentStoreError(existsResult.errorOrNull!);
      return;
    }

    final localExists = existsResult.valueOrNull ?? false;
    if (!localExists) {
      state = StoreUnavailable(
        store: store,
        reason: 'Local database file missing. Remote download required.',
      );
      return;
    }

    // Open database
    final openResult = await _dbManager.open(store.id);
    if (openResult.isFailure) {
      state = CurrentStoreError(openResult.errorOrNull!);
      return;
    }

    final pathResult = await _dbManager.getDatabaseFilePath(store.id);
    final path = pathResult.valueOrNull ?? '';

    // Persist active store preference
    await _prefs?.setString(kPrefKeyActiveStoreId, store.id.value);

    state = StoreSelected(
      store: store,
      dbPath: path,
      syncStatus: SyncStatus.local,
    );
  }

  /// Downloads a missing database from remote serverless storage and opens it.
  Future<void> downloadAndInstallStore(Store store) async {
    state = SelectingStore(store);

    final pathResult = await _dbManager.getDatabaseFilePath(store.id);
    if (pathResult.isFailure) {
      state = CurrentStoreError(pathResult.errorOrNull!);
      return;
    }
    final destPath = pathResult.valueOrNull!;

    final downloadResult = await _remoteDbRepo.download(
      storeId: store.id,
      destinationFilePath: destPath,
    );

    if (downloadResult.isFailure) {
      state = CurrentStoreError(downloadResult.errorOrNull!);
      return;
    }

    await selectStore(store);
  }

  /// Performs a safe WAL checkpoint and uploads the database file to remote cloud storage.
  Future<void> triggerManualBackup() async {
    if (state is! StoreSelected) return;
    final current = state as StoreSelected;

    state = current.copyWith(syncStatus: SyncStatus.syncing);

    // Flush WAL to disk
    final checkpointResult = await _dbManager.checkpoint(current.store.id);
    if (checkpointResult.isFailure) {
      state = current.copyWith(syncStatus: SyncStatus.error);
      return;
    }

    final uploadResult = await _remoteDbRepo.upload(
      storeId: current.store.id,
      localFilePath: current.dbPath,
      revision: current.store.revision,
    );

    if (uploadResult.isSuccess) {
      state = current.copyWith(syncStatus: SyncStatus.synced);
    } else {
      state = current.copyWith(syncStatus: SyncStatus.error);
    }
  }

  /// Deselects the current store and closes its active database connection.
  Future<void> clearStore() async {
    if (state is StoreSelected) {
      final currentStore = (state as StoreSelected).store;
      await _dbManager.close(currentStore.id);
    }
    await _prefs?.remove(kPrefKeyActiveStoreId);
    state = const NoStoreSelected();
  }
}
