import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF0B6B3A);
  static const Color primaryContainerColor = Color(0xFFE4F3EA);
  static const Color onPrimaryContainerColor = Color(0xFF0B6B3A);

  static const Color secondaryColor = Color(0xFF3E6A58);
  static const Color secondaryContainerColor = Color(0xFFEAF3EE);
  static const Color onSecondaryContainerColor = Color(0xFF446455);

  static const Color tertiaryColor = Color(0xFF0E5230);
  static const Color tertiaryContainerColor = Color(0xFFDDF3E8);
  static const Color onTertiaryContainerColor = Color(0xFF2B6B49);

  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F7F6);
  static const Color surfaceContainer = Color(0xFFEFF4F0);
  static const Color surfaceContainerHigh = Color(0xFFE6ECE8);
  static const Color surfaceContainerHighest = Color(0xFFDCE4DF);
  static const Color surfaceVariantColor = Color(0xFFE8EEEA);

  static const Color textPrimaryColor = Color(0xFF15211A);
  static const Color textSecondaryColor = Color(0xFF5B6A62);
  static const Color outlineColor = Color(0xFF87948D);
  static const Color outlineVariantColor = Color(0xFFD7E1DB);

  // Status Colors (from Stitch specifications)
  static const Color statusHigh = Color(0xFFBA1A1A); // High Priority Red
  static const Color statusHighContainer = Color(0xFFFFDAD6);
  static const Color statusMedium = Color(0xFFF97316); // Amber/Orange
  static const Color statusLow = Color(0xFF10B981); // Mint Green/Low Priority

  // Tonal fixed colors
  static const Color primaryFixed = Color(0xFFC1ECD4);
  static const Color primaryFixedDim = Color(0xFFA5D0B9);
  static const Color tertiaryFixed = Color(0xFFB0F1CC);
  static const Color tertiaryFixedDim = Color(0xFF94D4B1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryContainerColor,
        onPrimaryContainer: onPrimaryContainerColor,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainerColor,
        onSecondaryContainer: onSecondaryContainerColor,
        tertiary: tertiaryColor,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryContainerColor,
        onTertiaryContainer: onTertiaryContainerColor,
        error: statusHigh,
        onError: Colors.white,
        errorContainer: statusHighContainer,
        surface: surfaceColor,
        onSurface: textPrimaryColor,
        surfaceContainerHighest: surfaceVariantColor,
        onSurfaceVariant: textSecondaryColor,
        outline: outlineColor,
        outlineVariant: outlineVariantColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
          letterSpacing: -0.02,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          color: textSecondaryColor,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
