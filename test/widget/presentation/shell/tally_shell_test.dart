import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/application/auth/auth_state_provider.dart';
import 'package:tally/application/store/current_store_notifier.dart';
import 'package:tally/application/store/current_store_state.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/auth/auth_session.dart';
import 'package:tally/domain/auth/auth_state.dart';
import 'package:tally/domain/auth/user.dart';
import 'package:tally/domain/store/remote_store_database_metadata.dart';
import 'package:tally/domain/store/remote_store_database_repository.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/domain/sync/store_sync_state.dart';
import 'package:tally/presentation/shell/tally_shell.dart';

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
  _FakeCurrentStoreNotifier(
    CurrentStoreState initialState,
  ) : super(
          dbManager: _FakeDbManager(),
          remoteDbRepo: _FakeRemoteDbRepo(),
        ) {
    state = initialState;
  }
}

void main() {
  const testUser = User(
    id: 'user-1',
    email: 'manager@example.com',
    displayName: 'Store Manager',
  );
  const testSession = AuthSession(token: 'test-token', user: testUser);

  final testStore = Store(
    id: const StoreId('store-1'),
    name: 'Main Warehouse',
    ownerId: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Widget createSubject({required CurrentStoreState storeState}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStateAuthenticated(testSession)),
        ),
        currentStoreProvider.overrideWith(
          (ref) => _FakeCurrentStoreNotifier(storeState),
        ),
      ],
      child: const MaterialApp(
        home: TallyShell(),
      ),
    );
  }

  group('TallyShell', () {
    testWidgets('renders active store and navigation destinations',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          storeState: StoreSelected(
            store: testStore,
            dbPath: '/documents/tally/stores/store-1.db',
            syncStatus: SyncStatus.local,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Main Warehouse'), findsAtLeastNWidgets(1));
      expect(find.text('Overview'), findsAtLeastNWidgets(1));
      expect(find.text('Sales'), findsAtLeastNWidgets(1));
      expect(find.text('Items'), findsAtLeastNWidgets(1));
      expect(find.text('Receivings'), findsAtLeastNWidgets(1));
      expect(find.text('Reports'), findsAtLeastNWidgets(1));
      expect(find.text('Settings'), findsAtLeastNWidgets(1));
    });

    testWidgets('switching navigation destination mounts corresponding module',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          storeState: StoreSelected(
            store: testStore,
            dbPath: '/documents/tally/stores/store-1.db',
            syncStatus: SyncStatus.local,
          ),
        ),
      );
      await tester.pump();

      // Tap on Sales tab
      await tester.tap(find.text('Sales').first);
      await tester.pumpAndSettle();

      expect(find.text('Sales & Register'), findsOneWidget);

      // Tap on Items tab
      await tester.tap(find.text('Items').first);
      await tester.pumpAndSettle();

      expect(find.text('Items & Inventory'), findsOneWidget);
    });

    testWidgets('shows loading indicator when no store is selected',
        (tester) async {
      await tester.pumpWidget(
        createSubject(
          storeState: const NoStoreSelected(),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
