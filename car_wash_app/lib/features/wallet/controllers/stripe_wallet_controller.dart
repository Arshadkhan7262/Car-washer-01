import 'package:get/get.dart';
import '../services/stripe_wallet_service.dart';

/// Stripe Wallet Controller
class StripeWalletController extends GetxController {
  final StripeWalletService _stripeService = StripeWalletService();

  var isProcessing = false.obs;
  var isStripeInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkStripeInitialization();
  }

  /// Check if Stripe is initialized
  void _checkStripeInitialization() {
    isStripeInitialized.value = _stripeService.isStripeInitialized();
  }

  /// Process withdrawal using Stripe Payment Sheet
  Future<void> processWithdrawal({
    required String withdrawalId,
    required double amount,
    required String currency,
  }) async {
    try {
      isProcessing.value = true;

      // Check if Stripe is initialized
      if (!isStripeInitialized.value) {
        Get.snackbar(
          'Error',
          'Stripe is not initialized. Please restart the app.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }

      // Validate amount
      if (amount <= 0) {
        Get.snackbar(
          'Error',
          'Please enter a valid withdrawal amount',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }

      // Validate withdrawal ID
      if (withdrawalId.isEmpty) {
        Get.snackbar(
          'Error',
          'Withdrawal ID is required',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }

      // Process withdrawal with Stripe
      final result = await _stripeService.processWithdrawal(
        withdrawalId: withdrawalId,
        amount: amount,
        currency: currency,
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          'Withdrawal processed successfully (TEST MODE)',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 3),
        );

        // Refresh wallet data if needed
        // You can add a callback here to refresh the wallet balance
      } else {
        Get.snackbar(
          'Error',
          'Failed to process withdrawal',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }
      if (errorMessage.contains('Payment was cancelled')) {
        errorMessage = 'Withdrawal was cancelled';
      }

      Get.snackbar(
        'Withdrawal Failed',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessing.value = false;
    }
  }
}
