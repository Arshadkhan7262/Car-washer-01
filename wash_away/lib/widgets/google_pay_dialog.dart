import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class GooglePayDialog extends StatelessWidget {
  final double amount;
  final String currency;
  final Function() onPayPressed;
  final bool isLoading;

  const GooglePayDialog({
    super.key,
    required this.amount,
    required this.currency,
    required this.onPayPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? DarkTheme.card : LightTheme.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google Pay Logo/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF4285F4),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Pay with Google Pay',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Amount
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? DarkTheme.primary : LightTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              currency.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Google Pay Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPayPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              color: Color(0xFF4285F4),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Pay with Google Pay',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Cancel button
            TextButton(
              onPressed: isLoading ? null : () => Get.back(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

