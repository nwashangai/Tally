import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/navigation/store_module.dart';
import '../../presentation/home/store_home_screen.dart';
import '../../presentation/items/items_screen.dart';
import '../../presentation/receivings/receivings_screen.dart';
import '../../presentation/reports/reports_screen.dart';
import '../../presentation/sales/sales_placeholder_screen.dart';
import '../../presentation/settings/store_settings_screen.dart';

/// Default core modules for the Tally store experience.
final List<StoreModule> kDefaultStoreModules = [
  StoreModule(
    id: StoreModuleId.home,
    key: 'home',
    label: 'Overview',
    description: 'Store dashboard, quick actions, and status',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    order: 0,
    category: StoreModuleCategory.operations,
    showInBottomNav: true,
    builder: (context) => const StoreHomeScreen(),
  ),
  StoreModule(
    id: StoreModuleId.sales,
    key: 'sales',
    label: 'Sales',
    description: 'Point of sale register and instant checkout',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    order: 1,
    category: StoreModuleCategory.operations,
    showInBottomNav: true,
    builder: (context) => const SalesPlaceholderScreen(),
  ),
  StoreModule(
    id: StoreModuleId.items,
    key: 'items',
    label: 'Items',
    description: 'Catalog, barcode scan, SKUs, and stock levels',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    order: 2,
    category: StoreModuleCategory.operations,
    showInBottomNav: true,
    builder: (context) => const ItemsScreen(),
  ),
  StoreModule(
    id: StoreModuleId.receivings,
    key: 'receivings',
    label: 'Receivings',
    description: 'Purchase orders, stock in, and supplier intake',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping,
    order: 3,
    category: StoreModuleCategory.operations,
    showInBottomNav: true,
    builder: (context) => const ReceivingsScreen(),
  ),
  StoreModule(
    id: StoreModuleId.reports,
    key: 'reports',
    label: 'Reports',
    description: 'Variance analysis, audit trails, and valuation',
    icon: Icons.insert_chart_outlined_rounded,
    selectedIcon: Icons.insert_chart_rounded,
    order: 4,
    category: StoreModuleCategory.analytics,
    showInBottomNav: true,
    builder: (context) => const ReportsScreen(),
  ),
  StoreModule(
    id: StoreModuleId.settings,
    key: 'settings',
    label: 'Settings',
    description: 'Database lifecycle, WAL config, and store preferences',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    order: 5,
    category: StoreModuleCategory.administration,
    showInBottomNav: true,
    builder: (context) => const StoreSettingsScreen(),
  ),
];

/// Extensible registry of store modules.
class StoreModuleRegistryNotifier extends StateNotifier<List<StoreModule>> {
  StoreModuleRegistryNotifier([List<StoreModule>? initialModules])
      : super(initialModules ?? List.unmodifiable(kDefaultStoreModules));

  /// Dynamically registers a new module into the store navigation.
  void registerModule(StoreModule module) {
    if (state.any((m) => m.key == module.key)) {
      state = [
        for (final m in state)
          if (m.key == module.key) module else m,
      ]..sort((a, b) => a.order.compareTo(b.order));
    } else {
      final updated = [...state, module]
        ..sort((a, b) => a.order.compareTo(b.order));
      state = List.unmodifiable(updated);
    }
  }

  /// Removes a module by its key.
  void unregisterModule(String key) {
    state = List.unmodifiable(state.where((m) => m.key != key));
  }
}

/// Provider for registered store navigation modules.
final storeModulesProvider =
    StateNotifierProvider<StoreModuleRegistryNotifier, List<StoreModule>>(
  (ref) => StoreModuleRegistryNotifier(),
);

/// Currently active store module ID.
final selectedModuleIdProvider = StateProvider<StoreModuleId>(
  (ref) => StoreModuleId.home,
);
