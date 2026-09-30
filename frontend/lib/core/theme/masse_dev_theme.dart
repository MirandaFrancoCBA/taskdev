import 'package:flutter/material.dart';

abstract final class MasseDevTokens {
  static const brandPurple = Color(0xFF6D3CCF);
  static const brandBlue = Color(0xFF249DCE);
  static const ink = Color(0xFF182033);
  static const mutedInk = Color(0xFF667085);
  static const canvas = Color(0xFFF7F8FC);
  static const surface = Colors.white;

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;

  static const radiusSm = 10.0;
  static const radiusMd = 16.0;
  static const radiusLg = 24.0;

  static const pageMaxWidth = 1180.0;
}

abstract final class TaskDevTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: MasseDevTokens.brandPurple,
      brightness: Brightness.light,
      surface: MasseDevTokens.surface,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MasseDevTokens.canvas,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MasseDevTokens.canvas,
        foregroundColor: MasseDevTokens.ink,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: MasseDevTokens.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MasseDevTokens.radiusMd),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MasseDevTokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MasseDevTokens.radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MasseDevTokens.radiusSm),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MasseDevTokens.radiusSm),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MasseDevTokens.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
