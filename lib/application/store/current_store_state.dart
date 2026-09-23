import '../../domain/store/store.dart';
import '../../domain/sync/store_sync_state.dart';

/// Discriminated union representing the active store context in Tally.
sealed class CurrentStoreState {
  const CurrentStoreState();
}

/// No store is currently selected (user is on the store picker screen).
final class NoStoreSelected extends CurrentStoreState {
  const NoStoreSelected();
}

/// A store is currently being opened, prepared, or decrypted.
final class SelectingStore extends CurrentStoreState {
  final Store store;
  const SelectingStore(this.store);
}

/// A store is active and its local encrypted database is ready for transactions.
final class StoreSelected extends CurrentStoreState {
  final Store store;
  final String dbPath;
  final SyncStatus syncStatus;

  const StoreSelected({
    required this.store,
    required this.dbPath,
    this.syncStatus = SyncStatus.local,
  });

  StoreSelected copyWith({
    Store? store,
    String? dbPath,
    SyncStatus? syncStatus,
  }) {
    return StoreSelected(
      store: store ?? this.store,
      dbPath: dbPath ?? this.dbPath,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

/// The store metadata exists, but its local database file is missing or needs download.
final class StoreUnavailable extends CurrentStoreState {
  final Store store;
  final String reason;

  const StoreUnavailable({
    required this.store,
    required this.reason,
  });
}

/// Error encountered while opening or manipulating the store database.
final class CurrentStoreError extends CurrentStoreState {
  final Object error;
  const CurrentStoreError(this.error);
}
