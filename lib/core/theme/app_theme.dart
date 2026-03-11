import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────
  static const primary    = Color(0xFF0725B0); // City Hunter Blue
  static const secondary  = Color(0xFF6B4A3A); // Birdhouse Brown
  static const background = Color(0xFFE5DED4); // Modest White
  static const inputFill  = Color(0xFFF2EFEA); // Nano White
  static const textDark   = Color(0xFF3E3A36); // Brownish Black
  static const cardWhite  = Color(0xFFFFFFFF);

  // ── Theme ──────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: cardWhite,
          error: const Color(0xFFBA1A1A),
        ).copyWith(
          onSurface: textDark,
        ),
        scaffoldBackgroundColor: background,

        // Typography: Fredoka for display, Poppins for body
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge:  GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          displayMedium: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          displaySmall:  GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.fredoka(fontWeight: FontWeight.w600),
          headlineMedium:GoogleFonts.fredoka(fontWeight: FontWeight.w500),
          headlineSmall: GoogleFonts.fredoka(fontWeight: FontWeight.w500),
          titleLarge:    GoogleFonts.fredoka(fontWeight: FontWeight.w500),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: GoogleFonts.poppins(
            color: const Color(0xFF7A7570),
            fontSize: 14,
          ),
          prefixIconColor: const Color(0xFF7A7570),
          suffixIconColor: const Color(0xFF7A7570),
        ),

        // Filled button
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primary.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.fredoka(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
