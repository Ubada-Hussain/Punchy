import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.teal,
        secondary: AppColors.coral,
        surface: AppColors.surface,
        error: AppColors.coralDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w800),
        titleMedium: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w700),
        titleSmall: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w700),
        bodyLarge: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, fontWeight: FontWeight.w500),
        labelLarge: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkFaint, fontSize: 13.5, fontWeight: FontWeight.w500),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
