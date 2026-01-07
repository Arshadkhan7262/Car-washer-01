import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class DarkTheme {
  // Dark Theme Colors
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF131313);
  static const Color card = Color(0xFF1E1E1E);
  static const Color cardSecondary = Color(0xFF282828);
  static const Color primary = Color(0xFF8DA2FF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB8BDCA);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color paymentCardSelected = Color(0xFF8DA2FF);
  static const Color paymentCardUnselected = card;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        background: background,
        surface: surface,
        onPrimary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0B0D13), // barColor
      selectedItemColor: Color(0xFF8DA2FF), // selectedColor
      unselectedItemColor: Color(0xFFB8BDCA), // unselectedColor
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: AppTheme.interSemiBold15(textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
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
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }
}

