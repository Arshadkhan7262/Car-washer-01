import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/wallet_controller.dart';
import 'package:intl/intl.dart';

class TransactionHistory extends StatelessWidget {
  const TransactionHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transaction History",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          // TODO: Fetch transactions from API
          // For now, show empty state
          return Center(
            child: Column(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(5.42),
                  ),
                  child: Image.asset(
                    AppImages.wallet,
                    color: AppColors.black.withOpacity(0.48),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "No Transactions",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  "No transaction found for ${_getPeriodText(controller.selectedPeriod.value)}.",
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black.withOpacity(0.48),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getPeriodText(WalletPeriod period) {
    switch (period) {
      case WalletPeriod.today:
        return 'today';
      case WalletPeriod.thisWeek:
        return 'this week';
      case WalletPeriod.thisMonth:
        return 'this month';
    }
  }
}
