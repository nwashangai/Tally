import '../store/store_id.dart';

/// Enumeration of all possible synchronization states for a single store.
enum SyncStatus {
  /// Store data has not yet been submitted for synchronization.
  local,

  /// Sync is pending: mutation is queued but not yet uploaded.
  pending,

  /// Sync is currently in progress.
  syncing,

  /// Local data matches the last confirmed remote snapshot.
  synced,

  /// Device is offline. Sync deferred until connectivity is restored.
  offline,

  /// An unresolvable conflict was detected between local and remote data.
  conflict,

  /// Sync attempt failed with an error.
  error,
}

/// Immutable value object representing the current sync state for one store.
final class StoreSyncState {
  final StoreId storeId;
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final int pendingMutationCount;

  const StoreSyncState({
    required this.storeId,
    required this.status,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingMutationCount = 0,
  });

  StoreSyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    int? pendingMutationCount,
  }) {
    return StoreSyncState(
      storeId: storeId,
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingMutationCount: pendingMutationCount ?? this.pendingMutationCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreSyncState &&
          other.storeId == storeId &&
          other.status == status &&
          other.lastSyncedAt == lastSyncedAt &&
          other.errorMessage == errorMessage &&
          other.pendingMutationCount == pendingMutationCount);

  @override
  int get hashCode => Object.hash(
      storeId, status, lastSyncedAt, errorMessage, pendingMutationCount);

  @override
  String toString() =>
      'StoreSyncState(storeId: $storeId, status: $status, pending: $pendingMutationCount)';
}
