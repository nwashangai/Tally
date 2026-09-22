import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'store_id.dart';

/// Immutable, versioned snapshot of a complete store data boundary.
/// Designed for atomic file persistence, backup, restoration, and sync.
final class StoreSnapshot {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final StoreId storeId;
  final int revision;
  final DateTime generatedAt;
  final String checksum;
  final Map<String, Object?> data;

  const StoreSnapshot({
    required this.schemaVersion,
    required this.storeId,
    required this.revision,
    required this.generatedAt,
    required this.checksum,
    required this.data,
  });

  /// Factory that automatically computes the SHA-256 checksum over the payload.
  factory StoreSnapshot.create({
    required StoreId storeId,
    required int revision,
    required DateTime generatedAt,
    required Map<String, Object?> data,
    int schemaVersion = currentSchemaVersion,
  }) {
    final payloadJson = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(payloadJson)).toString();

    return StoreSnapshot(
      schemaVersion: schemaVersion,
      storeId: storeId,
      revision: revision,
      generatedAt: generatedAt,
      checksum: checksum,
      data: data,
    );
  }

  /// Verifies whether the payload matches the recorded checksum.
  bool verifyIntegrity() {
    final payloadJson = jsonEncode(data);
    final calculated = sha256.convert(utf8.encode(payloadJson)).toString();
    return calculated == checksum;
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'storeId': storeId.value,
        'revision': revision,
        'generatedAt': generatedAt.toIso8601String(),
        'checksum': checksum,
        'data': data,
      };

  factory StoreSnapshot.fromJson(Map<String, Object?> json) {
    return StoreSnapshot(
      schemaVersion: json['schemaVersion'] as int,
      storeId: StoreId(json['storeId'] as String),
      revision: json['revision'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      checksum: json['checksum'] as String,
      data: (json['data'] as Map<String, Object?>?) ?? <String, Object?>{},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreSnapshot &&
          other.schemaVersion == schemaVersion &&
          other.storeId == storeId &&
          other.revision == revision &&
          other.generatedAt == generatedAt &&
          other.checksum == checksum);

  @override
  int get hashCode =>
      Object.hash(schemaVersion, storeId, revision, generatedAt, checksum);

  @override
  String toString() =>
      'StoreSnapshot(storeId: $storeId, rev: $revision, v: $schemaVersion)';
}
