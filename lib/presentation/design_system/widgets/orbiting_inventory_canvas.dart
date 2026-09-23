import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Represents an orbiting inventory entity in 3D perspective.
class _OrbitItem {
  final IconData icon;
  final String label;
  final double baseAngle;
  final Color accentColor;

  const _OrbitItem({
    required this.icon,
    required this.label,
    required this.baseAngle,
    required this.accentColor,
  });
}

/// A 3D perspective canvas rendering inventory items orbiting around
/// a central store/ledger emblem along a tilted elliptical axis.
/// Supports true Z-depth sorting, depth scale, and inward convergence.
class OrbitingInventoryCanvas extends StatelessWidget {
  /// Overall size of the canvas.
  final double size;

  /// Continuous rotation value (0.0 to 1.0 representing one full orbit).
  final double orbitAngle;

  /// Convergence progress (0.0 = full orbit radius, 1.0 = condensed into core).
  final double convergenceProgress;

  /// Scale of the central core.
  final double coreScale;

  /// Opacity of the canvas.
  final double opacity;

  const OrbitingInventoryCanvas({
    super.key,
    this.size = 280,
    required this.orbitAngle,
    this.convergenceProgress = 0.0,
    this.coreScale = 1.0,
    this.opacity = 1.0,
  });

  static const List<_OrbitItem> _items = [
    _OrbitItem(
      icon: Icons.inventory_2_rounded,
      label: 'Goods',
      baseAngle: 0,
      accentColor: Color(0xFF38BDF8), // Sky blue
    ),
    _OrbitItem(
      icon: Icons.qr_code_scanner_rounded,
      label: 'Scanner',
      baseAngle: math.pi * 0.5,
      accentColor: TallyColors.varianceZeroLight, // Emerald
    ),
    _OrbitItem(
      icon: Icons.assignment_rounded,
      label: 'Ledger',
      baseAngle: math.pi,
      accentColor: Color(0xFFFBBF24), // Amber
    ),
    _OrbitItem(
      icon: Icons.storefront_rounded,
      label: 'Warehouse',
      baseAngle: math.pi * 1.5,
      accentColor: Color(0xFFA78BFA), // Purple
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _OrbitPainter(
            orbitAngle: orbitAngle,
            convergence: convergenceProgress,
            coreScale: coreScale,
            items: _items,
          ),
        ),
      ),
    );
  }
}

class _CalculatedItem {
  final _OrbitItem item;
  final double x;
  final double y;
  final double z;
  final double scale;
  final double alpha;

  _CalculatedItem({
    required this.item,
    required this.x,
    required this.y,
    required this.z,
    required this.scale,
    required this.alpha,
  });
}

class _OrbitPainter extends CustomPainter {
  final double orbitAngle;
  final double convergence;
  final double coreScale;
  final List<_OrbitItem> items;

  _OrbitPainter({
    required this.orbitAngle,
    required this.convergence,
    required this.coreScale,
    required this.items,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // Radii contract as convergence increases
    final contractFactor = (1.0 - convergence * 0.95).clamp(0.05, 1.0);
    final rx = size.width * 0.42 * contractFactor;
    final ry = size.height * 0.18 * contractFactor;
    const tiltAngle = -0.38; // Radians (tilted 3D plane)

    // Draw faint glowing orbital ring
    final ringPaint = Paint()
      ..color =
          TallyColors.slateMuted.withValues(alpha: 0.15 * (1.0 - convergence))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tiltAngle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      ringPaint,
    );
    canvas.restore();

    // Calculate 3D positions
    final calculated = <_CalculatedItem>[];
    final totalAngle = orbitAngle * 2 * math.pi;

    for (final it in items) {
      final a = totalAngle + it.baseAngle;
      final rawX = rx * math.cos(a);
      final rawY = ry * math.sin(a);
      final z = math.sin(a); // -1 (back) to +1 (front)

      // Apply 2D tilt rotation
      final rotX = rawX * math.cos(tiltAngle) - rawY * math.sin(tiltAngle);
      final rotY = rawX * math.sin(tiltAngle) + rawY * math.cos(tiltAngle);

      final s = (0.65 + 0.45 * ((z + 1.0) / 2.0)) * contractFactor;
      final alpha =
          (0.35 + 0.65 * ((z + 1.0) / 2.0)) * (1.0 - convergence * 0.8);

      calculated.add(
        _CalculatedItem(
          item: it,
          x: cx + rotX,
          y: cy + rotY,
          z: z,
          scale: s,
          alpha: alpha.clamp(0.0, 1.0),
        ),
      );
    }

    // Sort by Z: draw background items (z < 0), then CORE, then foreground items (z >= 0)
    calculated.sort((a, b) => a.z.compareTo(b.z));

    for (final it in calculated) {
      if (it.z < 0) {
        _drawOrbitNode(canvas, it);
      }
    }

    // Draw Central Store & Ledger Core
    _drawCentralCore(canvas, cx, cy, size.width * 0.22 * coreScale);

    for (final it in calculated) {
      if (it.z >= 0) {
        _drawOrbitNode(canvas, it);
      }
    }
  }

  void _drawCentralCore(Canvas canvas, double cx, double cy, double radius) {
    // Ambient radial aura
    final auraPaint = Paint()
      ..color = TallyColors.varianceZeroLight.withValues(alpha: 0.25)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);
    canvas.drawCircle(Offset(cx, cy), radius * 1.3, auraPaint);

    // Core glass circle
    final coreBgPaint = Paint()
      ..color = TallyColors.darkSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, coreBgPaint);

    final coreBorderPaint = Paint()
      ..color = TallyColors.iceFrost.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx, cy), radius, coreBorderPaint);

    // Central stylized ledger & store icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.storefront_rounded.codePoint),
        style: TextStyle(
          fontSize: radius * 1.1,
          fontFamily: Icons.storefront_rounded.fontFamily,
          package: Icons.storefront_rounded.fontPackage,
          color: TallyColors.iceFrost,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(cx - iconPainter.width * 0.5, cy - iconPainter.height * 0.5),
    );
  }

  void _drawOrbitNode(Canvas canvas, _CalculatedItem calc) {
    final nodeR = 18.0 * calc.scale;
    final pos = Offset(calc.x, calc.y);

    // Node glow
    final nodeGlow = Paint()
      ..color = calc.item.accentColor.withValues(alpha: 0.35 * calc.alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, nodeR * 0.6);
    canvas.drawCircle(pos, nodeR * 1.4, nodeGlow);

    // Node bubble background
    final nodeBg = Paint()
      ..color = TallyColors.darkSurface.withValues(alpha: 0.9 * calc.alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, nodeR, nodeBg);

    final nodeBorder = Paint()
      ..color = calc.item.accentColor.withValues(alpha: 0.8 * calc.alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * calc.scale;
    canvas.drawCircle(pos, nodeR, nodeBorder);

    // Draw inventory icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(calc.item.icon.codePoint),
        style: TextStyle(
          fontSize: nodeR * 1.1,
          fontFamily: calc.item.icon.fontFamily,
          package: calc.item.icon.fontPackage,
          color: calc.item.accentColor.withValues(alpha: calc.alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
          calc.x - iconPainter.width * 0.5, calc.y - iconPainter.height * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.orbitAngle != orbitAngle ||
        oldDelegate.convergence != convergence ||
        oldDelegate.coreScale != coreScale;
  }
}
