import 'store_id.dart';

/// Metadata entity describing a user's store.
final class StoreMetadata {
  final StoreId id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String currencyCode;

  const StoreMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.currencyCode = 'USD',
  });

  StoreMetadata copyWith({
    StoreId? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currencyCode,
  }) {
    return StoreMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'currencyCode': currencyCode,
      };

  factory StoreMetadata.fromJson(Map<String, Object?> json) {
    return StoreMetadata(
      id: StoreId(json['id'] as String),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      currencyCode: (json['currencyCode'] as String?) ?? 'USD',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoreMetadata &&
          other.id == id &&
          other.name == name &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.currencyCode == currencyCode);

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt, currencyCode);

  @override
  String toString() => 'StoreMetadata(id: $id, name: $name)';
}
