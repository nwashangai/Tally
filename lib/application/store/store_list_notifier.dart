import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/store/store.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_repository.dart';

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

/// Manages the list of accessible stores and store creation.
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
}
