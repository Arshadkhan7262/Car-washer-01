import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';
import 'period_selector.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  void _showWithdrawalDialog(BuildContext context, WalletController controller) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Withdrawal'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter withdrawal amount',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                controller.requestWithdrawal(amount);
              } else {
                Get.snackbar('Error', 'Please enter a valid amount');
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Find the existing controller
    final controller = Get.find<WalletController>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 30),
          decoration: const BoxDecoration(color: Color(0xFF031E3D)),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFD9D9D9).withOpacity(0.22),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Premium Wash",
                          style: TextStyle(
                            color: AppColors.white,
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 11),
                        // MUST wrap in Obx to show the 1250.00 value
                        Obx(
                          () => Text(
                            "\$${controller.balance.value.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: AppColors.black,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 52,
                      width: 52,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(5.42),
                      ),
                      child: Image.asset(AppImages.selectedWellet),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () {
                    // Show dialog to enter withdrawal amount
                    _showWithdrawalDialog(context, controller);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(AppImages.arrowUp, height: 19, width: 19),
                      const SizedBox(width: 8),
                      const Text(
                        "Request Withdrawal",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const PeriodSelector(),
          ),
        ),
      ],
    );
  }
}
