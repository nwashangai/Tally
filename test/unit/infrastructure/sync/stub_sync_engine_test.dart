import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/sync/store_sync_state.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/sync/stub_sync_engine.dart';

void main() {
  group('StubSyncEngine', () {
    late StubSyncEngine engine;
    const storeId = StoreId('test-store');

    setUp(() => engine = StubSyncEngine());
    tearDown(() => engine.dispose());

    test('initial state is local', () {
      expect(engine.currentState(storeId).status, SyncStatus.local);
    });

    test('syncStore returns Success', () async {
      final result = await engine.syncStore(storeId);
      expect(result.isSuccess, isTrue);
    });

    test('pause and resume complete without error', () async {
      await expectLater(engine.pause(), completes);
      await expectLater(engine.resume(), completes);
    });
  });
}
