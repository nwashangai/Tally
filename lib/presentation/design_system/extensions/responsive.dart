import 'package:flutter/material.dart';
import '../tokens/dimensions.dart';

/// Provides responsive layout utilities based on [TallyBreakpoints].
extension TallyResponsive on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isPhone => screenWidth < TallyBreakpoints.tablet;
  bool get isTablet =>
      screenWidth >= TallyBreakpoints.tablet &&
      screenWidth < TallyBreakpoints.desktop;
  bool get isDesktop => screenWidth >= TallyBreakpoints.desktop;
}
