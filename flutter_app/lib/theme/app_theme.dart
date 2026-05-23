import 'package:flutter/material.dart';

/// Port of the design tokens from CLAUDE.md (Stage 1.6 + Stage 1.7 palette
/// flip). The Swift app reads these from the asset catalogue with light/dark
/// variants; here they live as a single source of truth so a future palette
/// swap is a one-file edit, mirroring "edit AccentColor.colorset only".
abstract class AppColors {
  // AccentColor — Deep Royal Blue (#1A4FCC light / #5E8AE6 dark)
  static const accentLight = Color(0xFF1A4FCC);
  static const accentDark = Color(0xFF5E8AE6);

  // SecondaryAccent — Soft Emerald (#10A26B / #34D399)
  static const secondaryLight = Color(0xFF10A26B);
  static const secondaryDark = Color(0xFF34D399);

  // Surfaces
  static const appBgLight = Color(0xFFF7F8FA);
  static const appBgDark = Color(0xFF111317);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1C1F25);
  static const sidebarLight = Color(0xFFF2F4F8);
  static const sidebarDark = Color(0xFF1A1D22);

  // Performance hues (CLAUDE.md): good ≥80 / on-track / behind / critical
  static const good = Color(0xFF2E9E5B);
  static const behind = Color(0xFFE8943A);
  static const critical = Color(0xFFE53935);
}

abstract class AppRadius {
  static const hero = 20.0;
  static const card = 16.0;
  static const note = 14.0;
  static const chip = 10.0;
  static const pill = 8.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentDark : AppColors.accentLight;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      surface: isDark ? AppColors.cardDark : AppColors.cardLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.appBgDark : AppColors.appBgLight,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      // Stats use monospaced digits per CLAUDE.md.
      textTheme: const TextTheme().apply(
        fontFamily: '.SF Pro Text',
      ),
    );
  }
}

/// Performance-hue helper mirroring CLAUDE.md's threshold rule.
Color scoreHue(double composite, ColorScheme scheme) {
  if (composite >= 80) return AppColors.good;
  if (composite >= 65) return scheme.primary; // "on track"
  if (composite >= 50) return AppColors.behind;
  return AppColors.critical;
}
