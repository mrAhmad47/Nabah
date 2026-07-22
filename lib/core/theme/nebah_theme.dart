import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nebah_colors.dart';

/// Nebah Modern Security-Tech ThemeData Configuration
class NebahTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NebahColors.darkBackground,
      primaryColor: NebahColors.darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: NebahColors.darkPrimary,
        secondary: NebahColors.darkSecondary,
        surface: NebahColors.darkSurface,
        error: NebahColors.darkEmergency,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: NebahColors.darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: NebahColors.darkTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: NebahColors.darkTextPrimary, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: NebahColors.darkTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: NebahColors.darkTextPrimary),
        bodyMedium: GoogleFonts.inter(color: NebahColors.darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NebahColors.darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: NebahColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: NebahColors.darkPrimary),
      ),
      cardTheme: CardThemeData(
        color: NebahColors.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NebahColors.lightBackground,
      primaryColor: NebahColors.lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: NebahColors.lightPrimary,
        secondary: NebahColors.lightSecondary,
        surface: NebahColors.lightSurface,
        error: NebahColors.lightEmergency,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: NebahColors.lightTextPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: NebahColors.lightTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.inter(color: NebahColors.lightTextPrimary, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.inter(color: NebahColors.lightTextPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: NebahColors.lightTextPrimary),
        bodyMedium: GoogleFonts.inter(color: NebahColors.lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NebahColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: NebahColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: NebahColors.lightPrimary),
      ),
      cardTheme: CardThemeData(
        color: NebahColors.lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NebahColors.lightBorder),
        ),
      ),
    );
  }
}
