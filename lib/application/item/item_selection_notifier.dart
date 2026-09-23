import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/item/item.dart';
import '../../domain/item/item_id.dart';

/// Manages multi-item selection state for bulk actions and exports.
class ItemSelectionNotifier extends StateNotifier<Set<ItemId>> {
  ItemSelectionNotifier() : super(const {});

  void toggle(ItemId id) {
    if (state.contains(id)) {
      state = state.where((existing) => existing != id).toSet();
    } else {
      state = {...state, id};
    }
  }

  void select(ItemId id) {
    if (!state.contains(id)) {
      state = {...state, id};
    }
  }

  void deselect(ItemId id) {
    if (state.contains(id)) {
      state = state.where((existing) => existing != id).toSet();
    }
  }

  void toggleAllVisible(List<Item> visibleItems) {
    final visibleIds = visibleItems.map((item) => item.id).toSet();
    final allVisibleSelected = visibleIds.every(state.contains);

    if (allVisibleSelected) {
      // Unselect all visible
      state = state.difference(visibleIds);
    } else {
      // Select all visible
      state = {...state, ...visibleIds};
    }
  }

  void selectVisible(List<Item> visibleItems) {
    state = {...state, ...visibleItems.map((item) => item.id)};
  }

  void clear() {
    state = const {};
  }

  bool isSelected(ItemId id) => state.contains(id);
}
