import 'package:flutter/material.dart';

/// Tally official color palette tokens (ADR 0004).
///
/// Do NOT use raw hex literals in widget code.
/// Always reference these tokens to stay consistent.
abstract final class TallyColors {
  // ---------------------------------------------------------------------------
  // Primary triad
  // ---------------------------------------------------------------------------

  /// Deep Midnight Navy — dark mode surfaces, light mode text & brand buttons.
  static const primaryNavy = Color(0xFF172A45);

  /// Muted Steel Blue — secondary text, unselected icons, subtle dividers.
  static const slateMuted = Color(0xFF8892B0);

  /// Ice Frost Tint — light mode input fills, badges, active card accents;
  /// dark mode high-contrast primary text.
  static const iceFrost = Color(0xFFE6F1FF);

  /// Pure White — light mode canvas background (ADR 0004 update).
  static const canvasWhite = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Dark mode surface ramp
  // ---------------------------------------------------------------------------

  static const darkCanvas = Color(0xFF0A192F);
  static const darkSurface = Color(0xFF172A45); // == primaryNavy
  static const darkElevatedSurface = Color(0xFF1E3A5F);
  static const darkBorder = Color(0xFF233554);

  // ---------------------------------------------------------------------------
  // Light mode surface ramp
  // ---------------------------------------------------------------------------

  static const lightCanvas = canvasWhite;
  static const lightSecondaryContainer = iceFrost;
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightBorderStrong = Color(0xFFD1DDF0);

  // ---------------------------------------------------------------------------
  // Semantic / inventory status tokens
  // ---------------------------------------------------------------------------

  /// Stock count matches expected — zero variance. (Light surfaces)
  static const varianceZeroLight = Color(0xFF10B981);

  /// Stock count matches expected — zero variance. (Dark surfaces)
  static const varianceZeroDark = Color(0xFF64FFDA);

  /// Variance detected: shortage or surplus requiring review.
  static const varianceDiscrepancy = Color(0xFFF59E0B);

  /// Critical: negative stock, out-of-stock, or missing item.
  static const stockCritical = Color(0xFFEF4444);

  /// Active count session indicator and stepper focus accent.
  static const tallyActive = Color(0xFF38BDF8);
}
