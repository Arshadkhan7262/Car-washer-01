import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import '../api/api_client.dart';
import '../api/api_checker.dart';
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

  /// Create payment intent on backend with retry logic for connection errors
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
    int maxRetries = 3,
  }) async {
    // Validate Stripe configuration before attempting
    final stripeKey = Stripe.publishableKey;
    if (stripeKey.isEmpty) {
      throw Exception(
        'Stripe is not configured. Please check your .env file and ensure STRIPE_PUBLISHABLE_KEY is set correctly. '
        'The key must match your backend STRIPE_SECRET_KEY account. See ENV_SETUP.md for details.'
      );
    }
    
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        log('🔄 [createPaymentIntent] Attempt $attempt/$maxRetries - Amount: $amount, Currency: $currency');
        
        // Check internet connectivity before attempting (only on first attempt)
        if (attempt == 1) {
          final hasConnection = await ApiChecker.hasConnection();
          if (!hasConnection) {
            throw Exception('No internet connection. Please check your network and try again.');
          }
        }
        
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
          
          // Check if error is retryable (connection errors)
          final errorString = errorMessage.toLowerCase();
          final isRetryable = errorString.contains('connection') ||
              errorString.contains('reset') ||
              errorString.contains('timeout') ||
              errorString.contains('network') ||
              errorString.contains('peer') ||
              errorString.contains('socket');
          
          if (isRetryable && attempt < maxRetries) {
            final delay = Duration(milliseconds: 1000 * attempt); // Exponential backoff
            log('🔄 [createPaymentIntent] Retryable error detected, retrying in ${delay.inMilliseconds}ms...');
            await Future.delayed(delay);
            continue; // Retry
          }
          
          throw Exception(errorMessage);
        }

        final data = response.data['data'];
        log('✅ [createPaymentIntent] Payment intent created: ${data['payment_intent_id']}');
        
        return data;
      } catch (e) {
        final errorString = e.toString().toLowerCase();
        final isRetryable = errorString.contains('connection') ||
            errorString.contains('reset') ||
            errorString.contains('timeout') ||
            errorString.contains('network') ||
            errorString.contains('peer') ||
            errorString.contains('socket') ||
            errorString.contains('clientexception');
        
        log('❌ [createPaymentIntent] Exception on attempt $attempt: $e');
        
        // If it's a retryable error and we have retries left, retry
        if (isRetryable && attempt < maxRetries) {
          final delay = Duration(milliseconds: 1000 * attempt); // Exponential backoff
          log('🔄 [createPaymentIntent] Retryable connection error, retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
          continue; // Retry
        }
        
        // If it's not retryable or we've exhausted retries, throw
        if (isRetryable && attempt >= maxRetries) {
          throw Exception('Unable to connect to payment server. Please check your internet connection and try again. If the problem persists, the server may be temporarily unavailable.');
        }
        
        // For non-retryable errors, provide a cleaner error message
        String userFriendlyError = e.toString();
        if (userFriendlyError.contains('Exception: ')) {
          userFriendlyError = userFriendlyError.replaceAll('Exception: ', '');
        }
        if (userFriendlyError.contains('Failed to create payment intent: ')) {
          userFriendlyError = userFriendlyError.replaceAll('Failed to create payment intent: ', '');
        }
        
        throw Exception(userFriendlyError);
      }
    }
    
    // This should never be reached, but just in case
    throw Exception('Failed to create payment intent after $maxRetries attempts');
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
    
    // Declare payment configs outside try block for use in catch block
    PaymentSheetApplePay? applePayConfig;
    PaymentSheetGooglePay? googlePayConfig;
    
    // Track if we've already created a payment intent to avoid creating multiple
    bool paymentIntentCreated = false;
    String? originalPaymentIntentId;
    // Backend Stripe account id (from create-intent response) to debug key mismatch
    String? backendStripeAccount;
    
    try {
      log('🔄 [presentPaymentSheet] Starting payment sheet flow');
      log('🔄 [presentPaymentSheet] Amount: $amount, Currency: $currency, Preferred Method: $preferredPaymentMethod');
      
      // Ensure Stripe is properly initialized
      final publishableKey = Stripe.publishableKey;
      if (publishableKey.isEmpty) {
        log('❌ [presentPaymentSheet] Stripe not initialized');
        throw Exception('Stripe is not initialized. Please restart the app.');
      }
      
      // Configure payment methods first (before creating payment intent to minimize delay)
      // Always configure Apple Pay if merchant identifier is available
      final merchantId = AppConstants.applePayMerchantIdentifier;
      if (merchantId.isNotEmpty && Stripe.merchantIdentifier != null && Stripe.merchantIdentifier!.isNotEmpty) {
        applePayConfig = const PaymentSheetApplePay(
          merchantCountryCode: 'US',
        );
        log('🍎 [presentPaymentSheet] Apple Pay configured with merchant: ${Stripe.merchantIdentifier}');
      } else {
        // Use dummy config for Apple Pay to ensure it's available (will be handled by Stripe)
        applePayConfig = const PaymentSheetApplePay(
          merchantCountryCode: 'US',
        );
        log('🍎 [presentPaymentSheet] Apple Pay configured with default settings (merchant identifier may need setup)');
      }

      // Always configure Google Pay with default settings
      // Use the currency from the payment request
      final currencyCode = currency.toUpperCase();
      googlePayConfig = PaymentSheetGooglePay(
        merchantCountryCode: 'US',
        testEnv: true, // Set to false for production
        currencyCode: currencyCode, // Use the payment currency
      );
      log('📱 [presentPaymentSheet] Google Pay configured with currency: $currencyCode');
      
      // Create payment intent right before initialization to minimize expiration risk
      // Only create if we haven't already created one (to avoid multiple intents)
      String clientSecret;
      String paymentIntentId;
      
      if (!paymentIntentCreated) {
        log('🔄 [presentPaymentSheet] Creating payment intent...');
        final intentData = await createPaymentIntent(
          amount: amount,
          currency: currency,
        );

        final secret = intentData['client_secret'];
        final intentId = intentData['payment_intent_id'];
        
        if (secret == null || secret.isEmpty) {
          log('❌ [presentPaymentSheet] No client secret in response');
          log('❌ [presentPaymentSheet] Response data: $intentData');
          throw Exception('Invalid payment intent response: Missing client_secret');
        }
        
        if (intentId == null || intentId.isEmpty) {
          log('❌ [presentPaymentSheet] No payment intent ID in response');
          log('❌ [presentPaymentSheet] Response data: $intentData');
          throw Exception('Invalid payment intent response: Missing payment_intent_id');
        }
        
        // Validate client secret format
        if (!secret.contains('_secret_')) {
          log('❌ [presentPaymentSheet] Invalid client secret format: $secret');
          throw Exception('Invalid payment intent client secret format');
        }
        
        clientSecret = secret;
        paymentIntentId = intentId;
        originalPaymentIntentId = intentId;
        paymentIntentCreated = true;
        final backendAccount = intentData['_stripe_account'];
        if (backendAccount != null && backendAccount is String) {
          backendStripeAccount = backendAccount;
          log('✅ [presentPaymentSheet] Backend Stripe account: $backendStripeAccount (must match app pk_test_$backendStripeAccount...)');
        }
        
        log('✅ [presentPaymentSheet] Payment intent created: $paymentIntentId');
        log('✅ [presentPaymentSheet] Client secret validated');
        // Stripe intents are available immediately; no delay needed
      }
      
      log('✅ [presentPaymentSheet] Initializing sheet...');

      // Initialize payment sheet with proper configuration
      // Note: We need to initialize the payment sheet every time before presenting
      // This ensures a fresh state for each payment attempt
      String finalClientSecret = clientSecret;
      String finalPaymentIntentId = paymentIntentId;
      int initAttempts = 0;
      const maxInitAttempts = 2;
      
      while (initAttempts < maxInitAttempts) {
        try {
          initAttempts++;
          log('🔄 [presentPaymentSheet] Initializing payment sheet (attempt $initAttempts/$maxInitAttempts)...');
          
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: finalClientSecret,
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
          break; // Success, exit retry loop
        } catch (initError) {
          log('❌ [presentPaymentSheet] Failed to initialize payment sheet (attempt $initAttempts): $initError');
          
          // Check if it's a payment intent error
          final errorString = initError.toString().toLowerCase();
          final isPaymentIntentError = errorString.contains('no such payment_intent') || 
                                       errorString.contains('resource_missing') ||
                                       errorString.contains('payment_intent');
          
          if (isPaymentIntentError && initAttempts < maxInitAttempts) {
            // Payment intent is invalid, create a new one
            log('⚠️ [presentPaymentSheet] Payment intent invalid, creating new one...');
            try {
              final newIntentData = await createPaymentIntent(
                amount: amount,
                currency: currency,
              );
              
              final newClientSecret = newIntentData['client_secret'];
              final newPaymentIntentId = newIntentData['payment_intent_id'];
              
              if (newClientSecret != null && newPaymentIntentId != null) {
                log('✅ [presentPaymentSheet] New payment intent created: $newPaymentIntentId');
                finalClientSecret = newClientSecret;
                finalPaymentIntentId = newPaymentIntentId;
                // Wait a bit before retrying
                await Future.delayed(const Duration(milliseconds: 500));
                continue; // Retry initialization with new intent
              } else {
                throw Exception('Failed to create new payment intent');
              }
            } catch (createError) {
              log('❌ [presentPaymentSheet] Failed to create new payment intent: $createError');
              throw Exception('Payment session expired. Please try again.');
            }
          } else {
            // Not a payment intent error or max attempts reached
            if (initAttempts < maxInitAttempts) {
              // Wait before retrying
              await Future.delayed(const Duration(milliseconds: 500));
              continue;
            } else {
              // Max attempts reached, throw error
              throw Exception('Failed to initialize payment. Please try again.');
            }
          }
        }
      }

      log('✅ [presentPaymentSheet] Payment sheet initialized, presenting...');

      // Present payment sheet immediately after initialization
      // Reduced delay to minimize chance of payment intent expiring
      await Future.delayed(const Duration(milliseconds: 100));
      
      // presentPaymentSheet() will throw an exception if user cancels or payment fails
      // If it completes successfully, the payment was processed
      int presentAttempts = 0;
      const maxPresentAttempts = 2;
      
      while (presentAttempts < maxPresentAttempts) {
        try {
          presentAttempts++;
          log('🔄 [presentPaymentSheet] Presenting payment sheet (attempt $presentAttempts/$maxPresentAttempts)...');
          await Stripe.instance.presentPaymentSheet();
          log('✅ [presentPaymentSheet] Payment sheet presented successfully');
          break; // Success, exit retry loop
        } catch (presentError) {
          log('❌ [presentPaymentSheet] Error during presentation (attempt $presentAttempts): $presentError');
          
          // Check if it's a payment intent error during presentation
          final errorString = presentError.toString().toLowerCase();
          final isPaymentIntentError = errorString.contains('no such payment_intent') || 
                                       errorString.contains('resource_missing') ||
                                       (presentError is StripeException && 
                                        presentError.error.stripeErrorCode == 'resource_missing');
          
          // Check if user cancelled
          final isUserCancelled = (presentError is StripeException && 
                                   presentError.error.code == FailureCode.Canceled) ||
                                  errorString.contains('canceled') ||
                                  errorString.contains('cancelled');
          
          if (isUserCancelled) {
            log('ℹ️ [presentPaymentSheet] User cancelled the payment');
            throw Exception('Payment was cancelled by user');
          }
          
          if (isPaymentIntentError) {
            // "No such payment_intent" = backend created intent with one Stripe account,
            // but app is using a publishable key from a different account.
            final pkWithoutPrefix = publishableKey
                .replaceFirst('pk_test_', '')
                .replaceFirst('pk_live_', '');
            final appAccount = pkWithoutPrefix.length >= 12
                ? pkWithoutPrefix.substring(0, 12)
                : (pkWithoutPrefix.isNotEmpty ? pkWithoutPrefix : '?');
            final backendAccount = backendStripeAccount ?? 'unknown (restart backend and try again)';
            log('⚠️ [presentPaymentSheet] Payment intent not found: $originalPaymentIntentId');
            log('⚠️ [presentPaymentSheet] Backend Stripe account: $backendAccount | App account: $appAccount (must match!)');
            throw Exception(
              'Payment session expired. The payment intent is no longer valid.\n\n'
              'Stripe key mismatch:\n'
              '• Backend account: $backendAccount\n'
              '• App account: $appAccount\n'
              'They MUST match (same Stripe account).\n\n'
              'Fix: Put the SAME keys in backend/.env and wash_away/.env, then restart backend and rebuild app.'
            );
          } else {
            // Not a payment intent error or max attempts reached
            if (presentAttempts >= maxPresentAttempts) {
              // Max attempts reached, throw error
              throw Exception('Payment failed. Please try again.');
            }
            // Wait before retrying
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
        }
      }

      log('✅ [presentPaymentSheet] Payment sheet completed successfully');

      // If we reach here, payment was successful (presentPaymentSheet didn't throw)
      // Use the final payment intent ID (may have been updated during retry)
      // Notify backend with the payment intent ID
      final token = await _authService.getAuthToken();
      if (token != null) {
        _apiClient.setAuthToken(token);
      }

      log('🔄 [presentPaymentSheet] Notifying backend of successful payment...');

      final response = await _apiClient.post(
        '/customer/payment/confirm',
        body: {
          'payment_intent_id': finalPaymentIntentId,
          'transaction_id': finalPaymentIntentId,
        },
      );

      if (!response.success) {
        log('⚠️ Payment succeeded but backend confirmation failed');
        // Don't throw error here - payment was successful on Stripe side
        // Backend can verify the payment intent status independently
      } else {
        log('✅ [presentPaymentSheet] Backend confirmed payment');
      }

      return {
        'success': true,
        'payment_intent_id': finalPaymentIntentId,
        'transaction_id': finalPaymentIntentId,
        'status': 'succeeded',
      };
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
        
        // Handle resource_missing error (payment intent doesn't exist)
        // This usually happens when trying to retrieve a payment intent that was cancelled/expired
        // Since we're not retrieving anymore, this should be rare, but handle it gracefully
        if (stripeError.stripeErrorCode == 'resource_missing' || 
            stripeError.message?.toLowerCase().contains('no such payment_intent') == true) {
          log('⚠️ [presentPaymentSheet] Payment intent not found - session may have expired');
          throw Exception('Payment session expired. Please try again.');
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
      
      // Check for resource_missing in error string
      if (errorString.contains('no such payment_intent') || 
          errorString.contains('resource_missing')) {
        throw Exception('Payment session expired. Please try again.');
      }
      
      // Re-throw with more context for actual errors
      // Remove technical details for user-facing error
      String userFriendlyError = e.toString();
      if (userFriendlyError.contains('Exception: ')) {
        userFriendlyError = userFriendlyError.replaceAll('Exception: ', '');
      }
      if (userFriendlyError.contains('StripeException')) {
        userFriendlyError = 'Payment processing failed. Please try again.';
      }
      
      throw Exception('Payment failed: $userFriendlyError');
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
