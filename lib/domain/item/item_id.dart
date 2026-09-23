/// Value object representing a unique Item identifier.
/// Guarantees type safety across store inventory boundaries.
final class ItemId {
  final String value;

  const ItemId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ItemId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
