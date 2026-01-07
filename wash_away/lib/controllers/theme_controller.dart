import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class ThemeController extends GetxController {
  final RxBool isDarkMode = true.obs; // Default to dark mode

  ThemeData get currentTheme => isDarkMode.value 
      ? DarkTheme.themeData 
      : LightTheme.themeData;

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(currentTheme);
  }

  void setDarkMode(bool value) {
    isDarkMode.value = value;
    Get.changeTheme(currentTheme);
  }
}

