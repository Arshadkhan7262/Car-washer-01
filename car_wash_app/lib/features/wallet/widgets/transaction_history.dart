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
          if (controller.isLoadingTransactions.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.transactions.isEmpty) {
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
          }

          // Scrollable transaction list
          return Container(
            height: 400, // Fixed height for scrollable area
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: controller.transactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final transaction = controller.transactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] ?? 'unknown';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final status = transaction['status'] ?? 'completed';
    final date = transaction['created_at'] != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(DateTime.parse(transaction['created_at']))
        : 'Unknown date';

    // Determine icon and color based on type and status
    IconData icon;
    Color color;
    String title;

    if (type == 'withdrawal') {
      icon = Icons.arrow_upward;
      if (status == 'completed') {
        color = Colors.green;
        title = 'Withdrawal';
      } else if (status == 'failed' || status == 'rejected') {
        color = Colors.red;
        title = 'Withdrawal Failed';
      } else {
        color = Colors.orange;
        title = 'Withdrawal Pending';
      }
    } else if (type == 'earning' || type == 'job_payment') {
      icon = Icons.arrow_downward;
      color = Colors.green;
      title = 'Job Payment';
    } else {
      icon = Icons.account_balance_wallet;
      color = Colors.blue;
      title = type.replaceAll('_', ' ').toUpperCase();
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      subtitle: Text(
        date,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.black.withOpacity(0.6),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            type == 'withdrawal' ? '-\$${amount.toStringAsFixed(2)}' : '+\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: type == 'withdrawal' ? Colors.red : Colors.green,
            ),
          ),
          if (status != 'completed')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'failed' || status == 'rejected'
                    ? Colors.red.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: status == 'failed' || status == 'rejected'
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ),
        ],
      ),
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
