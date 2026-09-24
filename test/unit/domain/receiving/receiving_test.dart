import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/receiving/receiving.dart';
import 'package:tally/domain/receiving/receiving_id.dart';
import 'package:tally/domain/receiving/receiving_line.dart';
import 'package:tally/domain/receiving/receiving_status.dart';
import 'package:tally/domain/store/store_id.dart';

void main() {
  const storeId = StoreId('store-1');
  const receivingId = ReceivingId('rec-1');
  const itemId1 = ItemId('item-1');
  const itemId2 = ItemId('item-2');

  group('ReceivingLine Domain Tests', () {
    test('constructs valid line and computes lineTotal automatically', () {
      final line = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Coca-Cola 50cl',
        skuSnapshot: 'BEV-COK-50',
        unitSnapshot: 'bottle',
        quantity: 24,
        unitCost: 200.0,
      );

      expect(line.quantity, 24);
      expect(line.unitCost, 200.0);
      expect(line.lineTotal, 4800.0);
      expect(line.updateItemCost, isFalse);
    });

    test('throws ArgumentError on zero or negative quantity', () {
      expect(
        () => ReceivingLine(
          receivingId: receivingId,
          itemId: itemId1,
          itemNameSnapshot: 'Coca-Cola 50cl',
          unitSnapshot: 'bottle',
          quantity: 0,
          unitCost: 200.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => ReceivingLine(
          receivingId: receivingId,
          itemId: itemId1,
          itemNameSnapshot: 'Coca-Cola 50cl',
          unitSnapshot: 'bottle',
          quantity: -5,
          unitCost: 200.0,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on negative unit cost', () {
      expect(
        () => ReceivingLine(
          receivingId: receivingId,
          itemId: itemId1,
          itemNameSnapshot: 'Coca-Cola 50cl',
          unitSnapshot: 'bottle',
          quantity: 10,
          unitCost: -1.0,
        ),
        throwsArgumentError,
      );
    });

    test('copyWith updates line and recalculates lineTotal', () {
      final line = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Coca-Cola 50cl',
        unitSnapshot: 'bottle',
        quantity: 10,
        unitCost: 200.0,
      );

      final updated = line.copyWith(quantity: 15, unitCost: 220.0);
      expect(updated.quantity, 15);
      expect(updated.unitCost, 220.0);
      expect(updated.lineTotal, 3300.0);
    });

    test('calculates margin and markup percentage correctly', () {
      final line = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Coca-Cola 50cl',
        unitSnapshot: 'bottle',
        quantity: 10,
        unitCost: 200.0,
        newBaseSellingPrice: 300.0,
        newMinSellingPrice: 250.0,
        updateItemPrice: true,
      );

      expect(line.newBaseSellingPrice, 300.0);
      expect(line.newMinSellingPrice, 250.0);
      expect(line.updateItemPrice, isTrue);
      expect(line.margin, 100.0); // 300 - 200
      expect(line.markupPercentage, 50.0); // (100 / 200) * 100
    });

    test('throws ArgumentError if minSellingPrice exceeds baseSellingPrice',
        () {
      expect(
        () => ReceivingLine(
          receivingId: receivingId,
          itemId: itemId1,
          itemNameSnapshot: 'Coca-Cola 50cl',
          unitSnapshot: 'bottle',
          quantity: 10,
          unitCost: 200.0,
          newBaseSellingPrice: 250.0,
          newMinSellingPrice: 300.0,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError on negative selling prices', () {
      expect(
        () => ReceivingLine(
          receivingId: receivingId,
          itemId: itemId1,
          itemNameSnapshot: 'Coca-Cola 50cl',
          unitSnapshot: 'bottle',
          quantity: 10,
          unitCost: 200.0,
          newBaseSellingPrice: -50.0,
        ),
        throwsArgumentError,
      );

      expect(
        () => ReceivingLine(
          receivingId: receivingId,
          itemId: itemId1,
          itemNameSnapshot: 'Coca-Cola 50cl',
          unitSnapshot: 'bottle',
          quantity: 10,
          unitCost: 200.0,
          newMinSellingPrice: -10.0,
        ),
        throwsArgumentError,
      );
    });

    test(
        'roundtrip JSON serialization preserves all line properties including pricing',
        () {
      final line = ReceivingLine(
        id: 'line-123',
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Peak Milk 160g',
        skuSnapshot: 'DRY-MILK-160',
        unitSnapshot: 'can',
        quantity: 12,
        unitCost: 350.0,
        updateItemCost: true,
        newBaseSellingPrice: 500.0,
        newMinSellingPrice: 450.0,
        updateItemPrice: true,
      );

      final json = line.toJson();
      final reconstructed = ReceivingLine.fromJson(json);

      expect(reconstructed, line);
      expect(reconstructed.updateItemCost, isTrue);
      expect(reconstructed.newBaseSellingPrice, 500.0);
      expect(reconstructed.newMinSellingPrice, 450.0);
      expect(reconstructed.updateItemPrice, isTrue);
      expect(reconstructed.lineTotal, 4200.0);
    });
  });

  group('Receiving Aggregate Domain Tests', () {
    test('calculates totalCost, itemCount, and totalQuantity across lines', () {
      final line1 = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Coca-Cola 50cl',
        unitSnapshot: 'bottle',
        quantity: 24,
        unitCost: 200.0, // 4800
      );
      final line2 = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId2,
        itemNameSnapshot: 'Peak Milk 160g',
        unitSnapshot: 'can',
        quantity: 10,
        unitCost: 320.0, // 3200
      );

      final receiving = Receiving(
        id: receivingId,
        storeId: storeId,
        referenceNumber: 'REC-000124',
        supplier: 'ABC Distribution',
        notes: 'Invoice #9821',
        lines: [line1, line2],
      );

      expect(receiving.itemCount, 2);
      expect(receiving.totalQuantity, 34);
      expect(receiving.totalCost, 8000.0);
      expect(receiving.status, ReceivingStatus.draft);
    });

    test('throws ArgumentError if referenceNumber is empty or whitespace', () {
      expect(
        () => Receiving(
          storeId: storeId,
          referenceNumber: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if completed receiving has no lines', () {
      expect(
        () => Receiving(
          storeId: storeId,
          referenceNumber: 'REC-000001',
          status: ReceivingStatus.completed,
          lines: const [],
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if receiving contains duplicate item IDs', () {
      final line1 = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Coca-Cola 50cl',
        unitSnapshot: 'bottle',
        quantity: 10,
        unitCost: 200.0,
      );
      final line2 = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1, // Duplicate ID
        itemNameSnapshot: 'Coca-Cola 50cl (Extra)',
        unitSnapshot: 'bottle',
        quantity: 5,
        unitCost: 210.0,
      );

      expect(
        () => Receiving(
          storeId: storeId,
          referenceNumber: 'REC-000002',
          lines: [line1, line2],
        ),
        throwsArgumentError,
      );
    });

    test('historical snapshots remain immutable and preserved', () {
      final line = ReceivingLine(
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Coca-Cola 50cl',
        skuSnapshot: 'COK-50',
        unitSnapshot: 'bottle',
        quantity: 50,
        unitCost: 200.0,
      );

      final receiving = Receiving(
        id: receivingId,
        storeId: storeId,
        referenceNumber: 'REC-000050',
        status: ReceivingStatus.completed,
        lines: [line],
      );

      // Verify line data is immutable
      expect(receiving.lines.first.unitCost, 200.0);
      expect(receiving.lines.first.itemNameSnapshot, 'Coca-Cola 50cl');
      expect(receiving.lines.first.lineTotal, 10000.0);
      expect(
          () => (receiving.lines as dynamic).add(line), throwsUnsupportedError);
    });

    test('roundtrip JSON serialization preserves all aggregate fields', () {
      final now = DateTime.utc(2026, 9, 23, 14, 30);
      final line = ReceivingLine(
        id: 'line-1',
        receivingId: receivingId,
        itemId: itemId1,
        itemNameSnapshot: 'Milo 500g',
        skuSnapshot: 'MILO-500',
        unitSnapshot: 'pack',
        quantity: 12,
        unitCost: 2200.0,
      );

      final receiving = Receiving(
        id: receivingId,
        storeId: storeId,
        referenceNumber: 'REC-000999',
        receivedAt: now,
        supplier: 'Nestle Direct',
        notes: 'Carton sealed',
        status: ReceivingStatus.completed,
        createdBy: 'user-abc',
        createdAt: now,
        updatedAt: now,
        lines: [line],
      );

      final json = receiving.toJson();
      final parsed = Receiving.fromJson(json);

      expect(parsed, receiving);
      expect(parsed.totalCost, 26400.0);
      expect(parsed.lines.length, 1);
      expect(parsed.lines.first.itemNameSnapshot, 'Milo 500g');
    });
  });
}
