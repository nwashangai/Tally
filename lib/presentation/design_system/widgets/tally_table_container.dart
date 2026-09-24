import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/dimensions.dart';

/// Responsive container wrapper for desktop data tables providing consistent
/// background, border, clipping, and two-dimensional scrolling constraints.
class TallyTableContainer extends StatelessWidget {
  final Widget child;

  const TallyTableContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TallyRadii.md),
        border: Border.all(color: TallyColors.lightBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TallyRadii.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
