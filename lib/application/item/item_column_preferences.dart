import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/item/item_column.dart';

/// State representation for user column configuration.
class ItemColumnState {
  final Set<ItemColumn> visibleColumns;
  final ColumnPreset? activePreset;

  const ItemColumnState({
    required this.visibleColumns,
    this.activePreset,
  });

  ItemColumnState copyWith({
    Set<ItemColumn>? visibleColumns,
    ColumnPreset? activePreset,
    bool clearPreset = false,
  }) {
    return ItemColumnState(
      visibleColumns: visibleColumns ?? this.visibleColumns,
      activePreset: clearPreset ? null : (activePreset ?? this.activePreset),
    );
  }
}

/// Manages table column visibility and persists choices in SharedPreferences.
class ItemColumnPreferencesNotifier extends StateNotifier<ItemColumnState> {
  static const String _prefKey = 'tally_items_visible_columns';
  final SharedPreferences? _prefs;

  ItemColumnPreferencesNotifier({SharedPreferences? prefs})
      : _prefs = prefs,
        super(_loadInitialState(prefs));

  static ItemColumnState _loadInitialState(SharedPreferences? prefs) {
    if (prefs == null) {
      return ItemColumnState(
        visibleColumns: ColumnPreset.standard.columns,
        activePreset: ColumnPreset.standard,
      );
    }

    final rawList = prefs.getStringList(_prefKey);
    if (rawList == null || rawList.isEmpty) {
      return ItemColumnState(
        visibleColumns: ColumnPreset.standard.columns,
        activePreset: ColumnPreset.standard,
      );
    }

    final parsed =
        rawList.map(ItemColumn.fromString).whereType<ItemColumn>().toSet();

    // Ensure mandatory columns are always present
    parsed.add(ItemColumn.name);

    return ItemColumnState(
      visibleColumns: parsed,
      activePreset: _detectPreset(parsed),
    );
  }

  void toggleColumn(ItemColumn column) {
    // Mandatory columns cannot be toggled off
    if (column.isMandatory) return;

    final current = state.visibleColumns;
    final updated = current.contains(column)
        ? current.where((c) => c != column).toSet()
        : {...current, column};

    state = ItemColumnState(
      visibleColumns: updated,
      activePreset: _detectPreset(updated),
    );
    _persist();
  }

  void setPreset(ColumnPreset preset) {
    state = ItemColumnState(
      visibleColumns: preset.columns,
      activePreset: preset,
    );
    _persist();
  }

  void resetToDefault() {
    setPreset(ColumnPreset.standard);
  }

  static ColumnPreset? _detectPreset(Set<ItemColumn> cols) {
    for (final preset in ColumnPreset.values) {
      if (preset.columns.length == cols.length &&
          preset.columns.every(cols.contains)) {
        return preset;
      }
    }
    return null;
  }

  void _persist() {
    final names = state.visibleColumns.map((c) => c.name).toList();
    _prefs?.setStringList(_prefKey, names);
  }
}
