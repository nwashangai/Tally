/// Value object representing current inventory levels for an Item.
///
/// **Domain Principle**:
/// The Item entity reflects current aggregate stock quantity.
/// Adjustments to this quantity in production occur via stock movement events
/// (Receiving, Sale, Audit Variance Adjustment), not arbitrary ad-hoc mutations.
class ItemInventory {
  final double quantity;
  final double? reorderLevel;

  ItemInventory({
    required this.quantity,
    this.reorderLevel,
  }) {
    if (reorderLevel != null && reorderLevel! < 0) {
      throw ArgumentError.value(
        reorderLevel,
        'reorderLevel',
        'Reorder level cannot be negative.',
      );
    }
  }

  /// Whether the item has 0 or negative stock.
  bool get isOutOfStock => quantity <= 0;

  /// Whether the item stock is positive but at or below the reorder threshold.
  bool get isLowStock =>
      reorderLevel != null && quantity > 0 && quantity <= reorderLevel!;

  /// Whether the item has healthy stock above reorder level.
  bool get isInStock =>
      quantity > 0 && (reorderLevel == null || quantity > reorderLevel!);

  ItemInventory copyWith({
    double? quantity,
    double? reorderLevel,
    bool clearReorderLevel = false,
  }) {
    return ItemInventory(
      quantity: quantity ?? this.quantity,
      reorderLevel:
          clearReorderLevel ? null : (reorderLevel ?? this.reorderLevel),
    );
  }

  Map<String, Object?> toJson() => {
        'quantity': quantity,
        'reorderLevel': reorderLevel,
      };

  factory ItemInventory.fromJson(Map<String, Object?> json) {
    return ItemInventory(
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemInventory &&
          runtimeType == other.runtimeType &&
          quantity == other.quantity &&
          reorderLevel == other.reorderLevel;

  @override
  int get hashCode => Object.hash(quantity, reorderLevel);

  @override
  String toString() => 'ItemInventory(qty: $quantity, reorder: $reorderLevel)';
}
