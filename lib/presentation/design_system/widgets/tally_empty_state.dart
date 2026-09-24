import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Standardized enterprise empty state widget for zero-data and search/filter empty views.
class TallyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final bool isSearchEmpty;
  final double iconSize;

  const TallyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.isSearchEmpty = false,
    this.iconSize = 48,
  });

  /// Factory constructor for empty search/filter results
  factory TallyEmptyState.searchEmpty({
    Key? key,
    required String title,
    required String description,
    Widget? action,
  }) {
    return TallyEmptyState(
      key: key,
      icon: Icons.search_off_outlined,
      title: title,
      description: description,
      action: action,
      isSearchEmpty: true,
      iconSize: 48,
    );
  }

  /// Factory constructor for initial zero-data state
  factory TallyEmptyState.zeroData({
    Key? key,
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
    double iconSize = 48,
  }) {
    return TallyEmptyState(
      key: key,
      icon: icon,
      title: title,
      description: description,
      action: action,
      isSearchEmpty: false,
      iconSize: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TallySpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSearchEmpty)
              Icon(
                icon,
                size: iconSize,
                color: TallyColors.slateMuted,
              )
            else
              Container(
                padding: const EdgeInsets.all(TallySpacing.xl),
                decoration: const BoxDecoration(
                  color: TallyColors.iceFrost,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: TallyColors.primaryNavy,
                ),
              ),
            const SizedBox(height: TallySpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TallyColors.primaryNavy,
              ),
            ),
            const SizedBox(height: TallySpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: TallyColors.slateMuted,
                  height: 1.4,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: TallySpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
