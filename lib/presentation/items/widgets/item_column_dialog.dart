import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers/core_providers.dart';
import '../../../domain/item/item_column.dart';
import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/dimensions.dart';

/// Modal dialog for customizing visible table columns and switching presets.
class ItemColumnDialog extends ConsumerWidget {
  const ItemColumnDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columnState = ref.watch(itemColumnPreferencesProvider);
    final notifier = ref.read(itemColumnPreferencesProvider.notifier);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TallyRadii.lg),
      ),
      title: const Row(
        children: [
          Icon(Icons.view_column_outlined, color: TallyColors.primaryNavy),
          SizedBox(width: TallySpacing.sm),
          Text(
            'Customize Columns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TallyColors.primaryNavy,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Presets',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.slateMuted,
                ),
              ),
              const SizedBox(height: TallySpacing.xs),
              Wrap(
                spacing: TallySpacing.xs,
                runSpacing: TallySpacing.xs,
                children: ColumnPreset.values.map((preset) {
                  final isSelected = columnState.activePreset == preset;
                  return ChoiceChip(
                    label: Text(preset.label),
                    selected: isSelected,
                    onSelected: (_) => notifier.setPreset(preset),
                    selectedColor: TallyColors.iceFrost,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? TallyColors.primaryNavy
                          : TallyColors.slateMuted,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: TallySpacing.md),
              const Divider(color: TallyColors.lightBorder),
              const SizedBox(height: TallySpacing.xs),
              const Text(
                'Available Columns',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TallyColors.slateMuted,
                ),
              ),
              const SizedBox(height: TallySpacing.xs),
              ...ItemColumn.values.map((col) {
                final isChecked = columnState.visibleColumns.contains(col);
                return CheckboxListTile(
                  title: Text(
                    col.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          col.isMandatory ? FontWeight.w700 : FontWeight.w500,
                      color: TallyColors.primaryNavy,
                    ),
                  ),
                  subtitle: Text(
                    col.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TallyColors.slateMuted,
                    ),
                  ),
                  value: isChecked,
                  onChanged: col.isMandatory
                      ? null
                      : (_) => notifier.toggleColumn(col),
                  secondary: col.isMandatory
                      ? const Tooltip(
                          message: 'Mandatory field',
                          child: Icon(Icons.lock_outline, size: 18),
                        )
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => notifier.resetToDefault(),
          child: const Text('Reset to Default'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: TallyColors.primaryNavy,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
