import 'package:flutter/material.dart';
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
    loadApprovedWithdrawal();
    loadTransactions();
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
      } else {
        // Reset to 0 if no stats available
        earnings.value = 0.0;
        jobsCompleted.value = 0;
      }
    } catch (e) {
      print('Error loading period stats: $e');
      // Reset to 0 on error
      earnings.value = 0.0;
      jobsCompleted.value = 0;
    }
  }

  /// Change period and reload stats
  void changePeriod(WalletPeriod period) {
    selectedPeriod.value = period;
    loadPeriodStats();
    loadTransactions();
  }

  // Withdrawal limit
  var withdrawalLimit = 2000.0.obs;

  /// Get minimum withdrawal limit
  Future<double?> getWithdrawalLimit() async {
    try {
      final limit = await _walletService.getWithdrawalLimit();
      if (limit != null) {
        withdrawalLimit.value = limit;
      }
      return limit;
    } catch (e) {
      print('Error fetching withdrawal limit: $e');
      return null;
    }
  }

  /// Request withdrawal
  Future<void> requestWithdrawal(double amount) async {
    try {
      isLoading.value = true;
      
      final result = await _walletService.requestWithdrawal(amount);
      
      if (result != null && result['success'] == true) {
        Get.snackbar(
          "Success",
          "Withdrawal request sent successfully. Waiting for admin approval.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.black,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        // Refresh wallet data
        await loadWalletData();
      } else {
        final errorMsg = result?['error'] ?? 'Failed to send withdrawal request';
        Get.snackbar(
          "Error",
          errorMsg,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.black,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send withdrawal request: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.black,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Approved withdrawal
  var approvedWithdrawal = Rx<Map<String, dynamic>?>(null);

  /// Load approved withdrawal
  Future<void> loadApprovedWithdrawal() async {
    try {
      final withdrawals = await _walletService.getWithdrawalHistory(status: 'approved');
      if (withdrawals != null && withdrawals.isNotEmpty) {
        approvedWithdrawal.value = withdrawals.first;
      } else {
        approvedWithdrawal.value = null;
      }
    } catch (e) {
      print('Error loading approved withdrawal: $e');
      approvedWithdrawal.value = null;
    }
  }

  /// Process approved withdrawal
  Future<bool> processApprovedWithdrawal(String withdrawalId) async {
    try {
      final result = await _walletService.processApprovedWithdrawal(withdrawalId);
      if (result != null && result['success'] == true) {
        approvedWithdrawal.value = null; // Clear approved withdrawal
        await loadWalletData(); // Refresh balance
        return true;
      }
      return false;
    } catch (e) {
      print('Error processing withdrawal: $e');
      return false;
    }
  }

  // Transactions
  var transactions = <Map<String, dynamic>>[].obs;
  var isLoadingTransactions = false.obs;

  /// Load transactions
  Future<void> loadTransactions() async {
    try {
      isLoadingTransactions.value = true;
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

      final data = await _walletService.getTransactions(period: period);
      if (data != null && data['transactions'] != null) {
        transactions.value = List<Map<String, dynamic>>.from(data['transactions']);
      } else {
        transactions.value = [];
      }
    } catch (e) {
      print('Error loading transactions: $e');
      transactions.value = [];
    } finally {
      isLoadingTransactions.value = false;
    }
  }
  
  /// Refresh wallet data
  Future<void> refreshData() async {
    await loadWalletData();
    await loadApprovedWithdrawal();
    await loadTransactions();
  }
}
