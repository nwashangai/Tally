import '../../core/result/result.dart';
import '../store/store_id.dart';
import 'store_sync_state.dart';

/// Abstract port for the store synchronization engine.
/// Implementations are isolated in the infrastructure layer.
abstract interface class SyncEngine {
  /// Emits the current sync state for a specific store.
  Stream<StoreSyncState> watchSyncState(StoreId storeId);

  /// Returns the current sync state for a store.
  StoreSyncState currentState(StoreId storeId);

  /// Triggers a sync for the given store (upload local → remote, or download remote → local).
  Future<Result<void>> syncStore(StoreId storeId);

  /// Pauses all sync operations (e.g., when the user goes offline manually).
  Future<void> pause();

  /// Resumes automatic sync.
  Future<void> resume();
}
