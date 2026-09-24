import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/app_error.dart';
import '../../core/result/result.dart';
import '../../domain/item/item.dart';
import '../../domain/receiving/receiving.dart';
import '../../domain/receiving/receiving_id.dart';
import '../../domain/receiving/receiving_line.dart';
import '../../domain/receiving/receiving_repository.dart';
import '../../domain/receiving/receiving_status.dart';
import '../../domain/store/store_id.dart';

/// Form and draft state for creating a new Receiving transaction.
class CreateReceivingState extends Equatable {
  final ReceivingId receivingId;
  final String referenceNumber;
  final DateTime receivedAt;
  final String supplier;
  final String notes;
  final List<ReceivingLine> lines;
  final bool isSaving;
  final String? errorMessage;

  const CreateReceivingState({
    required this.receivingId,
    required this.referenceNumber,
    required this.receivedAt,
    this.supplier = '',
    this.notes = '',
    this.lines = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  double get totalCost =>
      lines.fold<double>(0.0, (sum, line) => sum + line.lineTotal);

  double get totalQuantity =>
      lines.fold<double>(0.0, (sum, line) => sum + line.quantity);

  int get itemCount => lines.length;

  bool get isValid =>
      referenceNumber.trim().isNotEmpty &&
      lines.isNotEmpty &&
      lines.every((l) =>
          l.quantity > 0 &&
          l.unitCost >= 0 &&
          (l.newBaseSellingPrice == null || l.newBaseSellingPrice! >= 0) &&
          (l.newMinSellingPrice == null ||
              (l.newMinSellingPrice! >= 0 &&
                  (l.newBaseSellingPrice == null ||
                      l.newMinSellingPrice! <= l.newBaseSellingPrice!))));

  CreateReceivingState copyWith({
    ReceivingId? receivingId,
    String? referenceNumber,
    DateTime? receivedAt,
    String? supplier,
    String? notes,
    List<ReceivingLine>? lines,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateReceivingState(
      receivingId: receivingId ?? this.receivingId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      receivedAt: receivedAt ?? this.receivedAt,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      lines: lines ?? this.lines,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        receivingId,
        referenceNumber,
        receivedAt,
        supplier,
        notes,
        lines,
        isSaving,
        errorMessage,
      ];
}

/// State notifier managing creation of a new Receiving transaction.
class CreateReceivingNotifier extends StateNotifier<CreateReceivingState> {
  final ReceivingRepository _repository;
  final StoreId _storeId;

  CreateReceivingNotifier({
    required ReceivingRepository repository,
    required StoreId storeId,
  })  : _repository = repository,
        _storeId = storeId,
        super(
          CreateReceivingState(
            receivingId: ReceivingId.generate(),
            referenceNumber: '',
            receivedAt: DateTime.now(),
          ),
        ) {
    _initializeReference();
  }

  Future<void> _initializeReference() async {
    final refRes = await _repository.getNextReferenceNumber();
    if (refRes.isSuccess && mounted) {
      state = state.copyWith(referenceNumber: refRes.valueOrNull!);
    }
  }

  void setReference(String ref) {
    state = state.copyWith(referenceNumber: ref, clearError: true);
  }

  void setReceivedAt(DateTime dt) {
    state = state.copyWith(receivedAt: dt);
  }

  void setSupplier(String s) {
    state = state.copyWith(supplier: s);
  }

  void setNotes(String n) {
    state = state.copyWith(notes: n);
  }

  void addItem(
    Item item, {
    double quantity = 1,
    double? unitCost,
    bool updateItemCost = false,
    double? newBaseSellingPrice,
    double? newMinSellingPrice,
    bool updateItemPrice = false,
  }) {
    final existingIndex =
        state.lines.indexWhere((l) => l.itemId.value == item.id.value);

    final resolvedCost = unitCost ?? item.pricing.costPrice;
    final resolvedBaseSelling =
        newBaseSellingPrice ?? item.pricing.baseSellingPrice;
    final resolvedMinSelling =
        newMinSellingPrice ?? item.pricing.minSellingPrice;

    if (existingIndex >= 0) {
      // Merge with existing line: increase quantity
      final existing = state.lines[existingIndex];
      final updated = existing.copyWith(
        quantity: existing.quantity + quantity,
        unitCost: resolvedCost,
        updateItemCost: updateItemCost,
        newBaseSellingPrice: resolvedBaseSelling,
        newMinSellingPrice: resolvedMinSelling,
        updateItemPrice: updateItemPrice,
      );
      final nextLines = List<ReceivingLine>.from(state.lines);
      nextLines[existingIndex] = updated;
      state = state.copyWith(lines: nextLines, clearError: true);
    } else {
      // Add new line item
      final newLine = ReceivingLine(
        receivingId: state.receivingId,
        itemId: item.id,
        itemNameSnapshot: item.name,
        skuSnapshot: item.sku,
        unitSnapshot: item.unit.value,
        quantity: quantity,
        unitCost: resolvedCost,
        updateItemCost: updateItemCost,
        newBaseSellingPrice: resolvedBaseSelling,
        newMinSellingPrice: resolvedMinSelling,
        updateItemPrice: updateItemPrice,
      );
      state = state.copyWith(
        lines: [...state.lines, newLine],
        clearError: true,
      );
    }
  }

  void updateQuantity(String lineId, double quantity) {
    if (quantity <= 0) return;
    final nextLines = state.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(quantity: quantity);
      }
      return l;
    }).toList();
    state = state.copyWith(lines: nextLines, clearError: true);
  }

  void updateUnitCost(String lineId, double unitCost) {
    if (unitCost < 0) return;
    final nextLines = state.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(unitCost: unitCost);
      }
      return l;
    }).toList();
    state = state.copyWith(lines: nextLines, clearError: true);
  }

  void updateBaseSellingPrice(String lineId, double? price) {
    if (price != null && price < 0) return;
    final nextLines = state.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(newBaseSellingPrice: price);
      }
      return l;
    }).toList();
    state = state.copyWith(lines: nextLines, clearError: true);
  }

  void updateMinSellingPrice(String lineId, double? minPrice) {
    if (minPrice != null && minPrice < 0) return;
    final nextLines = state.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(newMinSellingPrice: minPrice);
      }
      return l;
    }).toList();
    state = state.copyWith(lines: nextLines, clearError: true);
  }

  void toggleUpdateItemCost(String lineId, bool update) {
    final nextLines = state.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(updateItemCost: update);
      }
      return l;
    }).toList();
    state = state.copyWith(lines: nextLines);
  }

  void toggleUpdateItemPrice(String lineId, bool update) {
    final nextLines = state.lines.map((l) {
      if (l.id == lineId) {
        return l.copyWith(updateItemPrice: update);
      }
      return l;
    }).toList();
    state = state.copyWith(lines: nextLines);
  }

  void removeLine(String lineId) {
    final nextLines = state.lines.where((l) => l.id != lineId).toList();
    state = state.copyWith(lines: nextLines, clearError: true);
  }

  Future<Result<Receiving>> submit({
    bool markCompleted = true,
    String? createdBy,
  }) async {
    if (state.referenceNumber.trim().isEmpty) {
      const err = 'Reference number is required.';
      state = state.copyWith(errorMessage: err);
      return const Failure(ValidationError(err, field: 'referenceNumber'));
    }

    if (state.lines.isEmpty) {
      const err = 'At least one line item is required.';
      state = state.copyWith(errorMessage: err);
      return const Failure(ValidationError(err, field: 'lines'));
    }

    for (final line in state.lines) {
      if (line.newBaseSellingPrice != null && line.newBaseSellingPrice! < 0) {
        const err = 'Base selling price cannot be negative.';
        state = state.copyWith(errorMessage: err);
        return const Failure(
            ValidationError(err, field: 'newBaseSellingPrice'));
      }
      if (line.newMinSellingPrice != null && line.newMinSellingPrice! < 0) {
        const err = 'Minimum selling price cannot be negative.';
        state = state.copyWith(errorMessage: err);
        return const Failure(ValidationError(err, field: 'newMinSellingPrice'));
      }
      if (line.newBaseSellingPrice != null &&
          line.newMinSellingPrice != null &&
          line.newMinSellingPrice! > line.newBaseSellingPrice!) {
        final err =
            'Minimum selling price cannot exceed base selling price for "${line.itemNameSnapshot}".';
        state = state.copyWith(errorMessage: err);
        return Failure(ValidationError(err, field: 'newMinSellingPrice'));
      }
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final receiving = Receiving(
        id: state.receivingId,
        storeId: _storeId,
        referenceNumber: state.referenceNumber.trim(),
        receivedAt: state.receivedAt,
        supplier: state.supplier.trim().isEmpty ? null : state.supplier.trim(),
        notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
        status:
            markCompleted ? ReceivingStatus.completed : ReceivingStatus.draft,
        createdBy: createdBy,
        lines: state.lines,
      );

      final result = await _repository.create(receiving);
      if (mounted) {
        state = state.copyWith(
          isSaving: false,
          errorMessage: result.errorMessageOrNull,
        );
      }
      return result;
    } catch (e, st) {
      if (mounted) {
        state = state.copyWith(isSaving: false, errorMessage: e.toString());
      }
      return Failure(StorageError('Failed to save receiving: $e'),
          stackTrace: st);
    }
  }
}
