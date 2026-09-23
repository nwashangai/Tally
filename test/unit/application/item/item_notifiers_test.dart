import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/item/item_column_preferences.dart';
import 'package:tally/application/item/item_query_notifier.dart';
import 'package:tally/application/item/item_selection_notifier.dart';
import 'package:tally/domain/item/item.dart';
import 'package:tally/domain/item/item_column.dart';
import 'package:tally/domain/item/item_id.dart';
import 'package:tally/domain/item/item_inventory.dart';
import 'package:tally/domain/item/item_pricing.dart';
import 'package:tally/domain/item/item_query.dart';
import 'package:tally/domain/item/item_unit.dart';
import 'package:tally/domain/store/store_id.dart';

void main() {
  group('ItemQueryNotifier', () {
    test('updates search and resets page to 1', () {
      final notifier = ItemQueryNotifier(
        initialQuery: const ItemQuery(page: 3, search: ''),
      );

      notifier.setSearch('coke');
      expect(notifier.state.search, 'coke');
      expect(notifier.state.page, 1);
    });

    test('updates sort direction on repeated toggle', () {
      final notifier = ItemQueryNotifier();

      // First click on costPrice -> ascending
      notifier.setSortField(ItemSortField.costPrice);
      expect(notifier.state.sort.field, ItemSortField.costPrice);
      expect(notifier.state.sort.order, SortOrder.ascending);

      // Second click on costPrice -> toggles to descending
      notifier.setSortField(ItemSortField.costPrice);
      expect(notifier.state.sort.order, SortOrder.descending);
    });

    test('pagination navigation methods', () {
      final notifier = ItemQueryNotifier();
      notifier.nextPage();
      expect(notifier.state.page, 2);

      notifier.previousPage();
      expect(notifier.state.page, 1);

      notifier.previousPage(); // Should not go below 1
      expect(notifier.state.page, 1);
    });
  });

  group('ItemSelectionNotifier', () {
    test('toggles and bulk selects visible items', () {
      final notifier = ItemSelectionNotifier();
      const id1 = ItemId('item-1');
      const id2 = ItemId('item-2');

      notifier.toggle(id1);
      expect(notifier.state.contains(id1), isTrue);

      notifier.toggle(id1);
      expect(notifier.state.contains(id1), isFalse);

      final dummyItem1 = Item(
        id: id1,
        storeId: const StoreId('s1'),
        name: 'Item 1',
        unit: ItemUnit.piece,
        pricing: ItemPricing(costPrice: 10, baseSellingPrice: 20),
        inventory: ItemInventory(quantity: 5),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final dummyItem2 = Item(
        id: id2,
        storeId: const StoreId('s1'),
        name: 'Item 2',
        unit: ItemUnit.piece,
        pricing: ItemPricing(costPrice: 10, baseSellingPrice: 20),
        inventory: ItemInventory(quantity: 5),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      notifier.toggleAllVisible([dummyItem1, dummyItem2]);
      expect(notifier.state.length, 2);

      notifier.toggleAllVisible([dummyItem1, dummyItem2]);
      expect(notifier.state.isEmpty, isTrue);
    });
  });

  group('ItemColumnPreferencesNotifier', () {
    test('prevents mandatory columns from being removed', () {
      final notifier = ItemColumnPreferencesNotifier();
      expect(notifier.state.visibleColumns.contains(ItemColumn.name), isTrue);

      notifier.toggleColumn(ItemColumn.name);
      // Name is mandatory and must remain visible
      expect(notifier.state.visibleColumns.contains(ItemColumn.name), isTrue);
    });

    test('switching presets updates visible columns', () {
      final notifier = ItemColumnPreferencesNotifier();
      notifier.setPreset(ColumnPreset.pricing);

      expect(notifier.state.activePreset, ColumnPreset.pricing);
      expect(
        notifier.state.visibleColumns.contains(ItemColumn.costPrice),
        isTrue,
      );
      expect(
        notifier.state.visibleColumns.contains(ItemColumn.baseSellingPrice),
        isTrue,
      );
    });
  });
}
