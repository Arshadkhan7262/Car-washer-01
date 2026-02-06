import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../util/constants.dart';
import '../../../api/api_client.dart';

/// Stripe Wallet Service
/// Handles Stripe payment processing for withdrawals
class StripeWalletService {
  /// Initialize Stripe with publishable key
  Future<void> initializeStripe() async {
    if (kIsWeb) {
      throw Exception('Stripe is not supported on web platform');
    }

    try {
      Stripe.publishableKey = AppConstants.stripePublishableKey;
      await Stripe.instance.applySettings();
      log('✅ Stripe initialized successfully (TEST MODE)');
    } catch (e) {
      log('❌ Error initializing Stripe: $e');
      throw Exception('Failed to initialize Stripe: $e');
    }
  }

  /// Present Payment Sheet for withdrawal
  /// Gets payment intent from backend and presents Stripe payment sheet
  Future<Map<String, dynamic>> presentWithdrawalPaymentSheet({
    required String withdrawalId,
    required double amount,
    required String currency,
  }) async {
    if (kIsWeb) {
      throw Exception('Payment via Stripe Payment Sheet is not supported on web.');
    }

    try {
      log('🔄 [presentWithdrawalPaymentSheet] Starting withdrawal payment flow');
      log('🔄 [presentWithdrawalPaymentSheet] Withdrawal ID: $withdrawalId, Amount: $amount, Currency: $currency');

      // Ensure Stripe is initialized - re-initialize if needed
      final publishableKey = Stripe.publishableKey;
      if (publishableKey.isEmpty) {
        log('⚠️ [presentWithdrawalPaymentSheet] Stripe publishable key not set, initializing...');
        Stripe.publishableKey = AppConstants.stripePublishableKey;
      }

      // Re-initialize Stripe to ensure it's properly set up before using payment sheet
      log('🔄 [presentWithdrawalPaymentSheet] Re-initializing Stripe...');
      try {
        await Stripe.instance.applySettings();
        log('✅ [presentWithdrawalPaymentSheet] Stripe re-initialized successfully');
      } catch (e) {
        log('❌ [presentWithdrawalPaymentSheet] Failed to re-initialize Stripe: $e');
        throw Exception('Stripe initialization failed. Please restart the app.');
      }

      // Get payment intent from backend
      log('🔄 [presentWithdrawalPaymentSheet] Requesting payment intent from backend...');
      log('   Endpoint: /washer/withdrawal/$withdrawalId/payment-intent');
      
      final clientSecret = await _getPaymentIntentFromBackend(withdrawalId);
      
      if (clientSecret == null || clientSecret.isEmpty) {
        log('❌ [presentWithdrawalPaymentSheet] No client secret received from backend');
        throw Exception('Failed to get payment intent from server. Please try again.');
      }

      log('✅ [presentWithdrawalPaymentSheet] Payment intent received from backend');
      log('   Client secret: ${clientSecret.substring(0, 20)}...');

      // Initialize payment sheet with real payment intent
      try {
        log('✅ [presentWithdrawalPaymentSheet] Initializing payment sheet...');
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Car Wash Pro',
            allowsDelayedPaymentMethods: true,
            style: ThemeMode.system,
          ),
        );

        log('✅ [presentWithdrawalPaymentSheet] Payment sheet initialized, presenting...');

        // Present payment sheet
        await Stripe.instance.presentPaymentSheet();

        log('✅ [presentWithdrawalPaymentSheet] Payment sheet completed successfully');

        // Extract payment intent ID from client secret
        final paymentIntentId = _extractPaymentIntentId(clientSecret);

        return {
          'success': true,
          'payment_intent_id': paymentIntentId,
          'transaction_id': paymentIntentId,
          'status': 'succeeded',
        };
      } on StripeException catch (e) {
        // Handle Stripe-specific errors
        if (e.error.code == FailureCode.Canceled) {
          log('ℹ️ [presentWithdrawalPaymentSheet] User cancelled the payment');
          throw Exception('Payment was cancelled by user');
        } else {
          log('❌ [presentWithdrawalPaymentSheet] Stripe error: ${e.error.message}');
          rethrow;
        }
      }
    } catch (e) {
      log('❌ [presentWithdrawalPaymentSheet] Error: $e');

      // Check if user cancelled
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('canceled') || errorString.contains('cancelled')) {
        log('ℹ️ [presentWithdrawalPaymentSheet] User cancelled the payment');
        throw Exception('Payment was cancelled by user');
      }

      // Re-throw with more context
      String userFriendlyError = e.toString();
      if (userFriendlyError.contains('Exception: ')) {
        userFriendlyError = userFriendlyError.replaceAll('Exception: ', '');
      }

      throw Exception('Payment failed: $userFriendlyError');
    }
  }

  /// Get payment intent from backend
  Future<String?> _getPaymentIntentFromBackend(String withdrawalId) async {
    try {
      log('🌐 [getPaymentIntentFromBackend] Calling API: /washer/withdrawal/$withdrawalId/payment-intent');
      final apiClient = ApiClient();
      final response = await apiClient.post(
        '/washer/withdrawal/$withdrawalId/payment-intent',
        body: {},
      );

      log('📥 [getPaymentIntentFromBackend] Response success: ${response.success}');
      log('📥 [getPaymentIntentFromBackend] Status code: ${response.statusCode}');

      if (response.success && response.data != null) {
        final data = response.data['data'];
        log('📦 [getPaymentIntentFromBackend] Response data keys: ${data?.keys}');
        
        final clientSecret = data?['client_secret'] as String?;
        if (clientSecret != null && clientSecret.isNotEmpty) {
          log('✅ [getPaymentIntentFromBackend] Client secret received');
          return clientSecret;
        } else {
          log('❌ [getPaymentIntentFromBackend] Client secret is null or empty');
          log('   Data: $data');
        }
      } else {
        log('❌ [getPaymentIntentFromBackend] API call failed');
        log('   Error: ${response.error}');
        log('   Data: ${response.data}');
      }

      return null;
    } catch (e) {
      log('❌ [getPaymentIntentFromBackend] Exception: $e');
      log('   Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Extract payment intent ID from client secret
  String _extractPaymentIntentId(String clientSecret) {
    // Client secret format: pi_xxx_secret_xxx
    final parts = clientSecret.split('_secret_');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return 'pi_unknown';
  }

  /// Process withdrawal with Stripe
  /// Opens Stripe payment sheet for approved withdrawal
  Future<Map<String, dynamic>> processWithdrawal({
    required String withdrawalId,
    required double amount,
    required String currency,
  }) async {
    try {
      log('🔄 [processWithdrawal] Processing withdrawal');
      log('   Withdrawal ID: $withdrawalId');
      log('   Amount: \$$amount $currency');

      // Use payment sheet for withdrawal
      final result = await presentWithdrawalPaymentSheet(
        withdrawalId: withdrawalId,
        amount: amount,
        currency: currency,
      );

      log('✅ [processWithdrawal] Withdrawal processed successfully');
      log('   Payment Intent ID: ${result['payment_intent_id']}');

      return {
        'success': true,
        'payment_intent_id': result['payment_intent_id'],
        'transaction_id': result['transaction_id'],
        'amount': amount,
        'currency': currency,
      };
    } catch (e) {
      log('❌ [processWithdrawal] Error: $e');
      rethrow;
    }
  }

  /// Check if Stripe is properly initialized
  bool isStripeInitialized() {
    final publishableKey = Stripe.publishableKey;
    return publishableKey.isNotEmpty &&
        publishableKey.startsWith('pk_test_') &&
        publishableKey == AppConstants.stripePublishableKey;
  }
}
