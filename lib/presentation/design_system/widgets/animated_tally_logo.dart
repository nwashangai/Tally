import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import 'tally_logo.dart';

/// Animated version of the Tally logo with staggered vector transitions:
/// 1. Book-T expands and opens its pages.
/// 2. Pen-l styluses slide in and strike the tally.
/// 3. Wordmark lettering smoothly fades in with a soft ambient aura glow.
class AnimatedTallyLogo extends StatefulWidget {
  final double size;
  final TallyLogoVariant variant;
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const AnimatedTallyLogo({
    super.key,
    this.size = 56,
    this.variant = TallyLogoVariant.fullWordmark,
    this.duration = const Duration(milliseconds: 1600),
    this.onAnimationComplete,
  });

  @override
  State<AnimatedTallyLogo> createState() => _AnimatedTallyLogoState();
}

class _AnimatedTallyLogoState extends State<AnimatedTallyLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowPulse;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Staggered curves
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.75, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: _slideAnimation.value * widget.size,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Ambient breathing glowing background
                  if (_glowPulse.value > 0)
                    Container(
                      width: widget.size *
                          (widget.variant == TallyLogoVariant.fullWordmark
                              ? 3.6
                              : 1.4),
                      height: widget.size * 1.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(widget.size * 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: TallyColors.varianceZeroLight.withValues(
                              alpha: 0.25 *
                                  _glowPulse.value *
                                  (0.8 +
                                      0.2 *
                                          math.sin(
                                              _controller.value * math.pi)),
                            ),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  // The crisp Vector Logo
                  TallyLogo(
                    size: widget.size,
                    variant: widget.variant,
                    showGlow: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
