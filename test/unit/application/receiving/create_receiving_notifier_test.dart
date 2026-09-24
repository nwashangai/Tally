import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/receiving/create_receiving_notifier.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/receiving/receiving.dart';
import 'package:tally/domain/receiving/receiving_id.dart';
import 'package:tally/domain/receiving/receiving_line_history.dart';
import 'package:tally/domain/receiving/receiving_query.dart';
import 'package:tally/domain/receiving/receiving_repository.dart';
import 'package:tally/domain/store/store_id.dart';

class _FakeReceivingRepository implements ReceivingRepository {
  final List<Receiving> receivings = [];
  String nextRef = 'REC-000001';

  @override
  Future<Result<String>> getNextReferenceNumber() async => Success(nextRef);

  @override
  Future<Result<Receiving>> create(Receiving receiving) async {
    receivings.add(receiving);
    return Success(receiving);
  }

  @override
  Future<Result<Receiving>> complete(ReceivingId id) async {
    final idx = receivings.indexWhere((r) => r.id == id);
    if (idx != -1) return Success(receivings[idx]);
    throw UnimplementedError();
  }

  @override
  Future<Result<Receiving?>> getById(ReceivingId id) async {
    final r = receivings.where((e) => e.id == id).firstOrNull;
    return Success(r);
  }

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 10,
  }) async =>
      const Success([]);

  @override
  Future<Result<PaginatedResult<Receiving>>> query(ReceivingQuery query) async {
    return Success(PaginatedResult<Receiving>(
      items: receivings,
      page: query.page,
      pageSize: query.pageSize,
      totalItems: receivings.length,
    ));
  }

  @override
  Future<Result<Receiving>> voidReceiving(ReceivingId id,
      {String? reason}) async {
    final idx = receivings.indexWhere((r) => r.id == id);
    if (idx != -1) return Success(receivings[idx]);
    throw UnimplementedError();
  }
}

void main() {
  group('CreateReceivingNotifier', () {
    late _FakeReceivingRepository repo;
    const storeId = StoreId('store-test');

    setUp(() {
      repo = _FakeReceivingRepository();
    });

    final testItem = Item(
      id: const ItemId('item-1'),
      storeId: storeId,
      name: 'Flour 1kg',
      sku: 'FLOUR-1',
      unit: ItemUnit.bottle,
      pricing: ItemPricing(costPrice: 500, baseSellingPrice: 700),
      inventory: ItemInventory(quantity: 10),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('initializes with next reference number from repository', () async {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );

      // Await microtasks for async reference init
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.referenceNumber, equals('REC-000001'));
      expect(notifier.state.lines, isEmpty);
      expect(notifier.state.isValid, isFalse);
    });

    test('adding items creates lines and computes totals', () {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );

      notifier.addItem(testItem, quantity: 5, unitCost: 480);

      expect(notifier.state.lines.length, equals(1));
      final line = notifier.state.lines.first;
      expect(line.itemNameSnapshot, equals('Flour 1kg'));
      expect(line.quantity, equals(5));
      expect(line.unitCost, equals(480));
      expect(line.lineTotal, equals(2400));
      expect(notifier.state.totalCost, equals(2400));
      expect(notifier.state.totalQuantity, equals(5));
      expect(notifier.state.itemCount, equals(1));
    });

    test('adding duplicate item merges quantity', () {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );

      notifier.addItem(testItem, quantity: 3, unitCost: 500);
      notifier.addItem(testItem, quantity: 2, unitCost: 500);

      expect(notifier.state.lines.length, equals(1));
      expect(notifier.state.lines.first.quantity, equals(5));
      expect(notifier.state.totalQuantity, equals(5));
      expect(notifier.state.totalCost, equals(2500));
    });

    test('updating quantity and cost updates line subtotal', () {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );

      notifier.addItem(testItem, quantity: 2, unitCost: 500);
      final lineId = notifier.state.lines.first.id;

      notifier.updateQuantity(lineId, 10);
      notifier.updateUnitCost(lineId, 450);

      final updated = notifier.state.lines.first;
      expect(updated.quantity, equals(10));
      expect(updated.unitCost, equals(450));
      expect(updated.lineTotal, equals(4500));
      expect(notifier.state.totalCost, equals(4500));
    });

    test('toggling update item cost updates state', () {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );

      notifier.addItem(testItem, quantity: 2, unitCost: 500);
      final lineId = notifier.state.lines.first.id;

      expect(notifier.state.lines.first.updateItemCost, isFalse);
      notifier.toggleUpdateItemCost(lineId, true);
      expect(notifier.state.lines.first.updateItemCost, isTrue);
    });

    test('removing line item empties the list', () {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );

      notifier.addItem(testItem, quantity: 2, unitCost: 500);
      final lineId = notifier.state.lines.first.id;

      notifier.removeLine(lineId);
      expect(notifier.state.lines, isEmpty);
      expect(notifier.state.totalCost, equals(0));
    });

    test('submitting with valid data persists to repository', () async {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );
      notifier.setReference('REC-TEST-01');
      notifier.setSupplier('Acme Supplies');
      notifier.addItem(testItem, quantity: 4, unitCost: 500);

      final result = await notifier.submit(markCompleted: true);

      expect(result.isSuccess, isTrue);
      expect(repo.receivings.length, equals(1));
      final saved = repo.receivings.first;
      expect(saved.referenceNumber, equals('REC-TEST-01'));
      expect(saved.supplier, equals('Acme Supplies'));
      expect(saved.isCompleted, isTrue);
    });

    test('submitting with empty lines fails validation', () async {
      final notifier = CreateReceivingNotifier(
        repository: repo,
        storeId: storeId,
      );
      notifier.setReference('REC-EMPTY');

      final result = await notifier.submit(markCompleted: true);

      expect(result.isFailure, isTrue);
      expect(notifier.state.errorMessage, contains('line item is required'));
    });
  });
}
