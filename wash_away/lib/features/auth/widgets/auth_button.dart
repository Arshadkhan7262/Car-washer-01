import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wash_away/themes/dark_theme.dart';
import 'package:wash_away/themes/light_theme.dart';
import '../controllers/auth_controller.dart';

// The 'Main Button' used in Reset, Login, and Signup
Widget mainButton(String text, VoidCallback onPressed, {bool isLoading = false}) {
  final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
  
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D),
        disabledBackgroundColor: (isDarkTheme ? DarkTheme.primary : const Color(0xFF031E3D)).withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}

// The 'Google Button' from your auth.png
Widget googleButton() {
  final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
  final authController = Get.find<AuthController>();
  
  return Obx(() => OutlinedButton(
    onPressed: authController.isLoggingIn.value ? null : () async {
      await authController.loginWithGoogle();
    },
    style: OutlinedButton.styleFrom(
      fixedSize: const Size(double.infinity, 55),
      side: BorderSide(
        color: isDarkTheme 
            ? Colors.white.withValues(alpha: 0.25) 
            : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: isDarkTheme ? DarkTheme.card : Colors.transparent,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://www.google.com/favicon.ico',
          height: 20,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.g_mobiledata, 
              size: 20,
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          "Continue with Google",
          style: TextStyle(
            color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    ),
  ));
}

