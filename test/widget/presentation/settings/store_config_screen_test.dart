import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/application/store/current_store_notifier.dart';
import 'package:tally/application/store/current_store_state.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/store/remote_store_database_metadata.dart';
import 'package:tally/domain/store/remote_store_database_repository.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/domain/sync/store_sync_state.dart';
import 'package:tally/presentation/settings/store_config_screen.dart';

class _FakeDbManager implements StoreDatabaseManager {
  @override
  Future<Result<void>> create(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> open(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> close(StoreId storeId) async => const Success(null);
  @override
  Future<Result<void>> checkpoint(StoreId storeId) async => const Success(null);
  @override
  Future<Result<bool>> exists(StoreId storeId) async => const Success(true);
  @override
  Future<Result<String>> getDatabaseFilePath(StoreId storeId) async =>
      Success('/test/${storeId.value}.db');
  @override
  Future<Result<bool>> validateIntegrity(StoreId storeId) async =>
      const Success(true);
  @override
  Future<Result<void>> delete(StoreId storeId) async => const Success(null);
}

class _FakeRemoteDbRepo implements RemoteStoreDatabaseRepository {
  @override
  Future<Result<RemoteStoreDatabaseMetadata?>> getMetadata(
          StoreId storeId) async =>
      const Success(null);

  @override
  Future<Result<void>> upload({
    required StoreId storeId,
    required String localFilePath,
    required int revision,
  }) async =>
      const Success(null);

  @override
  Future<Result<void>> download({
    required StoreId storeId,
    required String destinationFilePath,
  }) async =>
      const Success(null);
}

class _FakeCurrentStoreNotifier extends CurrentStoreNotifier {
  _FakeCurrentStoreNotifier(CurrentStoreState initialState)
      : super(
          dbManager: _FakeDbManager(),
          remoteDbRepo: _FakeRemoteDbRepo(),
        ) {
    state = initialState;
  }
}

void main() {
  group('StoreConfigScreen', () {
    testWidgets('renders database metadata and maintenance actions',
        (tester) async {
      final store = Store(
        id: const StoreId('store-200'),
        name: 'Downtown Mart',
        ownerId: 'user-1',
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeDatabaseManagerProvider
                .overrideWith((ref) => Future.value(_FakeDbManager())),
            currentStoreProvider.overrideWith(
              (ref) => _FakeCurrentStoreNotifier(
                StoreSelected(
                  store: store,
                  dbPath: '/data/tally/store-200.db',
                  syncStatus: SyncStatus.local,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: StoreConfigScreen(),
          ),
        ),
      );

      expect(find.text('Store Database & Config'), findsWidgets);
      expect(find.text('Downtown Mart'), findsOneWidget);
      expect(find.text('/data/tally/store-200.db'), findsOneWidget);
      expect(find.text('SQLCipher AES-256 (Key in Secure Storage)'),
          findsOneWidget);
      expect(find.text('Verify Database Integrity'), findsOneWidget);
      expect(find.text('Run WAL Checkpoint'), findsOneWidget);
      expect(find.text('Export Store Database (.db)'), findsOneWidget);
    });
  });
}
