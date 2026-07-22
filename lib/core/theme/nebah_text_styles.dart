import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nebah Design System Typography (Inter Font Family)
class NebahTextStyles {
  static TextStyle displayLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      );

  static TextStyle headlineMedium(bool isDark) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      );

  static TextStyle titleLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      );

  static TextStyle bodyLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
      );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      );

  static TextStyle labelSmall(bool isDark) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      );
}
