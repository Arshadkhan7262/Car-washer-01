import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Color(AppColors.getPrimaryColor(false)),
      scaffoldBackgroundColor: Color(AppColors.getScaffoldBgColor(false)),
      cardColor: Color(AppColors.getCardColor(false)),
      dividerColor: const Color(0xFFEEEEEE),

      // colorScheme: ColorScheme.light(
      //   primary: Color(AppColors.getPrimaryColor(false)),
      //   secondary: const Color(0xFF007AFF), // Blue for 'New' tag
      //   surface: Color(AppColors.getCardColor(false)),
      //   background: Color(AppColors.getScaffoldBgColor(false)),
      //   onPrimary: Colors.white,
      //   onSurface: Color(AppColors.getTextPrimaryColor(false)),
      // ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.black, // Black for selected labels
        unselectedItemColor: AppColors.black.withOpacity(0.48),
        showSelectedLabels: true,
        selectedLabelStyle: TextStyle(color: AppColors.black),
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),

      // AppBar Theme for My Jobs screen
      // appBarTheme: AppBarTheme(
      //   backgroundColor: AppColors.white,
      //   foregroundColor: Color(AppColors.getTextPrimaryColor(false)),
      //   elevation: 0,
      //   centerTitle: false,
      //   titleTextStyle: GoogleFonts.inter(
      //     color: Color(AppColors.getTextPrimaryColor(false)),
      //     fontSize: 20,
      //     fontWeight: FontWeight.bold,
      //   ),
      // ),

      // Elevated Button (Accept Job)
      // elevatedButtonTheme: ElevatedButtonThemeData(
      //   style: ElevatedButton.styleFrom(
      //     backgroundColor: Color(AppColors.getPrimaryColor(false)),
      //     foregroundColor: Colors.white,
      //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //   ),
      // ),

      // Outlined Button (Decline)
      // outlinedButtonTheme: OutlinedButtonThemeData(
      //   style: OutlinedButton.styleFrom(
      //     foregroundColor: Colors.grey[700],
      //     side: BorderSide(color: Colors.grey[300]!),
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      //   ),
      // ),
    );
  }

  /// Dark Theme Configuration
}
