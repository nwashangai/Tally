import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/receiving/receiving_query_notifier.dart';
import 'package:tally/domain/receiving/receiving_query.dart';
import 'package:tally/domain/receiving/receiving_status.dart';

void main() {
  group('ReceivingQueryNotifier', () {
    test('initializes with default query', () {
      final notifier = ReceivingQueryNotifier();
      expect(notifier.state.search, isEmpty);
      expect(notifier.state.status, isNull);
      expect(notifier.state.supplier, isNull);
      expect(notifier.state.page, equals(1));
      expect(notifier.state.pageSize, equals(20));
      expect(notifier.state.sortBy, equals(ReceivingSortField.receivedAt));
      expect(notifier.state.sortDirection,
          equals(ReceivingSortDirection.descending));
    });

    test('setSearch updates search string and resets page to 1', () {
      final notifier = ReceivingQueryNotifier();
      notifier.setPage(3);
      expect(notifier.state.page, equals(3));

      notifier.setSearch('REC-001');
      expect(notifier.state.search, equals('REC-001'));
      expect(notifier.state.page, equals(1));
    });

    test('setStatus updates filter and resets page', () {
      final notifier = ReceivingQueryNotifier();
      notifier.setPage(2);

      notifier.setStatus(ReceivingStatus.completed);
      expect(notifier.state.status, equals(ReceivingStatus.completed));
      expect(notifier.state.page, equals(1));

      notifier.setStatus(null);
      expect(notifier.state.status, isNull);
    });

    test('setSupplier updates filter and resets page', () {
      final notifier = ReceivingQueryNotifier();
      notifier.setPage(4);

      notifier.setSupplier('Acme Ltd');
      expect(notifier.state.supplier, equals('Acme Ltd'));
      expect(notifier.state.page, equals(1));

      notifier.setSupplier('');
      expect(notifier.state.supplier, isNull);
    });

    test('setDateRange updates dates and resets page', () {
      final notifier = ReceivingQueryNotifier();
      notifier.setPage(2);

      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 1, 31);
      notifier.setDateRange(startDate: start, endDate: end);

      expect(notifier.state.startDate, equals(start));
      expect(notifier.state.endDate, equals(end));
      expect(notifier.state.page, equals(1));
    });

    test('setSortField changes sort field and toggles direction', () {
      final notifier = ReceivingQueryNotifier();
      expect(notifier.state.sortBy, equals(ReceivingSortField.receivedAt));
      expect(notifier.state.sortDirection,
          equals(ReceivingSortDirection.descending));

      // Toggling same field toggles direction to ascending
      notifier.setSortField(ReceivingSortField.receivedAt);
      expect(notifier.state.sortBy, equals(ReceivingSortField.receivedAt));
      expect(notifier.state.sortDirection,
          equals(ReceivingSortDirection.ascending));

      // Selecting different field defaults to descending
      notifier.setSortField(ReceivingSortField.totalCost);
      expect(notifier.state.sortBy, equals(ReceivingSortField.totalCost));
      expect(notifier.state.sortDirection,
          equals(ReceivingSortDirection.descending));
    });

    test('pagination next and previous page', () {
      final notifier = ReceivingQueryNotifier();
      notifier.nextPage();
      expect(notifier.state.page, equals(2));

      notifier.nextPage();
      expect(notifier.state.page, equals(3));

      notifier.previousPage();
      expect(notifier.state.page, equals(2));

      notifier.previousPage();
      expect(notifier.state.page, equals(1));

      // Cannot go below 1
      notifier.previousPage();
      expect(notifier.state.page, equals(1));
    });

    test('clearFilters resets all filter state', () {
      final notifier = ReceivingQueryNotifier();
      notifier.setSearch('test');
      notifier.setStatus(ReceivingStatus.draft);
      notifier.setSupplier('Distributor');
      notifier.setPage(3);

      notifier.clearFilters();
      expect(notifier.state.search, isEmpty);
      expect(notifier.state.status, isNull);
      expect(notifier.state.supplier, isNull);
      expect(notifier.state.page, equals(1));
    });
  });
}
