import 'package:flutter_test/flutter_test.dart';
import 'package:tally/infrastructure/store/in_memory_store_repository.dart';

void main() {
  group('InMemoryStoreRepository', () {
    late InMemoryStoreRepository repo;
    const userId = 'usr_123';

    setUp(() {
      repo = InMemoryStoreRepository();
    });

    test('starts with empty store list for user', () async {
      final result = await repo.getAccessibleStores(userId);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('createStore persists store with ownerId and valid ID', () async {
      final createResult = await repo.createStore(
        name: 'Downtown Warehouse',
        userId: userId,
      );

      expect(createResult.isSuccess, isTrue);
      final store = createResult.valueOrNull!;
      expect(store.name, 'Downtown Warehouse');
      expect(store.ownerId, userId);
      expect(store.id.value, startsWith('store_'));

      final listResult = await repo.getAccessibleStores(userId);
      expect(listResult.valueOrNull?.length, 1);
      expect(listResult.valueOrNull?.first.id, store.id);
    });

    test('isolates stores between different users', () async {
      await repo.createStore(name: 'User 1 Store', userId: 'user_1');
      await repo.createStore(name: 'User 2 Store', userId: 'user_2');

      final user1Stores = await repo.getAccessibleStores('user_1');
      final user2Stores = await repo.getAccessibleStores('user_2');

      expect(user1Stores.valueOrNull?.length, 1);
      expect(user1Stores.valueOrNull?.first.name, 'User 1 Store');
      expect(user2Stores.valueOrNull?.length, 1);
      expect(user2Stores.valueOrNull?.first.name, 'User 2 Store');
    });

    test('empty store name returns validation error', () async {
      final result = await repo.createStore(name: '   ', userId: userId);
      expect(result.isFailure, isTrue);
    });
  });
}
