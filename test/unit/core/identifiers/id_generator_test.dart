import 'package:flutter_test/flutter_test.dart';
import 'package:tally/core/identifiers/id_generator.dart';

void main() {
  group('UuidGenerator', () {
    late UuidGenerator generator;

    setUp(() => generator = const UuidGenerator());

    test('generates a non-empty string', () {
      expect(generator.generate(), isNotEmpty);
    });

    test('generates unique IDs on each call', () {
      final ids = List.generate(100, (_) => generator.generate()).toSet();
      expect(ids.length, 100);
    });

    test('generated id has UUID v4 format', () {
      final id = generator.generate();
      // UUID v4: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(uuidRegex.hasMatch(id), isTrue);
    });
  });
}
