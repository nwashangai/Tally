import 'store_id.dart';

/// Pure domain entity representing a Tally store.
/// Contains store identity and metadata, but NOT the store's inventory records.
class Store {
  final StoreId id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;

  const Store({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.revision = 1,
  });

  Store copyWith({
    StoreId? id,
    String? name,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? revision,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      revision: revision ?? this.revision,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id.value,
        'name': name,
        'ownerId': ownerId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'revision': revision,
      };

  factory Store.fromJson(Map<String, Object?> json) {
    return Store(
      id: StoreId(json['id']! as String),
      name: json['name']! as String,
      ownerId: json['ownerId']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Store &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ownerId == other.ownerId &&
          revision == other.revision;

  @override
  int get hashCode => Object.hash(id, name, ownerId, revision);

  @override
  String toString() =>
      'Store(id: ${id.value}, name: $name, owner: $ownerId, rev: $revision)';
}
