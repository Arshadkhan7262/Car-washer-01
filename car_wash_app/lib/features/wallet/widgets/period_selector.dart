import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/wallet_controller.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTab(WalletPeriod.today, "Today", controller),
          _buildTab(WalletPeriod.thisWeek, "This Week", controller),
          _buildTab(WalletPeriod.thisMonth, "This Month", controller),
        ],
      ),
    );
  }

  Widget _buildTab(
    WalletPeriod period,
    String label,
    WalletController controller,
  ) {
    return Obx(() {
      // FIXED: Changed selectedTab to selectedPeriod
      bool isSelected = controller.selectedPeriod.value == period;

      return GestureDetector(
        onTap: () => controller.changePeriod(period),
        child: Container(
          height: 32,
          width: 98,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.25),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSelected ? 16 : 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
              color: isSelected ? AppColors.black : AppColors.black,
            ),
          ),
        ),
      );
    });
  }
}
