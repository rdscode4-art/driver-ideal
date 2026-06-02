import 'package:flutter/material.dart';

class AppTheme {
  // RiDeal brand colors matching the logo
  static final Color primary = Colors.orange[600]!; // Primary orange
  static final Color primaryLight = Colors.orange[400]!; // Light orange
  static final Color secondary = Colors.green[600]!; // Secondary green
  static final Color secondaryLight = Colors.green[400]!; // Light green
  static const Color accent = Colors.white;
  static const Color background = Color(0xFFF9F9F9); // Lighter background
  static const Color card = Color(0xFFFFFFFF);
  static const Color online = Color(0xFF43A047); // Modern green
  static const Color offline = Color(0xFFE53935); // Modern red
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);

  static ThemeData get themeData => ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: primary,
      foregroundColor: accent,
      elevation: 3,
      iconTheme: const IconThemeData(color: accent),
      titleTextStyle: const TextStyle(
        color: accent,
        fontWeight: FontWeight.w900,
        fontSize: 22,
        letterSpacing: 1.1,
      ),
      shadowColor: shadow,
      centerTitle: true,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      primary: primary,
      secondary: accent,
      background: background,
      surface: card,
      onPrimary: accent,
      onSecondary: primary,
      onBackground: textPrimary,
      onSurface: textPrimary,
      brightness: Brightness.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: primary,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: shadow,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: accent, width: 2),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accent, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
      hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
      prefixIconColor: accent,
    ),
    cardTheme: CardThemeData(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 10,
      shadowColor: shadow,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
    ),
    textTheme: TextTheme(
      titleLarge: const TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w900,
        fontSize: 22,
        letterSpacing: 0.5,
      ),
      bodyMedium: const TextStyle(
        color: textSecondary,
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: textSecondary.withOpacity(0.8),
        fontSize: 14,
      ),
      labelLarge: const TextStyle(
        color: accent,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    iconTheme: const IconThemeData(color: accent, size: 26),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: primary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: const TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 16,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: border,
      circularTrackColor: border,
    ),
    shadowColor: shadow,
    highlightColor: accent.withOpacity(0.08),
    splashColor: accent.withOpacity(0.14),
    hoverColor: accent.withOpacity(0.10),
    focusColor: accent.withOpacity(0.18),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: true,
  );
}
