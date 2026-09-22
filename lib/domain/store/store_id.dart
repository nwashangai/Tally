/// Value object representing a unique Store identifier.
/// Guarantees type safety across store boundaries.
final class StoreId {
  final String value;

  const StoreId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StoreId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
