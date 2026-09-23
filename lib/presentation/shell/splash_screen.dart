import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/splash/splash_state_provider.dart';
import '../design_system/tokens/colors.dart';
import '../design_system/tokens/dimensions.dart';
import '../design_system/widgets/orbiting_inventory_canvas.dart';
import '../design_system/widgets/progressive_tally_writer.dart';

/// Full-featured, cinematic splash screen for Tally.
/// Orchestrates:
/// 1. 3D planetary orbit of inventory entities (Goods, Scanner, Ledger, Warehouse)
///    collapsing into the central store core.
/// 2. Progressive stylus draw-in and vector reveal of the "Tally" wordmark.
/// 3. Tagline and encryption status settlement.
/// 4. Timed completion triggering GoRouter navigation.
class SplashScreen extends ConsumerStatefulWidget {
  /// Total duration of the splash sequence.
  final Duration animationDuration;

  const SplashScreen({
    super.key,
    this.animationDuration = const Duration(milliseconds: 2600),
  });

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase 1: 3D Orbit & Condensation (0.0 -> 0.45)
  late final Animation<double> _orbitAngle;
  late final Animation<double> _orbitConvergence;
  late final Animation<double> _orbitOpacity;

  // Phase 2: Progressive Pen Writing & Wordmark Reveal (0.40 -> 0.85)
  late final Animation<double> _writeProgress;
  late final Animation<double> _wordmarkOpacity;

  // Phase 3: Tagline & Badges Fade-In (0.75 -> 1.0)
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // 1. Orbit animations (0.0 -> 0.45)
    _orbitAngle = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOutCubic),
      ),
    );

    _orbitConvergence = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.45, curve: Curves.easeInBack),
      ),
    );

    _orbitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.48, curve: Curves.easeOut),
      ),
    );

    // 2. Wordmark write animations (0.42 -> 0.85)
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.50, curve: Curves.easeIn),
      ),
    );

    _writeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Tagline & Footer animations (0.75 -> 1.0)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        ref.read(splashCompletedProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TallyColors.primaryNavy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.15),
            radius: 1.3,
            colors: [
              Color(0xFF1E293B), // Slate 800
              TallyColors.primaryNavy, // Deep navy
              Color(0xFF070D18), // Deep obsidian
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: [
                  // Center stage containing both the 3D Orbit and the progressive Wordmark
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: TallySpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Stage 1: 3D Orbiting Inventory
                                if (_orbitOpacity.value > 0.01)
                                  OrbitingInventoryCanvas(
                                    size: 240,
                                    orbitAngle: _orbitAngle.value,
                                    convergenceProgress:
                                        _orbitConvergence.value,
                                    opacity: _orbitOpacity.value,
                                  ),

                                // Stage 2: Progressive Pen-Written Tally Logo
                                if (_wordmarkOpacity.value > 0.01)
                                  Opacity(
                                    opacity: _wordmarkOpacity.value,
                                    child: ProgressiveTallyWriter(
                                      size: 64,
                                      writeProgress: _writeProgress.value,
                                      isCompleted: _writeProgress.value >= 0.99,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TallySpacing.md),

                          // Stage 3: Taglines
                          Opacity(
                            opacity: _taglineOpacity.value,
                            child: SlideTransition(
                              position: _taglineSlide,
                              child: Column(
                                children: [
                                  Text(
                                    'Offline-First Inventory Ledger',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: TallyColors.iceFrost
                                          .withValues(alpha: 0.95),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: TallySpacing.xs),
                                  const Text(
                                    'Precision Stock Balancing',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: TallyColors.slateMuted,
                                      fontSize: 13,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Encryption & Security Status
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: TallySpacing.xxl,
                    child: Opacity(
                      opacity: _taglineOpacity.value,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TallySpacing.md,
                            vertical: TallySpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color:
                                TallyColors.darkSurface.withValues(alpha: 0.65),
                            borderRadius:
                                BorderRadius.circular(TallyRadii.full),
                            border: Border.all(
                              color: TallyColors.lightBorder
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 13,
                                color: TallyColors.varianceZeroLight,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Encrypted Local Storage Active',
                                style: TextStyle(
                                  color: TallyColors.slateMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
