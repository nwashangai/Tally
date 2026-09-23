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
import '../../domain/auth/auth_repository.dart';
import '../../domain/services/platform_services.dart';
import '../../domain/store/remote_store_database_repository.dart';
import '../../domain/store/store_database_manager.dart';
import '../../domain/store/store_id.dart';
import '../../domain/store/store_key_manager.dart';
import '../../domain/store/store_repository.dart';
import '../../domain/store/store_storage.dart';
import '../../domain/sync/sync_engine.dart';
import '../../infrastructure/auth/mock_auth_repository.dart';
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

/// Internal fallback during async bootstrap
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
