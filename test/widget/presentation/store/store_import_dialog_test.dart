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
import 'package:tally/domain/store/store_database_manager.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/in_memory_store_repository.dart';
import 'package:tally/presentation/store/widgets/store_import_dialog.dart';

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
    email: 'merchant@tally.app',
    displayName: 'Merchant User',
  );
  const testSession = AuthSession(
    token: 'token_123',
    user: testUser,
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStateAuthenticated(testSession)),
        ),
        storeRepositoryProvider.overrideWithValue(InMemoryStoreRepository()),
        storeListProvider.overrideWith((ref) {
          return StoreListNotifier(
            storeRepo: ref.watch(storeRepositoryProvider),
            dbManager: _FakeDbManager(),
          );
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: StoreImportDialog(),
        ),
      ),
    );
  }

  group('StoreImportDialog', () {
    testWidgets('renders local backup tab with file picker and text field',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Import Store Backup'), findsOneWidget);
      expect(find.text('Local Backup File'), findsOneWidget);
      expect(find.text('Online / Cloud Backup'), findsOneWidget);
      expect(find.text('Tap to select backup file'), findsOneWidget);
      expect(find.text('Store Name'), findsOneWidget);
      expect(find.text('Import Store'), findsOneWidget);
    });

    testWidgets('switches to online backup tab and displays coming soon info',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the Cloud Backup tab
      await tester.tap(find.text('Online / Cloud Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Cloud Backup & Sync'), findsOneWidget);
      expect(find.text('Coming Soon in next update'), findsOneWidget);
      expect(find.text('End-to-End Encrypted Snapshots'), findsOneWidget);
      expect(find.text('Multi-Device Instant Sync'), findsOneWidget);
      expect(find.text('Automated Daily Cloud Backups'), findsOneWidget);
    });
  });
}
