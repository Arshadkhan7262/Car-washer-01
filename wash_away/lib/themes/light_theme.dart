import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class LightTheme {
  // Light Theme Colors
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardSecondary = Color(0xFFF0F0F0);
  static const Color primary = Color(0xFF8DA2FF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color paymentCardSelected = Color(0xFF2E70F0);
  static const Color paymentCardUnselected = card;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primary,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: AppTheme.interSemiBold15(textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTheme.interBold24(textPrimary),
        displayMedium: AppTheme.interBold15(textPrimary),
        displaySmall: AppTheme.interBold13(textPrimary),
        headlineLarge: AppTheme.interBold24(textPrimary),
        headlineMedium: AppTheme.interBold15(textPrimary),
        headlineSmall: AppTheme.interBold13(textPrimary),
        titleLarge: AppTheme.interSemiBold24(textPrimary),
        titleMedium: AppTheme.interSemiBold15(textPrimary),
        titleSmall: AppTheme.interSemiBold13(textPrimary),
        bodyLarge: AppTheme.interRegular15(textPrimary),
        bodyMedium: AppTheme.interRegular13(textPrimary),
        bodySmall: AppTheme.interRegular11(textSecondary),
        labelLarge: AppTheme.interSemiBold15(textPrimary),
        labelMedium: AppTheme.interRegular13(textSecondary),
        labelSmall: AppTheme.interRegular11(textTertiary),

      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white, // barColor
        selectedItemColor: Color(0xFF8DA2FF), // selectedColor
        unselectedItemColor: Color(0xFFB8BDCA), // unselectedColor
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }
}

