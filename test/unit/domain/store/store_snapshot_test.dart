import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/domain/store/store_snapshot.dart';

void main() {
  group('StoreSnapshot', () {
    const storeId = StoreId('test-store-001');

    test('create() computes checksum', () {
      final snapshot = StoreSnapshot.create(
        storeId: storeId,
        revision: 1,
        generatedAt: DateTime.utc(2026, 9, 1),
        data: {'items': []},
      );
      expect(snapshot.checksum, isNotEmpty);
    });

    test('verifyIntegrity() returns true for unmodified snapshot', () {
      final snapshot = StoreSnapshot.create(
        storeId: storeId,
        revision: 1,
        generatedAt: DateTime.utc(2026, 9, 1),
        data: {'items': []},
      );
      expect(snapshot.verifyIntegrity(), isTrue);
    });

    test('roundtrip via toJson/fromJson preserves all fields', () {
      final original = StoreSnapshot.create(
        storeId: storeId,
        revision: 5,
        generatedAt: DateTime.utc(2026, 9, 1, 12),
        data: {'key': 'value', 'count': 42},
      );

      final json = original.toJson();
      final restored = StoreSnapshot.fromJson(json);

      expect(restored.storeId, original.storeId);
      expect(restored.revision, original.revision);
      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.checksum, original.checksum);
    });

    test('fromJson snapshot passes integrity check', () {
      final original = StoreSnapshot.create(
        storeId: storeId,
        revision: 1,
        generatedAt: DateTime.utc(2026),
        data: {'x': 1},
      );
      final restored = StoreSnapshot.fromJson(original.toJson());
      expect(restored.verifyIntegrity(), isTrue);
    });

    test('stores have schema version', () {
      final snapshot = StoreSnapshot.create(
        storeId: storeId,
        revision: 1,
        generatedAt: DateTime.utc(2026),
        data: {},
      );
      expect(
          snapshot.schemaVersion, equals(StoreSnapshot.currentSchemaVersion));
    });
  });

  group('StoreId', () {
    test('equality by value', () {
      expect(const StoreId('a'), equals(const StoreId('a')));
      expect(const StoreId('a'), isNot(equals(const StoreId('b'))));
    });

    test('toString returns value', () {
      expect(const StoreId('my-store').toString(), 'my-store');
    });
  });
}
