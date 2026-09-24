import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/providers/core_providers.dart';
import 'package:tally/core/result/result.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/receiving/receiving.dart';
import 'package:tally/domain/receiving/receiving_id.dart';
import 'package:tally/domain/receiving/receiving_line.dart';
import 'package:tally/domain/receiving/receiving_line_history.dart';
import 'package:tally/domain/receiving/receiving_query.dart';
import 'package:tally/domain/receiving/receiving_repository.dart';
import 'package:tally/domain/receiving/receiving_status.dart';
import 'package:tally/domain/store/store_id.dart';
import 'package:tally/presentation/receivings/receiving_details_screen.dart';

class _FakeReceivingRepository implements ReceivingRepository {
  Receiving receiving;

  _FakeReceivingRepository(this.receiving);

  @override
  Future<Result<Receiving?>> getById(ReceivingId id) async =>
      Success(receiving);

  @override
  Future<Result<Receiving>> create(Receiving r) async {
    receiving = r;
    return Success(r);
  }

  @override
  Future<Result<Receiving>> complete(ReceivingId id) async {
    receiving = receiving.copyWith(status: ReceivingStatus.completed);
    return Success(receiving);
  }

  @override
  Future<Result<Receiving>> voidReceiving(ReceivingId id,
      {String? reason}) async {
    receiving = receiving.copyWith(
      status: ReceivingStatus.voided,
      notes: reason != null ? 'Void reason: $reason' : receiving.notes,
    );
    return Success(receiving);
  }

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 10,
  }) async =>
      const Success([]);

  @override
  Future<Result<String>> getNextReferenceNumber() async =>
      const Success('REC-000001');

  @override
  Future<Result<PaginatedResult<Receiving>>> query(
          ReceivingQuery query) async =>
      Success(PaginatedResult<Receiving>(
        items: [receiving],
        page: 1,
        pageSize: 20,
        totalItems: 1,
      ));

  @override
  Future<Result<Receiving>> update(Receiving r) async {
    receiving = r;
    return Success(r);
  }

  @override
  Future<Result<void>> delete(ReceivingId id) async {
    return const Success(null);
  }
}

void main() {
  final sampleReceiving = Receiving(
    id: const ReceivingId('rec-details-1'),
    storeId: const StoreId('store-1'),
    referenceNumber: 'REC-000099',
    receivedAt: DateTime(2026, 9, 21),
    supplier: 'Nestle Nigeria Plc',
    notes: 'PO-5544 Delivery',
    status: ReceivingStatus.completed,
    lines: [
      ReceivingLine(
        receivingId: const ReceivingId('rec-details-1'),
        itemId: const ItemId('milo-500g'),
        itemNameSnapshot: 'Milo 500g Refill',
        skuSnapshot: 'NES-MILO-500',
        unitSnapshot: 'tin',
        quantity: 24,
        unitCost: 2200,
        updateItemCost: true,
      ),
    ],
  );

  Widget createSubject(ReceivingRepository repo, Receiving receiving) {
    return ProviderScope(
      overrides: [
        receivingRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: ReceivingDetailsScreen(receiving: receiving),
      ),
    );
  }

  testWidgets('renders transaction details, metrics, and line items',
      (tester) async {
    final repo = _FakeReceivingRepository(sampleReceiving);

    await tester.pumpWidget(createSubject(repo, sampleReceiving));
    await tester.pumpAndSettle();

    expect(find.text('REC-000099'), findsWidgets);
    expect(find.text('Nestle Nigeria Plc'), findsOneWidget);
    expect(find.text('PO-5544 Delivery'), findsOneWidget);
    expect(find.text('Milo 500g Refill'), findsOneWidget);
    expect(find.text('NES-MILO-500'), findsOneWidget);
    expect(find.text('24 tin'), findsOneWidget);
    expect(find.text('Catalog cost updated'), findsOneWidget);
    expect(find.text('Void this Receiving Transaction'), findsOneWidget);
  });

  testWidgets('tapping void opens confirmation dialog and voids',
      (tester) async {
    final repo = _FakeReceivingRepository(sampleReceiving);

    await tester.pumpWidget(createSubject(repo, sampleReceiving));
    await tester.pumpAndSettle();

    final voidButton = find.text('Void this Receiving Transaction');
    await tester.ensureVisible(voidButton);
    await tester.tap(voidButton);
    await tester.pumpAndSettle();

    expect(find.text('Void Receiving?'), findsOneWidget);
    expect(find.text('Confirm Void'), findsOneWidget);

    await tester.tap(find.text('Confirm Void'));
    await tester.pumpAndSettle();

    expect(repo.receiving.isVoided, isTrue);
    expect(find.text('This transaction has been voided'), findsOneWidget);
  });

  testWidgets(
      'renders draft receiving with banner, edit, and delete actions (no direct complete)',
      (tester) async {
    final draftReceiving = Receiving(
      id: const ReceivingId('draft-details-1'),
      storeId: const StoreId('store-1'),
      referenceNumber: 'REC-DRAFT-99',
      receivedAt: DateTime(2026, 9, 21),
      supplier: 'Unilever Nigeria',
      status: ReceivingStatus.draft,
      lines: [
        ReceivingLine(
          receivingId: const ReceivingId('draft-details-1'),
          itemId: const ItemId('milo-500g'),
          itemNameSnapshot: 'Milo 500g Refill',
          unitSnapshot: 'tin',
          quantity: 12,
          unitCost: 2000,
        ),
      ],
    );

    final repo = _FakeReceivingRepository(draftReceiving);

    await tester.pumpWidget(createSubject(repo, draftReceiving));
    await tester.pumpAndSettle();

    // Verify draft banner
    expect(find.text('Draft Receiving'), findsOneWidget);
    expect(
      find.text(
          'Stock has not been adjusted. You can continue editing or delete this draft.'),
      findsOneWidget,
    );

    // Verify action buttons: Continue Editing and Delete Draft are present
    expect(find.text('Continue Editing'), findsWidgets);
    expect(find.text('Delete Draft'), findsWidgets);

    // Verify Complete Receiving button is NOT present directly (must be done from edit form)
    expect(find.text('Complete Receiving'), findsNothing);

    // Delete Draft flow
    final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete Draft');
    await tester.ensureVisible(deleteBtn);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    expect(find.text('Delete Draft?'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets(
      'renders card layout for line items on mobile without DataTable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _FakeReceivingRepository(sampleReceiving);

    await tester.pumpWidget(createSubject(repo, sampleReceiving));
    await tester.pumpAndSettle();

    // Verify DataTable is NOT rendered on mobile
    expect(find.byType(DataTable), findsNothing);

    // Verify item details rendered in card layout
    expect(find.text('Milo 500g Refill'), findsOneWidget);
    expect(find.text('NES-MILO-500'), findsOneWidget);
    expect(find.text('Catalog cost updated'), findsOneWidget);

    // Verify no RenderFlex overflow
    expect(tester.takeException(), isNull);
  });
}

