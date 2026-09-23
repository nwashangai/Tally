import 'package:flutter/widgets.dart';

/// Strongly-typed identifier for a store navigation module.
enum StoreModuleId {
  home,
  sales,
  items,
  receivings,
  reports,
  settings,
  custom,
}

/// Category grouping for store modules.
enum StoreModuleCategory {
  operations,
  analytics,
  administration,
}

/// Abstract contract for a pluggable store feature module.
/// Allows new store modules to be registered into the menu/navigation
/// without modifying core navigation shell code or database structures.
class StoreModule {
  final StoreModuleId id;
  final String key;
  final String label;
  final String description;
  final IconData icon;
  final IconData? selectedIcon;
  final int order;
  final StoreModuleCategory category;
  final bool showInBottomNav;
  final Widget Function(BuildContext context) builder;

  const StoreModule({
    required this.id,
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    this.selectedIcon,
    required this.order,
    required this.category,
    this.showInBottomNav = true,
    required this.builder,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreModule &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}
