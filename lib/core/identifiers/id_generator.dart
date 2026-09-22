import 'package:uuid/uuid.dart';

/// Abstract port for generating unique, stable identifiers.
abstract interface class IdGenerator {
  /// Generates a globally unique identifier (e.g., UUID v4).
  String generate();
}

/// Production implementation using standard UUID v4.
class UuidGenerator implements IdGenerator {
  static const _uuid = Uuid();

  const UuidGenerator();

  @override
  String generate() => _uuid.v4();
}
