import 'package:flutter/material.dart';

// The 'Main Button' used in Reset, Login, and Signup
Widget mainButton(String text, VoidCallback onPressed, {bool isLoading = false}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF031E3D), // Dark Navy from your design
        disabledBackgroundColor: const Color(0xFF031E3D).withOpacity(0.6),
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
  return OutlinedButton(
    onPressed: () {
      // TODO: Implement Google Sign In
    },
    style: OutlinedButton.styleFrom(
      fixedSize: const Size(double.infinity, 55),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          'https://www.google.com/favicon.ico',
          height: 20,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.g_mobiledata, size: 20);
          },
        ),
        const SizedBox(width: 12),
        const Text(
          "Continue with Google",
          style: TextStyle(color: Color(0xFF0A0E16), fontSize: 16),
        ),
      ],
    ),
  );
}
