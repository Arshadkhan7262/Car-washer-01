import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';
import '../services/wallet_service.dart';

enum WalletPeriod { today, thisWeek, thisMonth }

class WalletController extends GetxController {
  final WalletService _walletService = WalletService();
  final AuthService _authService = AuthService();
  
  var selectedPeriod = WalletPeriod.today.obs;
  var isLoading = true.obs;

  // Wallet data
  var balance = 0.00.obs; // Wallet balance
  var earnings = 0.00.obs; // Earnings for selected period
  var jobsCompleted = 0.obs; // Jobs completed for selected period

  @override
  void onInit() {
    super.onInit();
    loadWalletData();
  }

  /// Load wallet data from API
  Future<void> loadWalletData() async {
    try {
      isLoading.value = true;
      
      // Check if account is pending or suspended - don't call API
      final cachedStatus = await _authService.getCachedAccountStatus();
      if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
        // Set default values for pending/suspended accounts
        balance.value = 0.0;
        earnings.value = 0.0;
        jobsCompleted.value = 0;
        isLoading.value = false;
        return;
      }
      
      // Get wallet balance
      final balanceData = await _walletService.getWalletBalance();
      if (balanceData != null) {
        balance.value = (balanceData['balance'] ?? 0).toDouble();
      }
      
      // Load stats for current period
      await loadPeriodStats();
    } catch (e) {
      print('Error loading wallet data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load stats for selected period
  Future<void> loadPeriodStats() async {
    try {
      String period;
      switch (selectedPeriod.value) {
        case WalletPeriod.today:
          period = 'today';
          break;
        case WalletPeriod.thisWeek:
          period = 'week';
          break;
        case WalletPeriod.thisMonth:
          period = 'month';
          break;
      }
      
      final stats = await _walletService.getWalletStats(period);
      
      if (stats != null) {
        earnings.value = (stats['earnings'] ?? 0).toDouble();
        jobsCompleted.value = stats['jobs_completed'] ?? 0;
      }
    } catch (e) {
      print('Error loading period stats: $e');
    }
  }

  /// Change period and reload stats
  void changePeriod(WalletPeriod period) {
    selectedPeriod.value = period;
    loadPeriodStats();
  }

  /// Request withdrawal
  Future<void> requestWithdrawal(double amount) async {
    try {
      final success = await _walletService.requestWithdrawal(amount);
      
      if (success) {
        Get.snackbar("Success", "Withdrawal request sent successfully");
        // Refresh wallet data
        await loadWalletData();
      } else {
        Get.snackbar("Error", "Failed to send withdrawal request");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to send withdrawal request: $e");
    }
  }
  
  /// Refresh wallet data
  Future<void> refreshData() async {
    await loadWalletData();
  }
}
