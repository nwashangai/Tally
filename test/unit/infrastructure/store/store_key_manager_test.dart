import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/infrastructure/store/secure_storage_store_key_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('SecureStorageStoreKeyManager', () {
    late SecureStorageStoreKeyManager keyManager;
    const storeId1 = StoreId('store_alpha');
    const storeId2 = StoreId('store_beta');

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      keyManager = SecureStorageStoreKeyManager();
    });

    test('generates a stable 256-bit key per store', () async {
      final key1 = await keyManager.getOrCreateKey(storeId1);
      final key2 = await keyManager.getOrCreateKey(storeId1);

      expect(key1.isSuccess, isTrue);
      expect(key2.isSuccess, isTrue);
      expect(key1.valueOrNull, equals(key2.valueOrNull));
      expect(key1.valueOrNull!.length, greaterThanOrEqualTo(32));
    });

    test('generates different keys for different stores', () async {
      final key1 = await keyManager.getOrCreateKey(storeId1);
      final key2 = await keyManager.getOrCreateKey(storeId2);

      expect(key1.valueOrNull, isNot(equals(key2.valueOrNull)));
    });

    test('setKey overrides existing key and deleteKey removes it', () async {
      await keyManager.setKey(storeId1, 'custom_secret_key_123');
      final fetched = await keyManager.getKey(storeId1);
      expect(fetched.valueOrNull, 'custom_secret_key_123');

      await keyManager.deleteKey(storeId1);
      final afterDelete = await keyManager.getKey(storeId1);
      expect(afterDelete.valueOrNull, isNull);
    });
  });
}
