import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/application/navigation/store_module_registry.dart';
import 'package:tally/domain/navigation/store_module.dart';

void main() {
  group('StoreModuleRegistryNotifier', () {
    test('initial state contains all default modules in order', () {
      final notifier = StoreModuleRegistryNotifier();
      final modules = notifier.state;

      expect(modules.length, equals(6));
      expect(modules.map((m) => m.id).toList(), [
        StoreModuleId.home,
        StoreModuleId.sales,
        StoreModuleId.items,
        StoreModuleId.receivings,
        StoreModuleId.reports,
        StoreModuleId.settings,
      ]);
    });

    test('registerModule dynamically adds new custom module in sorted order',
        () {
      final notifier = StoreModuleRegistryNotifier();

      const newModule = StoreModule(
        id: StoreModuleId.custom,
        key: 'suppliers',
        label: 'Suppliers',
        description: 'Vendor directory and purchase contracts',
        icon: Icons.business,
        order: 3, // Between items (2) and receivings (3 -> sorted)
        category: StoreModuleCategory.operations,
        builder: _dummyBuilder,
      );

      notifier.registerModule(newModule);

      final modules = notifier.state;
      expect(modules.length, equals(7));
      expect(modules.any((m) => m.key == 'suppliers'), isTrue);
      // Order check: order 3 should appear before order 4 and 5
      expect(modules.last.id, equals(StoreModuleId.settings));
    });

    test('unregisterModule removes module by key', () {
      final notifier = StoreModuleRegistryNotifier();
      notifier.unregisterModule('sales');

      expect(notifier.state.any((m) => m.key == 'sales'), isFalse);
      expect(notifier.state.length, equals(5));
    });
  });
}

Widget _dummyBuilder(BuildContext context) => const SizedBox();
