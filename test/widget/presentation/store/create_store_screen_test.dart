import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/application/auth/auth_state_provider.dart';
import 'package:tally/application/store/current_store_notifier.dart';
import 'package:tally/application/store/store_list_notifier.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/auth/auth_session.dart';
import 'package:tally/domain/auth/auth_state.dart';
import 'package:tally/domain/auth/user.dart';
import 'package:tally/domain/store/remote_store_database_metadata.dart';
import 'package:tally/domain/store/remote_store_database_repository.dart';
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/in_memory_store_repository.dart';
import 'package:tally/presentation/store/create_store_screen.dart';

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

void main() {
  const testUser = User(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );
  const testSession = AuthSession(token: 'token-abc', user: testUser);

  Widget createSubject({required InMemoryStoreRepository storeRepo}) {
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (_, __) => const CreateStoreScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStateAuthenticated(testSession)),
        ),
        storeRepositoryProvider.overrideWithValue(storeRepo),
        storeListProvider.overrideWith((ref) {
          final notifier = StoreListNotifier(
            storeRepo: storeRepo,
            dbManager: _FakeDbManager(),
          );
          return notifier;
        }),
        currentStoreProvider.overrideWith((ref) {
          return CurrentStoreNotifier(
            dbManager: _FakeDbManager(),
            remoteDbRepo: _FakeRemoteDbRepo(),
          );
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('CreateStoreScreen', () {
    testWidgets('renders all fields and creates store with valid input',
        (tester) async {
      final storeRepo = InMemoryStoreRepository();

      await tester.pumpWidget(createSubject(storeRepo: storeRepo));
      await tester.pumpAndSettle();

      expect(find.text('Create New Store'), findsOneWidget);
      expect(find.text('Create & Open Store'), findsOneWidget);

      final submitFinder =
          find.widgetWithText(ElevatedButton, 'Create & Open Store');

      // Attempt to submit empty
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a store name'), findsOneWidget);

      // Enter valid name
      await tester.enterText(
        find.byType(TextFormField),
        'Warehouse A',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Verify store was saved in repository
      final storesRes = await storeRepo.getAccessibleStores('user-123');
      expect(storesRes.isSuccess, isTrue);
      expect(storesRes.valueOrNull!.length, equals(1));
      expect(storesRes.valueOrNull!.first.name, equals('Warehouse A'));
      expect(storesRes.valueOrNull!.first.ownerId, equals('user-123'));

      // Should have navigated to /home
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
