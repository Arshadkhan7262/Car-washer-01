import 'package:car_wash_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/wallet_controller.dart';
import 'widgets/balance_card.dart';
import 'widgets/transaction_history.dart';
import 'widgets/wallet_stats_grid.dart';
import 'widgets/approved_withdrawal_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WalletController());
    
    // Refresh wallet data when screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshData();
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF031E3D), // Match Home Navy
        elevation: 0,
        title: const Text(
          "My Wallet",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const BalanceCard(),
            // Show approved withdrawal card if available
            Obx(() {
              if (controller.approvedWithdrawal.value != null) {
                return ApprovedWithdrawalCard(
                  withdrawal: controller.approvedWithdrawal.value!,
                );
              }
              return const SizedBox.shrink();
            }),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WalletStatsGrid(),
                  const SizedBox(height: 25),
                  const TransactionHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
