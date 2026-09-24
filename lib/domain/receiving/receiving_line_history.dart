import 'package:equatable/equatable.dart';
import 'receiving_id.dart';

/// Historical receiving activity record for an item.
/// Immutable snapshot of past acquisition cost, selling price, quantity, and date.
class ReceivingLineHistory extends Equatable {
  final ReceivingId receivingId;
  final String referenceNumber;
  final DateTime receivedAt;
  final String? supplier;
  final double quantity;
  final double unitCost;
  final double lineTotal;
  final double? newBaseSellingPrice;
  final String unitSnapshot;

  const ReceivingLineHistory({
    required this.receivingId,
    required this.referenceNumber,
    required this.receivedAt,
    this.supplier,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.newBaseSellingPrice,
    required this.unitSnapshot,
  });

  @override
  List<Object?> get props => [
        receivingId,
        referenceNumber,
        receivedAt,
        supplier,
        quantity,
        unitCost,
        lineTotal,
        newBaseSellingPrice,
        unitSnapshot,
      ];
}
