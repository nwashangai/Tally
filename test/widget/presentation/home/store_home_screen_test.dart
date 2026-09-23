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
import 'package:tally/presentation/home/store_home_screen.dart';

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
  group('StoreHomeScreen', () {
    testWidgets('renders store header banner and module menu cards',
        (tester) async {
      final store = Store(
        id: const StoreId('store-100'),
        name: 'Chiagoziems Boutique',
        ownerId: 'user-1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentStoreProvider.overrideWith(
              (ref) => _FakeCurrentStoreNotifier(
                StoreSelected(
                  store: store,
                  dbPath: '/data/tally/store-100.db',
                  syncStatus: SyncStatus.local,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: StoreHomeScreen(),
          ),
        ),
      );

      expect(find.text('Chiagoziems Boutique'), findsOneWidget);
      expect(find.text('Encrypted Local DB'), findsOneWidget);
      expect(find.text('Config'), findsOneWidget);

      // Verify all menu module cards render
      expect(find.text('Sales'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
      expect(find.text('Receivings'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
