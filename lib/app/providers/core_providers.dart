import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../application/store/current_store_notifier.dart';
import '../../application/store/current_store_state.dart';
import '../../application/store/store_export_service.dart';
import '../../application/store/store_list_notifier.dart';
import '../../core/identifiers/id_generator.dart';
import '../../core/logging/logger.dart';
import '../../core/platform/platform_info.dart';
import '../../core/result/result.dart';
import '../../core/time/clock.dart';
import '../../core/error/app_error.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_export.dart';
import '../../domain/item/item_export_service.dart';
import '../../domain/item/item_id.dart';
import '../../domain/item/item_query.dart';
import '../../domain/item/item_repository.dart';
import '../../domain/receiving/receiving.dart';
import '../../domain/receiving/receiving_id.dart';
import '../../domain/receiving/receiving_line_history.dart';
import '../../domain/receiving/receiving_query.dart';
import '../../domain/receiving/receiving_repository.dart';
import '../../application/item/item_column_preferences.dart';
import '../../application/item/item_list_notifier.dart';
import '../../application/item/item_query_notifier.dart';
import '../../application/item/item_selection_notifier.dart';
import '../../application/receiving/create_receiving_notifier.dart';
import '../../application/receiving/receiving_list_notifier.dart';
import '../../application/receiving/receiving_query_notifier.dart';
import '../../infrastructure/receiving/drift_receiving_repository.dart';
import '../../domain/reports/reports_repository.dart';
import '../../domain/reports/sales_profit_report.dart';
import '../../infrastructure/reports/drift_reports_repository.dart';
import '../../application/reports/reports_notifier.dart';
import '../../domain/services/platform_services.dart';
import '../../domain/store/remote_store_database_repository.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_key_manager.dart';
import '../../domain/store/store_repository.dart';
import '../../domain/store/store_storage.dart';
import '../../domain/sync/sync_engine.dart';
import '../../infrastructure/auth/mock_auth_repository.dart';
import '../../infrastructure/item/default_item_export_service.dart';
import '../../infrastructure/item/default_item_importer.dart';
import '../../infrastructure/item/drift_item_repository.dart';
import '../../infrastructure/item/item_importer.dart';
import '../../infrastructure/storage/file_store_storage.dart';
import '../../infrastructure/store/drift_store_database_manager.dart';
import '../../infrastructure/store/in_memory_store_repository.dart';
import '../../infrastructure/store/mock_remote_store_database_repository.dart';
import '../../infrastructure/store/persisted_store_repository.dart';
import '../../infrastructure/store/secure_storage_store_key_manager.dart';
import '../../infrastructure/sync/stub_sync_engine.dart';

// ---------------------------------------------------------------------------
// Core utilities
// ---------------------------------------------------------------------------

final loggerProvider = Provider<Logger>((ref) {
  return const AppLogger();
});

final clockProvider = Provider<Clock>((ref) {
  return const SystemClock();
});

final idGeneratorProvider = Provider<IdGenerator>((ref) {
  return const UuidGenerator();
});

final platformInfoProvider = Provider<PlatformInfo>((ref) {
  return const AppPlatformInfo();
});

// ---------------------------------------------------------------------------
// Authentication
// ---------------------------------------------------------------------------

/// Active [AuthRepository] provider.
/// Uses [MockAuthRepository] with secure session persistence.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = MockAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------

// Store & Database infrastructure
// ---------------------------------------------------------------------------

/// SharedPreferences instance provider (injected in bootstrap).
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null;
});

/// Manages SQLCipher encryption keys per store.
final storeKeyManagerProvider = Provider<StoreKeyManager>((ref) {
  return SecureStorageStoreKeyManager();
});

/// Asynchronous factory for [StoreDatabaseManager].
final storeDatabaseManagerProvider =
    FutureProvider<StoreDatabaseManager>((ref) async {
  final keyManager = ref.watch(storeKeyManagerProvider);
  return DriftStoreDatabaseManager.initialize(keyManager: keyManager);
});

/// Store metadata repository.
/// Uses [PersistedStoreRepository] when SharedPreferences is available, falls back to [InMemoryStoreRepository].
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return PersistedStoreRepository(prefs: prefs);
  }
  return InMemoryStoreRepository();
});

/// Remote store database file repository.
final remoteStoreDatabaseRepositoryProvider =
    Provider<RemoteStoreDatabaseRepository>((ref) {
  return MockRemoteStoreDatabaseRepository();
});

/// Legacy snapshot storage adapter.
final storeStorageProvider = FutureProvider<StoreStorage>((ref) async {
  return FileStoreStorage.create();
});

// ---------------------------------------------------------------------------
// Store application state
// ---------------------------------------------------------------------------

/// Manages the list of accessible stores for the authenticated user.
final storeListProvider =
    StateNotifierProvider<StoreListNotifier, AsyncValue<List<StoreItemState>>>(
  (ref) {
    final storeRepo = ref.watch(storeRepositoryProvider);
    final dbManagerAsync = ref.watch(storeDatabaseManagerProvider);
    final dbManager = dbManagerAsync.valueOrNull;

    if (dbManager == null) {
      // Return a notifier with a temporary fallback if not yet loaded
      return StoreListNotifier(
        storeRepo: storeRepo,
        dbManager: _FallbackDbManager(),
      );
    }

    return StoreListNotifier(
      storeRepo: storeRepo,
      dbManager: dbManager,
    );
  },
);

/// Manages the currently selected active store and its database lifecycle.
final currentStoreProvider =
    StateNotifierProvider<CurrentStoreNotifier, CurrentStoreState>((ref) {
  final dbManagerAsync = ref.watch(storeDatabaseManagerProvider);
  final dbManager = dbManagerAsync.valueOrNull ?? _FallbackDbManager();
  final remoteDbRepo = ref.watch(remoteStoreDatabaseRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return CurrentStoreNotifier(
    dbManager: dbManager,
    remoteDbRepo: remoteDbRepo,
    prefs: prefs,
  );
});

/// Service for exporting store database files.
final storeExportServiceProvider = Provider<StoreExportService>((ref) {
  final dbManager = ref.watch(storeDatabaseManagerProvider).valueOrNull ??
      _FallbackDbManager();
  return StoreExportService(dbManager: dbManager);
});

// ---------------------------------------------------------------------------
// Items & Inventory application providers
// ---------------------------------------------------------------------------

/// Provider for [ItemRepository] bound to the active store database.
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final currentStoreState = ref.watch(currentStoreProvider);
  final dbManager = ref.watch(storeDatabaseManagerProvider).valueOrNull;

  if (currentStoreState is StoreSelected &&
      dbManager is DriftStoreDatabaseManager) {
    final activeDb = dbManager.getOpenStoreDatabase(currentStoreState.store.id);
    if (activeDb != null) {
      return DriftItemRepository(
        database: activeDb,
        storeId: currentStoreState.store.id,
      );
    }
  }

  return _FallbackItemRepository();
});

/// Current item query state (search, filter, sort, pagination).
final itemQueryProvider =
    StateNotifierProvider<ItemQueryNotifier, ItemQuery>((ref) {
  return ItemQueryNotifier();
});

/// Multi-item selection state for bulk actions.
final itemSelectionProvider =
    StateNotifierProvider<ItemSelectionNotifier, Set<ItemId>>((ref) {
  return ItemSelectionNotifier();
});

/// Table column visibility and preset preferences.
final itemColumnPreferencesProvider =
    StateNotifierProvider<ItemColumnPreferencesNotifier, ItemColumnState>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ItemColumnPreferencesNotifier(prefs: prefs);
  },
);

/// Paginated items list provider.
final itemListProvider =
    StateNotifierProvider<ItemListNotifier, AsyncValue<PaginatedResult<Item>>>(
  (ref) {
    final repo = ref.watch(itemRepositoryProvider);
    final query = ref.watch(itemQueryProvider);
    final notifier = ItemListNotifier(
      repository: repo,
      initialQuery: query,
    );

    ref.listen<ItemQuery>(itemQueryProvider, (prev, next) {
      if (prev != next) {
        notifier.updateQuery(next);
      }
    });

    return notifier;
  },
);

/// Service for exporting items to Excel (.xlsx) and CSV.
final itemExportServiceProvider = Provider<ItemExportService>((ref) {
  final repo = ref.watch(itemRepositoryProvider);
  return DefaultItemExportService(repository: repo);
});

/// Service for importing items from Excel (.xlsx) and CSV.
final itemImporterProvider = Provider<ItemImporter>((ref) {
  return const DefaultItemImporter();
});

/// Distinct item categories available in active store catalog.
final itemCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(itemRepositoryProvider);
  final result = await repo.getCategories();
  return result.valueOrNull ?? [];
});

// ---------------------------------------------------------------------------
// Receiving application providers
// ---------------------------------------------------------------------------

/// Provider for [ReceivingRepository] bound to the active store database.
final receivingRepositoryProvider = Provider<ReceivingRepository>((ref) {
  final currentStoreState = ref.watch(currentStoreProvider);
  final dbManager = ref.watch(storeDatabaseManagerProvider).valueOrNull;

  if (currentStoreState is StoreSelected &&
      dbManager is DriftStoreDatabaseManager) {
    final activeDb = dbManager.getOpenStoreDatabase(currentStoreState.store.id);
    if (activeDb != null) {
      return DriftReceivingRepository(
        database: activeDb,
        storeId: currentStoreState.store.id,
      );
    }
  }

  return _FallbackReceivingRepository();
});

/// Current receiving query state (search, status filter, date range, sort, pagination).
final receivingQueryProvider =
    StateNotifierProvider<ReceivingQueryNotifier, ReceivingQuery>((ref) {
  return ReceivingQueryNotifier();
});

/// Paginated receivings list provider.
final receivingListProvider = StateNotifierProvider<ReceivingListNotifier,
    AsyncValue<PaginatedResult<Receiving>>>((ref) {
  final repo = ref.watch(receivingRepositoryProvider);
  final query = ref.watch(receivingQueryProvider);
  final notifier = ReceivingListNotifier(
    repository: repo,
    initialQuery: query,
  );

  ref.listen<ReceivingQuery>(receivingQueryProvider, (prev, next) {
    if (prev != next) {
      notifier.updateQuery(next);
    }
  });

  return notifier;
});

/// Provider for creating a new receiving transaction.
final createReceivingProvider = StateNotifierProvider.autoDispose<
    CreateReceivingNotifier, CreateReceivingState>((ref) {
  final repo = ref.watch(receivingRepositoryProvider);
  final currentStoreState = ref.watch(currentStoreProvider);
  final storeId = currentStoreState is StoreSelected
      ? currentStoreState.store.id
      : const StoreId('default');

  return CreateReceivingNotifier(
    repository: repo,
    storeId: storeId,
  );
});

/// Inbound receiving history for a specific item.
final itemReceivingHistoryProvider =
    FutureProvider.family<List<ReceivingLineHistory>, ItemId>(
        (ref, itemId) async {
  final repo = ref.watch(receivingRepositoryProvider);
  final result = await repo.getItemReceivingHistory(itemId);
  return result.valueOrNull ?? const [];
});

// ---------------------------------------------------------------------------
// Platform service providers
// ---------------------------------------------------------------------------

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = StubSyncEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

final adServiceProvider = Provider<AdService>((ref) {
  return const NoOpAdService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const NoOpAnalyticsService();
});

/// Internal fallback during async bootstrap or when no store is selected.
class _FallbackDbManager implements StoreDatabaseManager {
  @override
  Future<Result<void>> create(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> open(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> close(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> checkpoint(StoreId storeId) async => const Success(null);
  @override
  Future<Result<bool>> exists(StoreId storeId) async => const Success(false);
  @override
  Future<Result<String>> getDatabaseFilePath(StoreId storeId) async =>
      const Success('');
  @override
  Future<Result<bool>> validateIntegrity(StoreId storeId) async =>
      const Success(false);
  @override
  Future<Result<void>> delete(StoreId storeId) async => const Success(null);
}

class _FallbackItemRepository implements ItemRepository {
  @override
  Future<Result<PaginatedResult<Item>>> query(ItemQuery query) async =>
      Success(PaginatedResult<Item>(
        items: const [],
        page: query.page,
        pageSize: query.pageSize,
        totalItems: 0,
      ));

  @override
  Future<Result<Item>> getById(ItemId id) async =>
      const Failure(NotFoundError('No active store database.'));

  @override
  Future<Result<Item>> create(Item item) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<List<Item>>> bulkCreate(List<Item> items) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<Item>> update(Item item) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<void>> archive(ItemId id) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<void>> activate(ItemId id) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<void>> delete(ItemId id) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<bool>> hasTransactions(ItemId id) async => const Success(false);

  @override
  Future<Result<List<String>>> getCategories() async => const Success([]);

  @override
  Future<Result<List<Item>>> getExportItems(ItemExportRequest request) async =>
      const Success([]);
}

class _FallbackReceivingRepository implements ReceivingRepository {
  @override
  Future<Result<PaginatedResult<Receiving>>> query(
          ReceivingQuery query) async =>
      Success(PaginatedResult<Receiving>(
        items: const [],
        page: query.page,
        pageSize: query.pageSize,
        totalItems: 0,
      ));

  @override
  Future<Result<Receiving?>> getById(ReceivingId id) async =>
      const Success(null);

  @override
  Future<Result<Receiving>> create(Receiving receiving) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<Receiving>> complete(ReceivingId id) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<Receiving>> voidReceiving(ReceivingId id,
          {String? reason}) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<Receiving>> update(Receiving receiving) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<void>> delete(ReceivingId id) async =>
      const Failure(StorageError('No active store selected.'));

  @override
  Future<Result<String>> getNextReferenceNumber() async =>
      const Success('REC-000001');

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 50,
  }) async =>
      const Success([]);
}

// ---------------------------------------------------------------------------
// Reports application providers
// ---------------------------------------------------------------------------

/// Provider for [ReportsRepository] bound to the active store database.
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final currentStoreState = ref.watch(currentStoreProvider);
  final dbManager = ref.watch(storeDatabaseManagerProvider).valueOrNull;

  if (currentStoreState is StoreSelected &&
      dbManager is DriftStoreDatabaseManager) {
    final activeDb = dbManager.getOpenStoreDatabase(currentStoreState.store.id);
    if (activeDb != null) {
      return DriftReportsRepository(
        database: activeDb,
        storeId: currentStoreState.store.id,
      );
    }
  }

  return _FallbackReportsRepository();
});

/// Provider for reports state notifier.
final reportsNotifierProvider =
    StateNotifierProvider.autoDispose<ReportsNotifier, ReportsState>((ref) {
  final repo = ref.watch(reportsRepositoryProvider);
  return ReportsNotifier(repository: repo);
});

class _FallbackReportsRepository implements ReportsRepository {
  @override
  Future<Result<SalesProfitReport>> getSalesProfitReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return Success(SalesProfitReport(
      startDate: startDate,
      endDate: endDate,
      itemReports: const [],
      transactionCount: 0,
    ));
  }
}
