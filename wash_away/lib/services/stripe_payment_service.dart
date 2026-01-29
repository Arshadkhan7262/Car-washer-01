import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../api/api_client.dart';
import '../features/auth/services/auth_service.dart';
import '../util/constants.dart';

/// Stripe Payment Service
/// Handles Stripe payment processing via backend API
class StripePaymentService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  /// Initialize Stripe with publishable key
  Future<void> initializeStripe(String publishableKey) async {
    try {
      Stripe.publishableKey = publishableKey;
      await Stripe.instance.applySettings();
      log('✅ Stripe initialized successfully');
    } catch (e) {
      log('❌ Error initializing Stripe: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Create payment intent on backend
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      log('🔄 [createPaymentIntent] Starting - Amount: $amount, Currency: $currency');
      
      // Set auth token
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      } else {
        throw Exception('Authentication required. Please login again.');
      }

      // Convert amount to cents
      final amountInCents = (amount * 100).toInt();
      log('🔄 [createPaymentIntent] Amount in cents: $amountInCents');

      final response = await _apiClient.post(
        '/customer/payment/create-intent',
        body: {
          'amount': amountInCents,
          'currency': currency.toLowerCase(),
          if (customerId != null) 'customer_id': customerId,
        },
      );

      log('🔄 [createPaymentIntent] Response received: ${response.success}');

      if (!response.success) {
        String errorMessage = response.error ?? 'Failed to create payment intent';
        log('❌ [createPaymentIntent] Error: $errorMessage');
        throw Exception(errorMessage);
      }

      final data = response.data['data'];
      log('✅ [createPaymentIntent] Payment intent created: ${data['payment_intent_id']}');
      
      return data;
    } catch (e) {
      log('❌ [createPaymentIntent] Exception: $e');
      throw Exception('Failed to create payment intent: ${e.toString()}');
    }
  }

  /// Create payment method from card details
  /// Note: In Stripe, card details are typically collected using CardField widget
  /// For manual entry, we'll use the confirmPayment method directly with card params
  Future<PaymentMethod> createPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required String cardholderName,
    String? zipCode,
  }) async {
    try {
      // Create payment method with card details
      // Note: Stripe SDK may require using CardField for security
      // This is a workaround for manual card entry
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: cardholderName,
              address: Address(
                line1: '', // Required but can be empty
                line2: '',
                city: '', // Required but can be empty
                state: '', // Required but can be empty
                postalCode: zipCode ?? '', // Use zipCode if provided
                country: '', // Required but can be empty
              ),
            ),
          ),
        ),
      );

      return paymentMethod;
    } catch (e) {
      log('❌ [createPaymentMethod] Error: $e');
      // If creating payment method fails, we'll use direct confirmation
      rethrow;
    }
  }

  /// Confirm payment with payment method
  Future<PaymentIntent> confirmPayment({
    required String paymentIntentClientSecret,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Confirm payment with Stripe using payment method ID
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: paymentMethod.billingDetails,
          ),
        ),
      );

      return paymentIntent;
    } catch (e) {
      log('❌ [confirmPayment] Error: $e');
      throw Exception('Payment confirmation failed: ${e.toString()}');
    }
  }

  /// Process payment with CardField details
  Future<Map<String, dynamic>> processCardPayment({
    required double amount,
    required String currency,
    required String paymentIntentClientSecret,
  }) async {
    try {
      // Confirm payment using CardField (card details are already collected)
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      // Check payment status
      if (paymentIntent.status == 'succeeded') {
        // Notify backend of successful payment
        final token = await _authService.getAuthToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
        }

        final response = await _apiClient.post(
          '/customer/payment/confirm',
          body: {
            'payment_intent_id': paymentIntent.id,
            'transaction_id': paymentIntent.id,
          },
        );

        if (!response.success) {
          log('⚠️ Payment succeeded but backend confirmation failed');
        }

        return {
          'success': true,
          'payment_intent_id': paymentIntent.id,
          'transaction_id': paymentIntent.id,
          'status': 'succeeded',
        };
      } else {
        throw Exception('Payment failed with status: ${paymentIntent.status}');
      }
    } catch (e) {
      log('❌ [processCardPayment] Error: $e');
      rethrow;
    }
  }

  /// Present Payment Sheet for Credit Card, Google Pay / Apple Pay
  Future<Map<String, dynamic>> presentPaymentSheet({
    required double amount,
    required String currency,
    String? preferredPaymentMethod, // Preferred payment method: 'Credit Card', 'Google Pay', or 'Apple Pay'
  }) async {
    // Check if running on web - Stripe Payment Sheet doesn't work on web
    if (kIsWeb) {
      throw Exception('Payment via Stripe Payment Sheet is not supported on web. Please use the mobile app for card payments.');
    }
    
    try {
      log('🔄 [presentPaymentSheet] Starting payment sheet flow');
      log('🔄 [presentPaymentSheet] Amount: $amount, Currency: $currency, Preferred Method: $preferredPaymentMethod');
      
      // Ensure Stripe is properly initialized
      final publishableKey = Stripe.publishableKey;
      if (publishableKey.isEmpty) {
        log('❌ [presentPaymentSheet] Stripe not initialized');
        throw Exception('Stripe is not initialized. Please restart the app.');
      }
      
      // Create payment intent first
      log('🔄 [presentPaymentSheet] Creating payment intent...');
      final intentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      final clientSecret = intentData['client_secret'];
      if (clientSecret == null || clientSecret.isEmpty) {
        log('❌ [presentPaymentSheet] No client secret in response');
        log('❌ [presentPaymentSheet] Response data: $intentData');
        throw Exception('Invalid payment intent response: Missing client_secret');
      }

      log('✅ [presentPaymentSheet] Payment intent created, initializing sheet...');

      // Configure Apple Pay if preferred method is Apple Pay
      PaymentSheetApplePay? applePayConfig;
      if (preferredPaymentMethod == 'Apple Pay') {
        // Check if merchant identifier is configured
        final merchantId = AppConstants.applePayMerchantIdentifier;
        if (merchantId.isEmpty || Stripe.merchantIdentifier == null || Stripe.merchantIdentifier!.isEmpty) {
          log('❌ [presentPaymentSheet] Apple Pay merchant identifier not configured');
          throw Exception(
            'Apple Pay is not configured. Please add your merchant identifier in util/constants.dart. '
            'Get it from: https://support.stripe.com/questions/enable-apple-pay-on-your-stripe-account'
          );
        }
        
        applePayConfig = const PaymentSheetApplePay(
          merchantCountryCode: 'US',
        );
        log('🍎 [presentPaymentSheet] Apple Pay configured as preferred method with merchant: ${Stripe.merchantIdentifier}');
      }

      // Configure Google Pay if preferred method is Google Pay
      PaymentSheetGooglePay? googlePayConfig;
      if (preferredPaymentMethod == 'Google Pay') {
        googlePayConfig = const PaymentSheetGooglePay(
          merchantCountryCode: 'US',
          testEnv: true, // Set to false for production
        );
        log('📱 [presentPaymentSheet] Google Pay configured as preferred method');
      }

      // Initialize payment sheet with proper configuration
      // Note: We need to initialize the payment sheet every time before presenting
      // This ensures a fresh state for each payment attempt
      try {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Wash Away',
            // Enable card entry in Payment Sheet (always allow as fallback)
            allowsDelayedPaymentMethods: true,
            // Optional: Customize appearance
            style: ThemeMode.system,
            // Configure preferred payment methods
            applePay: applePayConfig,
            googlePay: googlePayConfig,
          ),
        );
        log('✅ [presentPaymentSheet] Payment sheet initialized successfully');
      } catch (initError) {
        log('❌ [presentPaymentSheet] Failed to initialize payment sheet: $initError');
        // If initialization fails, try to reinitialize after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Wash Away',
            allowsDelayedPaymentMethods: true,
            style: ThemeMode.system,
            applePay: applePayConfig,
            googlePay: googlePayConfig,
          ),
        );
        log('✅ [presentPaymentSheet] Payment sheet reinitialized successfully');
      }

      log('✅ [presentPaymentSheet] Payment sheet initialized, presenting...');

      // Present payment sheet (this will show bottom sheet with card entry)
      // Add a small delay to ensure initialization is complete
      await Future.delayed(const Duration(milliseconds: 300));
      await Stripe.instance.presentPaymentSheet();

      log('✅ [presentPaymentSheet] Payment sheet completed, checking status...');

      // Get payment intent to check status
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(clientSecret);

      log('🔄 [presentPaymentSheet] Payment intent status: ${paymentIntent.status}');

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        // Notify backend
        final token = await _authService.getAuthToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
        }

        log('🔄 [presentPaymentSheet] Notifying backend of successful payment...');

        final response = await _apiClient.post(
          '/customer/payment/confirm',
          body: {
            'payment_intent_id': paymentIntent.id,
            'transaction_id': paymentIntent.id,
          },
        );

        if (!response.success) {
          log('⚠️ Payment succeeded but backend confirmation failed');
        } else {
          log('✅ [presentPaymentSheet] Backend confirmed payment');
        }

        return {
          'success': true,
          'payment_intent_id': paymentIntent.id,
          'transaction_id': paymentIntent.id,
          'status': 'succeeded',
        };
      } else {
        throw Exception('Payment failed with status: ${paymentIntent.status}');
      }
    } catch (e) {
      log('❌ [presentPaymentSheet] Error: $e');
      log('❌ [presentPaymentSheet] Error type: ${e.runtimeType}');
      
      // Check if user cancelled - StripeException with Canceled failure code
      if (e is StripeException) {
        final stripeError = e.error;
        if (stripeError.code == FailureCode.Canceled) {
          log('ℹ️ [presentPaymentSheet] User cancelled the payment');
          throw Exception('Payment was cancelled by user');
        }
      }
      
      // Check if user cancelled - string matching for other error types
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('canceled') || 
          errorString.contains('cancelled') ||
          (errorString.contains('user') && errorString.contains('cancel')) ||
          errorString.contains('payment flow has been canceled')) {
        log('ℹ️ [presentPaymentSheet] User cancelled the payment');
        throw Exception('Payment was cancelled by user');
      }
      
      // Re-throw with more context for actual errors
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  /// Process payment with card details (legacy method for manual entry)
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
    String? zipCode,
  }) async {
    try {
      // Create payment intent
      final intentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );

      final paymentIntentId = intentData['payment_intent_id'];
      final clientSecret = intentData['client_secret'];

      if (paymentIntentId == null || clientSecret == null) {
        throw Exception('Invalid payment intent response');
      }

      // Parse expiry date
      final expiryParts = expiryDate.split('/');
      if (expiryParts.length != 2) {
        throw Exception('Invalid expiry date format');
      }

      final expiryMonth = int.tryParse(expiryParts[0]);
      final expiryYear = int.tryParse(expiryParts[1]);

      if (expiryMonth == null || expiryYear == null) {
        throw Exception('Invalid expiry date');
      }

      // Confirm payment directly with card details
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: cardholderName,
              address: Address(
                line1: '',
                line2: '',
                city: '',
                state: '',
                postalCode: zipCode ?? '',
                country: '',
              ),
            ),
          ),
        ),
      );

      // Check payment status
      if (paymentIntent.status == 'succeeded') {
        // Notify backend of successful payment
        final token = await _authService.getAuthToken();
        if (token != null) {
          _apiClient.setAuthToken(token);
        }

        final response = await _apiClient.post(
          '/customer/payment/confirm',
          body: {
            'payment_intent_id': paymentIntentId,
            'transaction_id': paymentIntent.id,
          },
        );

        if (!response.success) {
          log('⚠️ Payment succeeded but backend confirmation failed');
        }

        return {
          'success': true,
          'payment_intent_id': paymentIntent.id,
          'transaction_id': paymentIntent.id,
          'status': 'succeeded',
        };
      } else {
        throw Exception('Payment failed with status: ${paymentIntent.status}');
      }
    } catch (e) {
      log('❌ [processPayment] Error: $e');
      rethrow;
    }
  }

  /// Process Google Pay payment (mock implementation with dummy data)
  Future<Map<String, dynamic>> processGooglePay({
    required double amount,
    required String currency,
  }) async {
    try {
      log('🔄 [processGooglePay] Starting Google Pay flow (mock)');
      log('🔄 [processGooglePay] Amount: $amount, Currency: $currency');
      
      // Simulate Google Pay processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock payment success
      final mockPaymentId = 'gp_${DateTime.now().millisecondsSinceEpoch}';
      
      log('✅ [processGooglePay] Mock payment successful: $mockPaymentId');
      
      // Create payment intent on backend (for consistency)
      final intentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );
      
      // Notify backend of successful payment
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      }
      
      final response = await _apiClient.post(
        '/customer/payment/confirm',
        body: {
          'payment_intent_id': intentData['payment_intent_id'],
          'transaction_id': mockPaymentId,
        },
      );
      
      if (!response.success) {
        log('⚠️ Google Pay succeeded but backend confirmation failed');
      } else {
        log('✅ [processGooglePay] Backend confirmed payment');
      }
      
      return {
        'success': true,
        'payment_intent_id': intentData['payment_intent_id'],
        'transaction_id': mockPaymentId,
        'status': 'succeeded',
        'method': 'google_pay',
      };
    } catch (e) {
      log('❌ [processGooglePay] Error: $e');
      throw Exception('Google Pay failed: ${e.toString()}');
    }
  }

  /// Process Apple Pay payment (mock implementation with dummy data)
  Future<Map<String, dynamic>> processApplePay({
    required double amount,
    required String currency,
  }) async {
    try {
      log('🔄 [processApplePay] Starting Apple Pay flow (mock)');
      log('🔄 [processApplePay] Amount: $amount, Currency: $currency');
      
      // Simulate Apple Pay processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock payment success
      final mockPaymentId = 'ap_${DateTime.now().millisecondsSinceEpoch}';
      
      log('✅ [processApplePay] Mock payment successful: $mockPaymentId');
      
      // Create payment intent on backend (for consistency)
      final intentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );
      
      // Notify backend of successful payment
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      }
      
      final response = await _apiClient.post(
        '/customer/payment/confirm',
        body: {
          'payment_intent_id': intentData['payment_intent_id'],
          'transaction_id': mockPaymentId,
        },
      );
      
      if (!response.success) {
        log('⚠️ Apple Pay succeeded but backend confirmation failed');
      } else {
        log('✅ [processApplePay] Backend confirmed payment');
      }
      
      return {
        'success': true,
        'payment_intent_id': intentData['payment_intent_id'],
        'transaction_id': mockPaymentId,
        'status': 'succeeded',
        'method': 'apple_pay',
      };
    } catch (e) {
      log('❌ [processApplePay] Error: $e');
      throw Exception('Apple Pay failed: ${e.toString()}');
    }
  }
}
