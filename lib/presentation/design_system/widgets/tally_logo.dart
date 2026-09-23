import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Supported layout variants for the Tally logo.
enum TallyLogoVariant {
  /// Standalone emblem mark (Book-T + Pen-l emblem).
  markOnly,

  /// Complete typographic wordmark with custom Book 'T' and Pen 'l's.
  fullWordmark,

  /// Side-by-side mark + clean text wordmark.
  horizontalWithMark,
}

/// A crisp, scalable vector-drawn logo for Tally.
/// Features a ledger/record book styled capital 'T' and precision pen styled 'l's.
class TallyLogo extends StatelessWidget {
  /// Desired height/size of the logo.
  final double size;

  /// Primary color of the logo.
  final Color primaryColor;

  /// Accent color used for ledger bookmark ribbon, pen nib, and highlights.
  final Color accentColor;

  /// Layout variant to render.
  final TallyLogoVariant variant;

  /// Whether to render a soft ambient glow/shadow.
  final bool showGlow;

  const TallyLogo({
    super.key,
    this.size = 48,
    this.primaryColor = TallyColors.iceFrost,
    this.accentColor = TallyColors.varianceZeroLight,
    this.variant = TallyLogoVariant.fullWordmark,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case TallyLogoVariant.markOnly:
        return _buildMark();
      case TallyLogoVariant.fullWordmark:
        return _buildFullWordmark();
      case TallyLogoVariant.horizontalWithMark:
        return _buildHorizontalWithMark();
    }
  }

  Widget _buildMark() {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TallyEmblemPainter(
          primaryColor: primaryColor,
          accentColor: accentColor,
          showGlow: showGlow,
        ),
      ),
    );
  }

  Widget _buildFullWordmark() {
    // Width is roughly 3.2x the height for the balanced 5-letter wordmark
    final width = size * 3.4;
    return SizedBox(
      width: width,
      height: size,
      child: CustomPaint(
        painter: _TallyWordmarkPainter(
          primaryColor: primaryColor,
          accentColor: accentColor,
          showGlow: showGlow,
        ),
      ),
    );
  }

  Widget _buildHorizontalWithMark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMark(),
        SizedBox(width: size * 0.25),
        Text(
          'Tally',
          style: TextStyle(
            color: primaryColor,
            fontSize: size * 0.75,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the standalone Tally emblem (Ledger Book 'T' + Pen 'l').
class _TallyEmblemPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool showGlow;

  _TallyEmblemPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (showGlow) {
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.2);
      canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.4, glowPaint);
    }

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // --- Book 'T' Design ---
    // 1. Book Top Bar (open ledger covers with gentle curve)
    // Left open book page
    final leftPage = Path()
      ..moveTo(w * 0.12, h * 0.18)
      ..quadraticBezierTo(w * 0.3, h * 0.12, w * 0.48, h * 0.18)
      ..lineTo(w * 0.48, h * 0.32)
      ..quadraticBezierTo(w * 0.3, h * 0.26, w * 0.12, h * 0.32)
      ..close();
    canvas.drawPath(leftPage, primaryPaint);

    // Right open book page
    final rightPage = Path()
      ..moveTo(w * 0.52, h * 0.18)
      ..quadraticBezierTo(w * 0.7, h * 0.12, w * 0.88, h * 0.18)
      ..lineTo(w * 0.88, h * 0.32)
      ..quadraticBezierTo(w * 0.7, h * 0.26, w * 0.52, h * 0.32)
      ..close();
    canvas.drawPath(rightPage, primaryPaint);

    // 2. Book Spine / Stem of the 'T'
    final stemPath = Path()
      ..moveTo(w * 0.42, h * 0.28)
      ..lineTo(w * 0.58, h * 0.28)
      ..lineTo(w * 0.56, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.44, h * 0.82)
      ..close();
    canvas.drawPath(stemPath, primaryPaint);

    // 3. Ledger Bookmark Ribbon (Accent)
    final ribbonPath = Path()
      ..moveTo(w * 0.48, h * 0.22)
      ..lineTo(w * 0.52, h * 0.22)
      ..lineTo(w * 0.52, h * 0.70)
      ..lineTo(w * 0.50, h * 0.65)
      ..lineTo(w * 0.48, h * 0.70)
      ..close();
    canvas.drawPath(ribbonPath, accentPaint);

    // --- Pen / Stylus Accent on the right side ---
    final penPath = Path()
      // Pen body
      ..moveTo(w * 0.72, h * 0.35)
      ..lineTo(w * 0.80, h * 0.35)
      ..lineTo(w * 0.80, h * 0.75)
      // Pen Nib tip
      ..lineTo(w * 0.76, h * 0.88)
      ..lineTo(w * 0.72, h * 0.75)
      ..close();
    canvas.drawPath(penPath, primaryPaint);

    // Pen Nib accent dot / tip
    final nibTip = Path()
      ..moveTo(w * 0.74, h * 0.80)
      ..lineTo(w * 0.78, h * 0.80)
      ..lineTo(w * 0.76, h * 0.88)
      ..close();
    canvas.drawPath(nibTip, accentPaint);

    // Pen clip
    final clipPath = Path()
      ..moveTo(w * 0.70, h * 0.40)
      ..lineTo(w * 0.72, h * 0.40)
      ..lineTo(w * 0.72, h * 0.56)
      ..lineTo(w * 0.70, h * 0.54)
      ..close();
    canvas.drawPath(clipPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _TallyEmblemPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.showGlow != showGlow;
  }
}

/// Custom painter for the complete "Tally" wordmark with:
/// - 'T' : Stylized Ledger/Record Book
/// - 'a' : Crisp geometric ledger letter
/// - 'l' : Precision Counting Pen 1
/// - 'l' : Precision Tally Pen 2
/// - 'y' : Sleek geometric descender
class _TallyWordmarkPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool showGlow;

  _TallyWordmarkPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (showGlow) {
      final glowPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.1, w, h * 0.8),
          Radius.circular(h * 0.3),
        ),
        glowPaint,
      );
    }

    final primaryPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final accentPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // We divide horizontal space across the 5 glyphs: T, a, l, l, y
    // Base unit metrics:
    final tW = w * 0.22;
    final aW = w * 0.18;
    final l1W = w * 0.14;
    final l2W = w * 0.14;
    final yW = w * 0.18;
    final spacing = w * 0.035;

    var curX = w * 0.02;

    // -------------------------------------------------------------
    // 1. Letter 'T' : Ledger / Record Book
    // -------------------------------------------------------------
    final leftPage = Path()
      ..moveTo(curX + tW * 0.05, h * 0.20)
      ..quadraticBezierTo(
          curX + tW * 0.30, h * 0.14, curX + tW * 0.48, h * 0.20)
      ..lineTo(curX + tW * 0.48, h * 0.33)
      ..quadraticBezierTo(
          curX + tW * 0.30, h * 0.27, curX + tW * 0.05, h * 0.33)
      ..close();
    canvas.drawPath(leftPage, primaryPaint);

    final rightPage = Path()
      ..moveTo(curX + tW * 0.52, h * 0.20)
      ..quadraticBezierTo(
          curX + tW * 0.70, h * 0.14, curX + tW * 0.95, h * 0.20)
      ..lineTo(curX + tW * 0.95, h * 0.33)
      ..quadraticBezierTo(
          curX + tW * 0.70, h * 0.27, curX + tW * 0.52, h * 0.33)
      ..close();
    canvas.drawPath(rightPage, primaryPaint);

    final tStem = Path()
      ..moveTo(curX + tW * 0.40, h * 0.30)
      ..lineTo(curX + tW * 0.60, h * 0.30)
      ..lineTo(curX + tW * 0.58, h * 0.85)
      ..lineTo(curX + tW * 0.42, h * 0.85)
      ..close();
    canvas.drawPath(tStem, primaryPaint);

    // Book Ribbon Accent
    final tRibbon = Path()
      ..moveTo(curX + tW * 0.48, h * 0.22)
      ..lineTo(curX + tW * 0.52, h * 0.22)
      ..lineTo(curX + tW * 0.52, h * 0.65)
      ..lineTo(curX + tW * 0.50, h * 0.60)
      ..lineTo(curX + tW * 0.48, h * 0.65)
      ..close();
    canvas.drawPath(tRibbon, accentPaint);

    curX += tW + spacing;

    // -------------------------------------------------------------
    // 2. Letter 'a' : Geometric Inventory Ledger Glyph
    // -------------------------------------------------------------
    final aPath = Path();
    final aRect =
        Rect.fromLTWH(curX + aW * 0.05, h * 0.42, aW * 0.80, h * 0.43);
    aPath.addOval(aRect);
    // Vertical stem of 'a'
    final aStem = RRect.fromRectAndRadius(
      Rect.fromLTWH(curX + aW * 0.72, h * 0.42, aW * 0.20, h * 0.43),
      Radius.circular(h * 0.02),
    );
    canvas.drawPath(aPath, primaryPaint);
    canvas.drawRRect(aStem, primaryPaint);

    // Inner cutout for 'a'
    final aCutout = Paint()
      ..color = const Color(0x00000000)
      ..blendMode = BlendMode.clear;
    canvas.drawOval(
      Rect.fromLTWH(curX + aW * 0.25, h * 0.54, aW * 0.40, h * 0.20),
      aCutout,
    );

    curX += aW + spacing;

    // -------------------------------------------------------------
    // 3. Letter 'l' (First Pen) : Counting Pen with Nib & Clip
    // -------------------------------------------------------------
    final l1PenBody = Path()
      ..moveTo(curX + l1W * 0.25, h * 0.18)
      ..lineTo(curX + l1W * 0.65, h * 0.18)
      ..lineTo(curX + l1W * 0.65, h * 0.72)
      ..lineTo(curX + l1W * 0.45, h * 0.85) // Pen tip
      ..lineTo(curX + l1W * 0.25, h * 0.72)
      ..close();
    canvas.drawPath(l1PenBody, primaryPaint);

    // Pen Nib Accent
    final l1Nib = Path()
      ..moveTo(curX + l1W * 0.32, h * 0.74)
      ..lineTo(curX + l1W * 0.58, h * 0.74)
      ..lineTo(curX + l1W * 0.45, h * 0.85)
      ..close();
    canvas.drawPath(l1Nib, accentPaint);

    // Pen Clip
    final l1Clip = Path()
      ..moveTo(curX + l1W * 0.15, h * 0.22)
      ..lineTo(curX + l1W * 0.25, h * 0.22)
      ..lineTo(curX + l1W * 0.25, h * 0.42)
      ..lineTo(curX + l1W * 0.15, h * 0.40)
      ..close();
    canvas.drawPath(l1Clip, accentPaint);

    curX += l1W + spacing;

    // -------------------------------------------------------------
    // 4. Letter 'l' (Second Pen) : Tally Stylus with Top Cap
    // -------------------------------------------------------------
    final l2PenBody = Path()
      ..moveTo(curX + l2W * 0.25, h * 0.18)
      ..lineTo(curX + l2W * 0.65, h * 0.18)
      ..lineTo(curX + l2W * 0.65, h * 0.72)
      ..lineTo(curX + l2W * 0.45, h * 0.85) // Pen tip
      ..lineTo(curX + l2W * 0.25, h * 0.72)
      ..close();
    canvas.drawPath(l2PenBody, primaryPaint);

    // Pen Nib Accent
    final l2Nib = Path()
      ..moveTo(curX + l2W * 0.32, h * 0.74)
      ..lineTo(curX + l2W * 0.58, h * 0.74)
      ..lineTo(curX + l2W * 0.45, h * 0.85)
      ..close();
    canvas.drawPath(l2Nib, accentPaint);

    // Stylus top cap accent
    final l2Cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(curX + l2W * 0.20, h * 0.14, l2W * 0.50, h * 0.05),
      Radius.circular(h * 0.015),
    );
    canvas.drawRRect(l2Cap, accentPaint);

    curX += l2W + spacing;

    // -------------------------------------------------------------
    // 5. Letter 'y' : Clean Modern Descender with Stock Tally Angle
    // -------------------------------------------------------------
    final yLeftArm = Path()
      ..moveTo(curX + yW * 0.08, h * 0.42)
      ..lineTo(curX + yW * 0.28, h * 0.42)
      ..lineTo(curX + yW * 0.52, h * 0.66)
      ..lineTo(curX + yW * 0.36, h * 0.66)
      ..close();
    canvas.drawPath(yLeftArm, primaryPaint);

    final yRightStem = Path()
      ..moveTo(curX + yW * 0.72, h * 0.42)
      ..lineTo(curX + yW * 0.92, h * 0.42)
      ..lineTo(curX + yW * 0.25, h * 0.98) // Descender
      ..lineTo(curX + yW * 0.08, h * 0.98)
      ..close();
    canvas.drawPath(yRightStem, primaryPaint);

    // Bottom accent dot for 'y' tally closure
    final yDot = Rect.fromCircle(
      center: Offset(curX + yW * 0.12, h * 0.95),
      radius: h * 0.03,
    );
    canvas.drawOval(yDot, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _TallyWordmarkPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.showGlow != showGlow;
  }
}
