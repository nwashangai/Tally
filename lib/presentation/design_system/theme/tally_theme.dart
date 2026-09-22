import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Tally ThemeData factory.
/// Generates both light and dark [ThemeData] instances from the official color tokens.
abstract final class TallyTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? TallyColors.darkCanvas : TallyColors.lightCanvas,
      cardTheme: CardThemeData(
        color: isDark ? TallyColors.darkSurface : TallyColors.canvasWhite,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? TallyColors.darkSurface : TallyColors.primaryNavy,
        foregroundColor: TallyColors.iceFrost,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? TallyColors.darkBorder : TallyColors.lightBorder,
        thickness: 1,
      ),
      textTheme: _textTheme(isDark),
      iconTheme: IconThemeData(
        color: isDark ? TallyColors.iceFrost : TallyColors.primaryNavy,
        size: 24,
      ),
    );
  }

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: TallyColors.primaryNavy,
    onPrimary: TallyColors.canvasWhite,
    secondary: TallyColors.slateMuted,
    onSecondary: TallyColors.canvasWhite,
    surface: TallyColors.canvasWhite,
    onSurface: TallyColors.primaryNavy,
    error: TallyColors.stockCritical,
    onError: TallyColors.canvasWhite,
    primaryContainer: TallyColors.iceFrost,
    onPrimaryContainer: TallyColors.primaryNavy,
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: TallyColors.iceFrost,
    onPrimary: TallyColors.primaryNavy,
    secondary: TallyColors.slateMuted,
    onSecondary: TallyColors.darkSurface,
    surface: TallyColors.darkSurface,
    onSurface: TallyColors.iceFrost,
    error: TallyColors.stockCritical,
    onError: TallyColors.darkCanvas,
    primaryContainer: TallyColors.darkElevatedSurface,
    onPrimaryContainer: TallyColors.iceFrost,
  );

  static TextTheme _textTheme(bool isDark) {
    final base = isDark ? TallyColors.iceFrost : TallyColors.primaryNavy;
    const muted = TallyColors.slateMuted;
    return TextTheme(
      displayLarge: TextStyle(
        color: base,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
      ),
      headlineLarge: TextStyle(
        color: base,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: base,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: base,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: base,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(color: base, fontSize: 16),
      bodyMedium: TextStyle(color: base, fontSize: 14),
      bodySmall: const TextStyle(color: muted, fontSize: 12),
      labelSmall:
          const TextStyle(color: muted, fontSize: 11, letterSpacing: 0.5),
    );
  }
}
