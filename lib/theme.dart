import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant, harmonious color palette
  static const Color primaryColor = Color(0xFF3F51B5); // Deep Indigo
  static const Color primaryLight = Color(0xFFC5CAE9);
  static const Color primaryDark = Color(0xFF303F9F);

  static const Color accentColor = Color(0xFFFF5722); // Deep Orange
  static const Color accentLight = Color(0xFFFFCCBC);

  static const Color backgroundColor = Color(0xFFF5F7FB);
  static const Color surfaceColor = Colors.white;
  static const Color textDark = Color(0xFF263238);
  static const Color textLight = Color(0xFF78909C);

  // Modern gradients for backgrounds and cards
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, Color(0xFF5C6BC0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor, Color(0xFFFF7043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFE8EAF6), Color(0xFFF5F7FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceColor, Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Premium shadows for modern look
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.08),
      spreadRadius: 2,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> intenseShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.15),
      spreadRadius: 3,
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Global Light Theme Data
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);

    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        secondary: accentColor,
        error: Colors.red[700],
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textLight,
        ),
      ),
      // Changed from CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryLight.withValues(alpha: 0.3), // Updated from withOpacity
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryLight.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryLight.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        labelStyle: GoogleFonts.outfit(color: textLight),
        hintStyle: GoogleFonts.outfit(color: textLight.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      // Changed from DialogTheme to DialogThemeData
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        contentTextStyle: GoogleFonts.outfit(
          fontSize: 16,
          color: textDark.withValues(alpha: 0.8), // Updated from withOpacity
        ),
      ),
    );
  }
}