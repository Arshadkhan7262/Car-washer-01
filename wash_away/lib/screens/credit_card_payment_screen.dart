import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../services/stripe_payment_service.dart';
import '../features/auth/services/auth_service.dart';
import '../api/api_client.dart';
import '../widgets/safe_card_field.dart';

class CreditCardPaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;
  final Function(Map<String, dynamic>)? onPaymentSuccess;
  final Function(String)? onPaymentError;

  const CreditCardPaymentScreen({
    super.key,
    required this.amount,
    this.currency = 'USD',
    this.onPaymentSuccess,
    this.onPaymentError,
  });

  @override
  State<CreditCardPaymentScreen> createState() => _CreditCardPaymentScreenState();
}

class _CreditCardPaymentScreenState extends State<CreditCardPaymentScreen> {
  final StripePaymentService _paymentService = StripePaymentService();
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();
  
  bool _isProcessing = false;
  CardFieldInputDetails? _cardDetails;

  Future<void> _processPayment() async {
    // Check if Stripe is initialized
    final publishableKey = Stripe.publishableKey;
    if (publishableKey.isEmpty || publishableKey == 'pk_test_your_publishable_key_here') {
      Get.snackbar(
        'Configuration Error',
        'Stripe is not configured. Please add your Stripe publishable key in util/constants.dart',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }
    
    if (_cardDetails == null || !_cardDetails!.complete) {
      Get.snackbar(
        'Validation Error',
        'Please enter valid card details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create payment intent
      final intentData = await _paymentService.createPaymentIntent(
        amount: widget.amount,
        currency: widget.currency,
      );

      final clientSecret = intentData['client_secret'];
      if (clientSecret == null) {
        throw Exception('Invalid payment intent response');
      }

      // Confirm payment using Stripe's CardField
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (paymentIntent.status == 'succeeded') {
        // Notify backend
        final token = await _authService.getAuthToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
        }

        final result = {
          'success': true,
          'payment_intent_id': paymentIntent.id,
          'transaction_id': paymentIntent.id,
          'status': 'succeeded',
        };

        if (mounted) {
          Get.snackbar(
            'Success',
            'Payment processed successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          if (widget.onPaymentSuccess != null) {
            widget.onPaymentSuccess!(result);
          }
          
          Navigator.pop(context, result);
        }
      } else {
        throw Exception('Payment failed with status: ${paymentIntent.status}');
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Payment Failed',
          e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
    
    // Check if Stripe is initialized
    final publishableKey = Stripe.publishableKey;
    final isStripeInitialized = publishableKey.isNotEmpty &&
                                publishableKey != 'pk_test_your_publishable_key_here' &&
                                publishableKey.startsWith('pk_');

    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        title: Text(
          'Credit Card Payment',
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

            Text(
              'Card Details',
              style: GoogleFonts.inter(
                color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Stripe CardField - Safe wrapper to prevent crashes
            Container(
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
              child: SafeCardField(
                onCardChanged: (card) {
                  setState(() {
                    _cardDetails = card;
                  });
                },
              ),
            ),

            const SizedBox(height: 30),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!isStripeInitialized || _isProcessing || _cardDetails == null || !_cardDetails!.complete) 
                    ? null 
                    : _processPayment,
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
                    : Text(
                        'Pay \$${widget.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Security Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: isDark ? DarkTheme.primary : LightTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is secure and encrypted by Stripe',
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
