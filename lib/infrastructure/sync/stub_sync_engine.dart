import 'dart:async';
import '../../core/result/result.dart';
import '../../domain/store/store_id.dart';
import '../../domain/sync/store_sync_state.dart';
import '../../domain/sync/sync_engine.dart';

/// Stub SyncEngine for use before a backend provider and conflict strategy are selected.
/// All stores report [SyncStatus.local] — no remote operations are performed.
class StubSyncEngine implements SyncEngine {
  final _controllers = <String, StreamController<StoreSyncState>>{};
  final _states = <String, StoreSyncState>{};

  StreamController<StoreSyncState> _controllerFor(StoreId storeId) {
    return _controllers.putIfAbsent(
      storeId.value,
      () => StreamController<StoreSyncState>.broadcast(),
    );
  }

  StoreSyncState _stateFor(StoreId storeId) {
    return _states.putIfAbsent(
      storeId.value,
      () => StoreSyncState(storeId: storeId, status: SyncStatus.local),
    );
  }

  @override
  Stream<StoreSyncState> watchSyncState(StoreId storeId) =>
      _controllerFor(storeId).stream;

  @override
  StoreSyncState currentState(StoreId storeId) => _stateFor(storeId);

  @override
  Future<Result<void>> syncStore(StoreId storeId) async {
    // Stub: no remote operations. Returns success immediately.
    return const Success(null);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
  }
}
