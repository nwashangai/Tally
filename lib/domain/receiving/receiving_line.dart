import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../item/item_id.dart';
import 'receiving_id.dart';

/// Immutable line item in a Receiving transaction.
/// Preserves the historical acquisition snapshot of the item, along with optional
/// selling price updates specified during stock intake.
class ReceivingLine extends Equatable {
  final String id;
  final ReceivingId receivingId;
  final ItemId itemId;
  final String itemNameSnapshot;
  final String? skuSnapshot;
  final String unitSnapshot;
  final double quantity;
  final double unitCost;
  final double lineTotal;
  final double? newBaseSellingPrice;
  final double? newMinSellingPrice;
  final bool updateItemCost;
  final bool updateItemPrice;

  ReceivingLine({
    String? id,
    required this.receivingId,
    required this.itemId,
    required this.itemNameSnapshot,
    this.skuSnapshot,
    required this.unitSnapshot,
    required this.quantity,
    required this.unitCost,
    double? lineTotal,
    this.newBaseSellingPrice,
    this.newMinSellingPrice,
    this.updateItemCost = false,
    this.updateItemPrice = false,
  })  : id = id ?? const Uuid().v4(),
        lineTotal = lineTotal ?? (quantity * unitCost) {
    if (quantity <= 0) {
      throw ArgumentError('Receiving line quantity must be greater than zero.');
    }
    if (unitCost < 0) {
      throw ArgumentError('Receiving line unit cost cannot be negative.');
    }
    if (newBaseSellingPrice != null && newBaseSellingPrice! < 0) {
      throw ArgumentError('New base selling price cannot be negative.');
    }
    if (newMinSellingPrice != null) {
      if (newMinSellingPrice! < 0) {
        throw ArgumentError('New minimum selling price cannot be negative.');
      }
      if (newBaseSellingPrice != null &&
          newMinSellingPrice! > newBaseSellingPrice!) {
        throw ArgumentError(
          'New minimum selling price ($newMinSellingPrice) cannot exceed new base selling price ($newBaseSellingPrice).',
        );
      }
    }
  }

  /// Computed profit margin per unit if a new base selling price was specified.
  double? get margin =>
      newBaseSellingPrice != null ? newBaseSellingPrice! - unitCost : null;

  /// Computed markup percentage relative to receiving unit cost.
  double? get markupPercentage {
    if (newBaseSellingPrice == null || unitCost <= 0) return null;
    return ((newBaseSellingPrice! - unitCost) / unitCost) * 100.0;
  }

  ReceivingLine copyWith({
    String? id,
    ReceivingId? receivingId,
    ItemId? itemId,
    String? itemNameSnapshot,
    String? skuSnapshot,
    String? unitSnapshot,
    double? quantity,
    double? unitCost,
    double? lineTotal,
    double? newBaseSellingPrice,
    bool clearBaseSellingPrice = false,
    double? newMinSellingPrice,
    bool clearMinSellingPrice = false,
    bool? updateItemCost,
    bool? updateItemPrice,
  }) {
    final nextQty = quantity ?? this.quantity;
    final nextCost = unitCost ?? this.unitCost;
    return ReceivingLine(
      id: id ?? this.id,
      receivingId: receivingId ?? this.receivingId,
      itemId: itemId ?? this.itemId,
      itemNameSnapshot: itemNameSnapshot ?? this.itemNameSnapshot,
      skuSnapshot: skuSnapshot ?? this.skuSnapshot,
      unitSnapshot: unitSnapshot ?? this.unitSnapshot,
      quantity: nextQty,
      unitCost: nextCost,
      lineTotal: lineTotal ?? (nextQty * nextCost),
      newBaseSellingPrice: clearBaseSellingPrice
          ? null
          : (newBaseSellingPrice ?? this.newBaseSellingPrice),
      newMinSellingPrice: clearMinSellingPrice
          ? null
          : (newMinSellingPrice ?? this.newMinSellingPrice),
      updateItemCost: updateItemCost ?? this.updateItemCost,
      updateItemPrice: updateItemPrice ?? this.updateItemPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receivingId': receivingId.value,
      'itemId': itemId.value,
      'itemNameSnapshot': itemNameSnapshot,
      'skuSnapshot': skuSnapshot,
      'unitSnapshot': unitSnapshot,
      'quantity': quantity,
      'unitCost': unitCost,
      'lineTotal': lineTotal,
      'newBaseSellingPrice': newBaseSellingPrice,
      'newMinSellingPrice': newMinSellingPrice,
      'updateItemCost': updateItemCost,
      'updateItemPrice': updateItemPrice,
    };
  }

  factory ReceivingLine.fromJson(Map<String, dynamic> json) {
    return ReceivingLine(
      id: json['id'] as String,
      receivingId: ReceivingId(json['receivingId'] as String),
      itemId: ItemId(json['itemId'] as String),
      itemNameSnapshot: json['itemNameSnapshot'] as String,
      skuSnapshot: json['skuSnapshot'] as String?,
      unitSnapshot: json['unitSnapshot'] as String? ?? 'unit',
      quantity: (json['quantity'] as num).toDouble(),
      unitCost: (json['unitCost'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
      newBaseSellingPrice: json['newBaseSellingPrice'] != null
          ? (json['newBaseSellingPrice'] as num).toDouble()
          : null,
      newMinSellingPrice: json['newMinSellingPrice'] != null
          ? (json['newMinSellingPrice'] as num).toDouble()
          : null,
      updateItemCost: json['updateItemCost'] as bool? ?? false,
      updateItemPrice: json['updateItemPrice'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        receivingId,
        itemId,
        itemNameSnapshot,
        skuSnapshot,
        unitSnapshot,
        quantity,
        unitCost,
        lineTotal,
        newBaseSellingPrice,
        newMinSellingPrice,
        updateItemCost,
        updateItemPrice,
      ];
}
