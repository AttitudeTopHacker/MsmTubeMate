import 'package:flutter/material.dart';

class AppTheme {
  // PRD Color Palette Constants
  static const Color backgroundMidnight = Color(0xFF090D16);
  static const Color backgroundNavy = Color(0xFF111827);
  static const Color backgroundDeepPurple = Color(0xFF1E1B4B);

  // Ambient Radial Orb Colors
  static const Color orbCyan = Color(0xFF00F5D4);
  static const Color orbViolet = Color(0xFF7B2CBF);
  static const Color orbBlue = Color(0xFF3A86FF);

  // Primary Accent Gradient Colors
  static const Color accentCyan = Color(0xFF00F5D4);
  static const Color accentBlue = Color(0xFF3A86FF);
  static const Color accentViolet = Color(0xFF7B2CBF);
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentBlue],
  );

  // Glass Surface Constants
  static Color glassSurface = Colors.white.withValues(alpha: 0.08);
  static Color glassElevatedModal = const Color(0xFF131A2B).withValues(alpha: 0.75);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundMidnight,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentBlue,
        surface: Color(0xFF101625),
        onPrimary: Color(0xFF090D16),
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
