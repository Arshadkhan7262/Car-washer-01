import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class GooglePayScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final Function(Map<String, dynamic>)? onPaymentSuccess;
  final Function(String)? onPaymentError;

  const GooglePayScreen({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.onPaymentSuccess,
    this.onPaymentError,
  });

  @override
  State<GooglePayScreen> createState() => _GooglePayScreenState();
}

class _GooglePayScreenState extends State<GooglePayScreen> {
  bool _isProcessing = false;

  Future<void> _processGooglePay() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate Google Pay processing
    await Future.delayed(const Duration(seconds: 2));

    try {
      // TODO: Integrate actual Google Pay SDK
      // For now, this is a placeholder
      
      final result = {
        'success': true,
        'payment_method': 'google_pay',
        'transaction_id': 'GP_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'succeeded',
      };

      if (mounted) {
        Get.snackbar(
          'Success',
          'Google Pay payment processed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        if (widget.onPaymentSuccess != null) {
          widget.onPaymentSuccess!(result);
        }
        
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Payment Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        
        if (widget.onPaymentError != null) {
          widget.onPaymentError!(e.toString());
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        title: Text(
          'Google Pay',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Google Pay Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? DarkTheme.card : LightTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Google Pay',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Fast and secure payment',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            // Amount Display
            Container(
              padding: const EdgeInsets.all(20),
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
                    '\$${widget.amount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processGooglePay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Pay with Google Pay',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will be redirected to Google Pay for authentication',
                      style: GoogleFonts.inter(
                        color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

