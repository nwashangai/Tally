/// Value object representing current pricing attributes of an Item.
///
/// **Domain Invariant (ADR 0012)**:
/// - When specified, `minSellingPrice` must be <= `baseSellingPrice`.
/// - `costPrice` and `baseSellingPrice` must be >= 0.
///
/// Note: These values represent the **current** pricing of the item.
/// Historical transaction costs (e.g. past Receivings or Sales) are recorded
/// in their respective transaction ledgers and are never overwritten by item pricing changes.
class ItemPricing {
  final double costPrice;
  final double baseSellingPrice;
  final double? minSellingPrice;

  ItemPricing({
    required this.costPrice,
    required this.baseSellingPrice,
    this.minSellingPrice,
  }) {
    if (costPrice < 0) {
      throw ArgumentError.value(
        costPrice,
        'costPrice',
        'Cost price cannot be negative.',
      );
    }
    if (baseSellingPrice < 0) {
      throw ArgumentError.value(
        baseSellingPrice,
        'baseSellingPrice',
        'Base selling price cannot be negative.',
      );
    }
    if (minSellingPrice != null) {
      if (minSellingPrice! < 0) {
        throw ArgumentError.value(
          minSellingPrice,
          'minSellingPrice',
          'Minimum selling price cannot be negative.',
        );
      }
      if (minSellingPrice! > baseSellingPrice) {
        throw ArgumentError(
          'Minimum selling price ($minSellingPrice) cannot exceed base selling price ($baseSellingPrice).',
        );
      }
    }
  }

  /// Computed profit margin per unit at base selling price.
  double get margin => baseSellingPrice - costPrice;

  /// Computed markup percentage relative to cost price.
  double get markupPercentage {
    if (costPrice <= 0) return 0.0;
    return ((baseSellingPrice - costPrice) / costPrice) * 100.0;
  }

  ItemPricing copyWith({
    double? costPrice,
    double? baseSellingPrice,
    double? minSellingPrice,
    bool clearMinSellingPrice = false,
  }) {
    return ItemPricing(
      costPrice: costPrice ?? this.costPrice,
      baseSellingPrice: baseSellingPrice ?? this.baseSellingPrice,
      minSellingPrice: clearMinSellingPrice
          ? null
          : (minSellingPrice ?? this.minSellingPrice),
    );
  }

  Map<String, Object?> toJson() => {
        'costPrice': costPrice,
        'baseSellingPrice': baseSellingPrice,
        'minSellingPrice': minSellingPrice,
      };

  factory ItemPricing.fromJson(Map<String, Object?> json) {
    return ItemPricing(
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
      baseSellingPrice: (json['baseSellingPrice'] as num?)?.toDouble() ?? 0.0,
      minSellingPrice: (json['minSellingPrice'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemPricing &&
          runtimeType == other.runtimeType &&
          costPrice == other.costPrice &&
          baseSellingPrice == other.baseSellingPrice &&
          minSellingPrice == other.minSellingPrice;

  @override
  int get hashCode => Object.hash(costPrice, baseSellingPrice, minSellingPrice);

  @override
  String toString() =>
      'ItemPricing(cost: $costPrice, base: $baseSellingPrice, min: $minSellingPrice)';
}
