/// Tally spacing scale tokens.
///
/// All spacing in the application (padding, margin, gap) must be expressed as
/// multiples of the base unit (4dp).
abstract final class TallySpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Tally border radius tokens.
abstract final class TallyRadii {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 9999;
}

/// Tally elevation levels (Material elevation in dp).
abstract final class TallyElevation {
  static const double none = 0;
  static const double low = 1;
  static const double card = 2;
  static const double modal = 8;
  static const double overlay = 16;
}

/// Minimum interaction target dimensions to meet WCAG 2.1 / platform guidelines.
abstract final class TallyTargetSize {
  static const double minimum = 48; // 48x48 dp minimum touch/click target
}

/// Responsive layout breakpoints.
abstract final class TallyBreakpoints {
  static const double phone = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
}
