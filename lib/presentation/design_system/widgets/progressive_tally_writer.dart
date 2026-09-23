import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import 'tally_logo.dart';

/// Renders a progressive pen-written reveal of the Tally logo.
/// As [writeProgress] advances from 0.0 to 1.0, the letters are progressively
/// drawn with a luminous stylus cursor following the writing tip.
class ProgressiveTallyWriter extends StatelessWidget {
  /// Overall height of the logo.
  final double size;

  /// Progress of the writing stroke (0.0 to 1.0).
  final double writeProgress;

  /// Whether writing is fully completed.
  final bool isCompleted;

  const ProgressiveTallyWriter({
    super.key,
    this.size = 64,
    required this.writeProgress,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = size * 3.4;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Base logo with progressive clip
          ClipRect(
            clipper: _ProgressiveLogoClipper(progress: writeProgress),
            child: TallyLogo(
              size: size,
              variant: TallyLogoVariant.fullWordmark,
              showGlow: true,
            ),
          ),

          // Luminous stylus writing tip cursor
          if (writeProgress > 0.02 && writeProgress < 0.98 && !isCompleted)
            Positioned(
              left: (width * writeProgress) - (size * 0.2),
              top: (size * 0.1) + _getYOffset(writeProgress, size),
              child: _StylusCursor(size: size * 0.45),
            ),
        ],
      ),
    );
  }

  double _getYOffset(double progress, double s) {
    // Subtle up-down stylus writing motion across the letters
    if (progress < 0.25) return s * 0.3; // Writing 'T'
    if (progress < 0.45) return s * 0.45; // Writing 'a'
    if (progress < 0.65) return s * 0.25; // Writing 'l'
    if (progress < 0.85) return s * 0.25; // Writing 'l'
    return s * 0.55; // Writing 'y'
  }
}

class _ProgressiveLogoClipper extends CustomClipper<Rect> {
  final double progress;

  _ProgressiveLogoClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
        0, 0, size.width * progress.clamp(0.0, 1.0), size.height);
  }

  @override
  bool shouldReclip(covariant _ProgressiveLogoClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class _StylusCursor extends StatelessWidget {
  final double size;

  const _StylusCursor({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spark aura
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: TallyColors.varianceZeroLight.withValues(alpha: 0.8),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Pen tip
          Transform.rotate(
            angle: -0.45,
            child: Icon(
              Icons.edit_rounded,
              size: size * 0.8,
              color: TallyColors.iceFrost,
            ),
          ),
        ],
      ),
    );
  }
}
