import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF012D1D); // Deep Forest Green
  static const Color primaryContainerColor = Color(0xFF1B4332);
  static const Color onPrimaryContainerColor = Color(0xFF86AF99);

  static const Color secondaryColor = Color(0xFF57615C);
  static const Color secondaryContainerColor = Color(0xFFD8E2DC);
  static const Color onSecondaryContainerColor = Color(0xFF5B6560);

  static const Color tertiaryColor = Color(0xFF002D1B);
  static const Color tertiaryContainerColor = Color(0xFF00452D);
  static const Color onTertiaryContainerColor = Color(0xFF74B392);

  static const Color backgroundColor = Color(
    0xFFF8F9FA,
  ); // Soft Earthy Light Grey
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceVariantColor = Color(0xFFE1E3E4);

  static const Color textPrimaryColor = Color(0xFF191C1D);
  static const Color textSecondaryColor = Color(
    0xFF414844,
  ); // on-surface-variant
  static const Color outlineColor = Color(0xFF717973);
  static const Color outlineVariantColor = Color(0xFFC1C8C2);

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
    final baseTheme = ThemeData.light(useMaterial3: true);
    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);

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
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimaryColor,
          height: 1.2,
          letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          height: 1.25,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
          height: 1.45,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
          height: 1.25,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: textSecondaryColor,
          height: 1.25,
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        iconTheme: const IconThemeData(color: textPrimaryColor),
        titleTextStyle: GoogleFonts.inter(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.2,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
