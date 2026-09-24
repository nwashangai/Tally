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
import 'package:tally/presentation/receivings/receivings_screen.dart';
import 'package:tally/presentation/receivings/widgets/receiving_desktop_table.dart';
import 'package:tally/presentation/receivings/widgets/receiving_mobile_card.dart';

class _FakeReceivingRepository implements ReceivingRepository {
  final List<Receiving> receivings;

  _FakeReceivingRepository(this.receivings);

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
  Future<Result<Receiving?>> getById(ReceivingId id) async {
    final r = receivings.where((x) => x.id == id).firstOrNull;
    return Success(r);
  }

  @override
  Future<Result<Receiving>> create(Receiving receiving) async {
    receivings.add(receiving);
    return Success(receiving);
  }

  @override
  Future<Result<Receiving>> complete(ReceivingId id) async =>
      Success(receivings.firstWhere((r) => r.id == id));

  @override
  Future<Result<Receiving>> voidReceiving(ReceivingId id,
          {String? reason}) async =>
      Success(receivings.firstWhere((r) => r.id == id));

  @override
  Future<Result<List<ReceivingLineHistory>>> getItemReceivingHistory(
    ItemId itemId, {
    int limit = 10,
  }) async =>
      const Success([]);

  @override
  Future<Result<String>> getNextReferenceNumber() async =>
      const Success('REC-000001');
}

void main() {
  final sampleReceiving = Receiving(
    id: const ReceivingId('rec-1'),
    storeId: const StoreId('store-1'),
    referenceNumber: 'REC-000001',
    receivedAt: DateTime(2026, 9, 20),
    supplier: 'Golden Penny Mills',
    status: ReceivingStatus.completed,
    lines: [
      ReceivingLine(
        receivingId: const ReceivingId('rec-1'),
        itemId: const ItemId('item-1'),
        itemNameSnapshot: 'Golden Penny Flour 50kg',
        skuSnapshot: 'GP-FLOUR-50',
        unitSnapshot: 'bag',
        quantity: 10,
        unitCost: 35000,
      ),
    ],
  );

  Widget createSubject(ReceivingRepository repo) {
    return ProviderScope(
      overrides: [
        receivingRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: ReceivingsScreen(),
      ),
    );
  }

  testWidgets('renders empty state when no receivings exist', (tester) async {
    final repo = _FakeReceivingRepository([]);

    await tester.pumpWidget(createSubject(repo));
    await tester.pumpAndSettle();

    expect(find.text('No receivings yet'), findsOneWidget);
    expect(find.text('New Receiving'), findsWidgets);
  });

  testWidgets('renders mobile card list on mobile width', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _FakeReceivingRepository([sampleReceiving]);

    await tester.pumpWidget(createSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byType(ReceivingMobileCard), findsOneWidget);
    expect(find.text('REC-000001'), findsOneWidget);
    expect(find.text('Golden Penny Mills'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets('renders desktop table on wide width', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repo = _FakeReceivingRepository([sampleReceiving]);

    await tester.pumpWidget(createSubject(repo));
    await tester.pumpAndSettle();

    expect(find.byType(ReceivingDesktopTable), findsOneWidget);
    expect(find.text('REC-000001'), findsOneWidget);
    expect(find.text('Golden Penny Mills'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });
}
