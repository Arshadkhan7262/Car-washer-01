import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import 'credit_card_payment_screen.dart';
import 'google_pay_screen.dart';
import 'wallet_payment_screen.dart';

class PaymentSelectionScreen extends StatelessWidget {
  final double amount;
  final String currency;
  final Function(Map<String, dynamic>)? onPaymentSuccess;
  final Function(String)? onPaymentError;

  const PaymentSelectionScreen({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.onPaymentSuccess,
    this.onPaymentError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: GoogleFonts.inter(
            color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Display
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: isDark ? DarkTheme.card : LightTheme.card,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(
                      color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'Choose Payment Method',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Credit Card
            _buildPaymentOption(
              context: context,
              title: 'Credit Card',
              subtitle: 'Pay with debit or credit card',
              icon: Icons.credit_card,
              iconColor: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreditCardPaymentScreen(
                      amount: amount,
                      currency: currency,
                      onPaymentSuccess: onPaymentSuccess,
                      onPaymentError: onPaymentError,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Google Pay
            _buildPaymentOption(
              context: context,
              title: 'Google Pay',
              subtitle: 'Fast and secure payment',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GooglePayScreen(
                      amount: amount,
                      currency: currency,
                      onPaymentSuccess: onPaymentSuccess,
                      onPaymentError: onPaymentError,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Wallet
            _buildPaymentOption(
              context: context,
              title: 'Wallet',
              subtitle: 'Pay from your wallet balance',
              icon: Icons.wallet,
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WalletPaymentScreen(
                      amount: amount,
                      currency: currency,
                      onPaymentSuccess: onPaymentSuccess,
                      onPaymentError: onPaymentError,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Cash (for reference, but typically handled differently)
            _buildPaymentOption(
              context: context,
              title: 'Cash',
              subtitle: 'Pay on service completion',
              icon: Icons.money,
              iconColor: Colors.green,
              onTap: () {
                // Cash payment - typically handled in booking confirmation
                if (onPaymentSuccess != null) {
                  onPaymentSuccess!({
                    'success': true,
                    'payment_method': 'cash',
                    'status': 'pending',
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? DarkTheme.card : LightTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? DarkTheme.textTertiary : LightTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

