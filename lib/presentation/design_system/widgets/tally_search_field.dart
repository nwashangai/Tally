import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Standardized enterprise search field with focus border highlight, search icon,
/// clear button, and optional mobile expand-with-cancel mode.
class TallySearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isFocused;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onCancel;
  final bool showCancelButton;
  final Key? fieldKey;
  final Key? cancelButtonKey;

  const TallySearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.isFocused = false,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.onCancel,
    this.showCancelButton = false,
    this.fieldKey,
    this.cancelButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final searchInput = Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(
          color: isFocused ? TallyColors.primaryNavy : TallyColors.lightBorder,
          width: isFocused ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: TallyColors.slateMuted,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: isFocused ? TallyColors.primaryNavy : TallyColors.slateMuted,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
        ),
      ),
    );

    if (!showCancelButton) {
      return searchInput;
    }

    return Row(
      children: [
        Expanded(child: searchInput),
        const SizedBox(width: TallySpacing.xs),
        TextButton(
          key: cancelButtonKey,
          onPressed: onCancel,
          style: TextButton.styleFrom(
            foregroundColor: TallyColors.primaryNavy,
            padding: const EdgeInsets.symmetric(
              horizontal: TallySpacing.sm,
            ),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
