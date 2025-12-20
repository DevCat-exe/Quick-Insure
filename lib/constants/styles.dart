import 'package:flutter/material.dart';

class AppStyles {
  // Premium Color Palette
  static const Color primaryColor = Color(0xFFE53E3E); // Vibrant Red
  static const Color primaryDark = Color(0xFFC53030);
  static const Color accentColor = Color(0xFF2D3748);
  static const Color scaffoldBackgroundColor = Color(0xFFF7FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE2E8F0);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF56565), Color(0xFFE53E3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getGlassGradient(bool isDark) {
    return LinearGradient(
      colors: isDark
          ? [Colors.white.withAlpha(20), Colors.white.withAlpha(10)]
          : [Colors.white.withAlpha(200), Colors.white.withAlpha(150)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData getTheme({bool dark = false}) {
    final isDark = dark;
    final Color darkPrimary = Color(0xFF111827); // Deeper dark
    final Color darkCard = Color(0xFF374151); // Slate dark
    final Color darkBorder = Color(0xFF4A5568);

    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: isDark ? Colors.white : accentColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: isDark ? darkPrimary : scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : accentColor,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : accentColor),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          color: isDark ? Colors.white : accentColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primaryColor,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color:
              isDark ? Colors.white.withAlpha(200) : accentColor.withAlpha(220),
          height: 1.6,
        ),
        labelLarge: TextStyle(fontWeight: FontWeight.w800, color: primaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: primaryColor.withAlpha(100),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard.withAlpha(150) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? darkBorder : borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? darkBorder : borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? darkCard : cardColor,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(20)
                : borderColor.withAlpha(100),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkPrimary : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 24,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: primaryColor,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white.withAlpha(200) : accentColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: accentColor,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
      ),
    );
  }
}
