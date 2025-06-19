import 'package:flutter/material.dart';

class AppStyles {
  static const Color primaryColor = Color(0xFFC53030);
  static const Color scaffoldBackgroundColor = Color(0xFFF9FAFB);
  static const Color accentColor = Color(0xFF2D3748);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE2E8F0);

  static ThemeData getTheme({bool dark = false}) {
    final isDark = dark;
    final Color darkPrimary = Color(0xFF23272F);
    final Color darkCard = Color(0xFF2D2F36);
    final Color darkBorder = Color(0xFF44474F);
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor, // Always use the same red
      secondary: isDark ? Colors.white : accentColor,
      surface: isDark ? darkCard : cardColor,
      background: isDark ? darkPrimary : scaffoldBackgroundColor,
      brightness: brightness, // Ensure brightness matches
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: isDark ? darkPrimary : scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.white : primaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
            fontSize: 17,
            color: isDark ? Colors.white70 : accentColor,
            height: 1.5),
        labelLarge: TextStyle(fontWeight: FontWeight.w700, color: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 8,
          shadowColor: primaryColor.withAlpha((0.2 * 255).toInt()),
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? darkCard.withAlpha((0.95 * 255).toInt())
            : cardColor.withAlpha((0.95 * 255).toInt()),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? darkBorder : borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      cardTheme: CardThemeData(
        color: isDark
            ? darkCard.withAlpha((0.98 * 255).toInt())
            : cardColor.withAlpha((0.98 * 255).toInt()),
        elevation: 8,
        margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadowColor: primaryColor.withAlpha((0.10 * 255).toInt()),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? darkCard.withAlpha((0.98 * 255).toInt())
            : cardColor.withAlpha((0.98 * 255).toInt()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 12,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        contentTextStyle: TextStyle(
          fontSize: 17,
          color: isDark ? Colors.white70 : accentColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      splashColor: primaryColor.withAlpha((0.12 * 255).toInt()),
      highlightColor: primaryColor.withAlpha((0.08 * 255).toInt()),
      hoverColor: primaryColor.withAlpha((0.06 * 255).toInt()),
    );
  }
}
