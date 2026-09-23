import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/application/auth/auth_state_provider.dart';
import 'package:tally/application/store/store_list_notifier.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/auth/auth_session.dart';
import 'package:tally/domain/auth/auth_state.dart';
import 'package:tally/domain/auth/user.dart';
import 'package:tally/domain/store/store.dart';
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/in_memory_store_repository.dart';
import 'package:tally/presentation/store/store_selection_screen.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  const testUser = User(
    id: 'test_user_001',
    email: 'test@tally.app',
    displayName: 'Test Merchant',
  );
  const testSession = AuthSession(
    token: 'token_123',
    user: testUser,
  );

  group('StoreSelectionScreen', () {
    testWidgets('renders empty view when user has no stores', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStateAuthenticated(testSession)),
            ),
            storeRepositoryProvider
                .overrideWithValue(InMemoryStoreRepository()),
            storeListProvider.overrideWith((ref) {
              final notifier = StoreListNotifier(
                storeRepo: ref.watch(storeRepositoryProvider),
                dbManager: _FakeDbManager(),
              );
              notifier.loadStores('test_user_001');
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: StoreSelectionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("You don't have a store yet"), findsOneWidget);
      expect(find.text('Create Store'), findsOneWidget);
    });

    testWidgets('renders store cards when stores exist', (tester) async {
      final store1 = Store(
        id: const StoreId('store_01'),
        name: 'Main Street Grocery',
        ownerId: 'test_user_001',
        createdAt: DateTime.utc(2026, 9, 1),
        updatedAt: DateTime.utc(2026, 9, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStateAuthenticated(testSession)),
            ),
            storeRepositoryProvider.overrideWithValue(
              InMemoryStoreRepository(initialStores: [store1]),
            ),
            storeListProvider.overrideWith((ref) {
              final notifier = StoreListNotifier(
                storeRepo: ref.watch(storeRepositoryProvider),
                dbManager: _FakeDbManager(),
              );
              notifier.loadStores('test_user_001');
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: StoreSelectionScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Main Street Grocery'), findsOneWidget);
    });
  });
}
