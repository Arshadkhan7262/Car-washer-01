import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../controllers/profile_controller.dart';

class WalletPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final Function(Map<String, dynamic>)? onPaymentSuccess;
  final Function(String)? onPaymentError;

  const WalletPaymentScreen({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.onPaymentSuccess,
    this.onPaymentError,
  });

  @override
  State<WalletPaymentScreen> createState() => _WalletPaymentScreenState();
}

class _WalletPaymentScreenState extends State<WalletPaymentScreen> {
  final ProfileController _profileController = Get.put(ProfileController());
  bool _isProcessing = false;

  Future<void> _processWalletPayment() async {
    final walletBalance = _profileController.walletBalance.value;

    if (walletBalance < widget.amount) {
      Get.snackbar(
        'Insufficient Balance',
        'Your wallet balance is \$${walletBalance.toStringAsFixed(2)}. Please add funds or use another payment method.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate wallet payment processing
    await Future.delayed(const Duration(seconds: 1));

    try {
      // TODO: Integrate actual wallet payment API
      // For now, this is a placeholder
      
      final result = {
        'success': true,
        'payment_method': 'wallet',
        'transaction_id': 'WLT_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'succeeded',
        'amount': widget.amount,
      };

      if (mounted) {
        Get.snackbar(
          'Success',
          'Payment processed from wallet',
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
          'Wallet Payment',
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
            // Wallet Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E3A5F),
                          const Color(0xFF2D4A6F),
                        ]
                      : [
                          const Color(0xFF2E70F0),
                          const Color(0xFF1E5FCF),
                        ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.blue : Colors.blue).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wallet Balance',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    '\$${_profileController.walletBalance.value.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
                ],
              ),
            ),

            // Payment Details
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? DarkTheme.card : LightTheme.card,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount to Pay',
                        style: GoogleFonts.inter(
                          color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '\$${widget.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Obx(() {
                    final balance = _profileController.walletBalance.value;
                    final remaining = balance - widget.amount;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining Balance',
                          style: GoogleFonts.inter(
                            color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${remaining.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            color: remaining >= 0 ? Colors.green : Colors.red,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // Insufficient Balance Warning
            Obx(() {
              if (_profileController.walletBalance.value < widget.amount) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Insufficient wallet balance. Please add funds or use another payment method.',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final canPay = _profileController.walletBalance.value >= widget.amount;
                return ElevatedButton(
                  onPressed: (_isProcessing || !canPay) ? null : _processWalletPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? DarkTheme.primary : LightTheme.primary,
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
                            Icon(Icons.wallet, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Pay from Wallet',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Add Funds Button
            TextButton(
              onPressed: () {
                // TODO: Navigate to add funds screen
                Get.snackbar(
                  'Add Funds',
                  'Add funds feature coming soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Text(
                'Add Funds to Wallet',
                style: GoogleFonts.inter(
                  color: isDark ? DarkTheme.primary : LightTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

