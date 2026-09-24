import 'package:equatable/equatable.dart';
import '../store/store_id.dart';
import 'receiving_id.dart';
import 'receiving_line.dart';
import 'receiving_status.dart';

/// Root aggregate representing an inventory Receiving transaction.
/// Records stock entering the store from a supplier or other source.
class Receiving extends Equatable {
  final ReceivingId id;
  final StoreId storeId;
  final String referenceNumber;
  final DateTime receivedAt;
  final String? supplier;
  final String? notes;
  final ReceivingStatus status;
  final double totalCost;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ReceivingLine> lines;

  Receiving({
    ReceivingId? id,
    required this.storeId,
    required this.referenceNumber,
    DateTime? receivedAt,
    this.supplier,
    this.notes,
    this.status = ReceivingStatus.draft,
    double? totalCost,
    this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReceivingLine>? lines,
  })  : id = id ?? ReceivingId.generate(),
        receivedAt = receivedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lines = List.unmodifiable(lines ?? const []),
        totalCost = totalCost ??
            (lines ?? const [])
                .fold<double>(0.0, (sum, line) => sum + line.lineTotal) {
    if (referenceNumber.trim().isEmpty) {
      throw ArgumentError('Receiving reference number cannot be empty.');
    }
    if (status == ReceivingStatus.completed && this.lines.isEmpty) {
      throw ArgumentError(
        'A completed receiving transaction must have at least one line item.',
      );
    }
    // Verify no duplicate item IDs
    final itemIds = <String>{};
    for (final line in this.lines) {
      if (!itemIds.add(line.itemId.value)) {
        throw ArgumentError(
          'Duplicate item "${line.itemNameSnapshot}" in receiving transaction.',
        );
      }
    }
  }

  /// Total count of distinct items in this receiving.
  int get itemCount => lines.length;

  /// Total sum of all line quantities.
  double get totalQuantity =>
      lines.fold<double>(0.0, (sum, line) => sum + line.quantity);

  bool get isDraft => status.isDraft;
  bool get isCompleted => status.isCompleted;
  bool get isVoided => status.isVoided;

  Receiving copyWith({
    ReceivingId? id,
    StoreId? storeId,
    String? referenceNumber,
    DateTime? receivedAt,
    String? supplier,
    String? notes,
    ReceivingStatus? status,
    double? totalCost,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ReceivingLine>? lines,
  }) {
    final nextLines = lines ?? this.lines;
    return Receiving(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      receivedAt: receivedAt ?? this.receivedAt,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalCost: totalCost ??
          nextLines.fold<double>(0.0, (sum, line) => sum + line.lineTotal),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lines: nextLines,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.value,
      'storeId': storeId.value,
      'referenceNumber': referenceNumber,
      'receivedAt': receivedAt.toUtc().toIso8601String(),
      'supplier': supplier,
      'notes': notes,
      'status': status.value,
      'totalCost': totalCost,
      'createdBy': createdBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'lines': lines.map((l) => l.toJson()).toList(),
    };
  }

  factory Receiving.fromJson(Map<String, dynamic> json) {
    final linesList = (json['lines'] as List<dynamic>?)
            ?.map((e) => ReceivingLine.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return Receiving(
      id: ReceivingId(json['id'] as String),
      storeId: StoreId(json['storeId'] as String),
      referenceNumber: json['referenceNumber'] as String,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      supplier: json['supplier'] as String?,
      notes: json['notes'] as String?,
      status: ReceivingStatus.fromValue(json['status'] as String),
      totalCost: (json['totalCost'] as num).toDouble(),
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lines: linesList,
    );
  }

  @override
  List<Object?> get props => [
        id,
        storeId,
        referenceNumber,
        receivedAt,
        supplier,
        notes,
        status,
        totalCost,
        createdBy,
        createdAt,
        updatedAt,
        lines,
      ];
}
