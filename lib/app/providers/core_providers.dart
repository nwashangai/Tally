import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/identifiers/id_generator.dart';
import '../../core/logging/logger.dart';
import '../../core/platform/platform_info.dart';
import '../../core/time/clock.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/services/platform_services.dart';
import '../../domain/store/store_storage.dart';
import '../../domain/sync/sync_engine.dart';
import '../../infrastructure/auth/stub_auth_repository.dart';
import '../../infrastructure/storage/file_store_storage.dart';
import '../../infrastructure/sync/stub_sync_engine.dart';

// ---------------------------------------------------------------------------
// Core providers
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
// Domain / Port providers
// ---------------------------------------------------------------------------

/// StoreStorage provider — asynchronously initialised from the file system.
/// Uses [FutureProvider] so the app can await readiness on first launch.
final storeStorageProvider = FutureProvider<StoreStorage>((ref) async {
  return FileStoreStorage.create();
});

/// AuthRepository provider.
/// Replace [StubAuthRepository] with a concrete provider adapter after ADR 0002.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = StubAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// SyncEngine provider.
/// Replace [StubSyncEngine] with a real implementation after ADR 0002 and sync ADR.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = StubSyncEngine();
  ref.onDispose(engine.dispose);
  return engine;
});

// ---------------------------------------------------------------------------
// Platform service providers
// ---------------------------------------------------------------------------

/// AdService provider — no-op until ADR 0003 is accepted.
final adServiceProvider = Provider<AdService>((ref) {
  return const NoOpAdService();
});

/// AnalyticsService provider — no-op until analytics ADR is accepted.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const NoOpAnalyticsService();
});
