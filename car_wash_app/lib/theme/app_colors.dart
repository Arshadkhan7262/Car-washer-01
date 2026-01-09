import 'package:flutter/widgets.dart';

class AppColors {
  // Primary Colors (The Green color from the "Accept Job" button)
  static const String primaryLight = '#008800';

  // Secondary Colors (The Blue/Navy used for headers and 'New' badges)
  static const String secondaryLight = '#001F3F'; // Deep Navy from HOME.png
  static const String accentBlue = '#007AFF'; // Blue for 'New' label

  // Background Colors
  static const String scaffoldBgLight = '#F8F9FB'; // Very light grey background

  // Card/Surface Colors
  static const String cardLight = '#FFFFFF'; // Pure white cards

  // Text Colors
  static const String textPrimaryLight = '#0A0E16'; // Near black for titles
  static const String textSecondaryLight = '#757575'; // Grey for subtitles

  static const Color white = Color(0xFFF7FFFE);
  static const Color black = Color(0xFF000000);
  static const Color green = Color(0xFF088B0F);
  static const Color red = Color(0xFFB30000);

  // Helper methods
  static int hexToInt(String hex) =>
      int.parse(hex.replaceAll('#', ''), radix: 16);

  // Method to get light mode colors explicitly
  static int getPrimaryColor(bool isDark) =>
      hexToInt(isDark ? '#00A500' : primaryLight);
  static int getSecondaryColor(bool isDark) =>
      hexToInt(isDark ? '#4D94FF' : secondaryLight);
  static int getScaffoldBgColor(bool isDark) =>
      hexToInt(isDark ? '#121212' : scaffoldBgLight);
  static int getCardColor(bool isDark) =>
      hexToInt(isDark ? '#1E1E1E' : cardLight);
  static int getTextPrimaryColor(bool isDark) =>
      hexToInt(isDark ? '#FFFFFF' : textPrimaryLight);
  static int getTextSecondaryColor(bool isDark) =>
      hexToInt(isDark ? '#B0B0B0' : textSecondaryLight);
}
