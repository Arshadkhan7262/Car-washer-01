import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../controllers/wallet_controller.dart';

class WalletStatsGrid extends StatelessWidget {
  const WalletStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();

    return Row(
      children: [
        Expanded(
          child: Obx(
            () => _statItem(
              "Earning",
              "\$${controller.earnings.value.toStringAsFixed(2)}",
              AppImages.updateLive,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Obx(
            () => _statItem(
              "Jobs Completed",
              "${controller.jobsCompleted.value}",
              AppImages.jobs,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String title, String val, String imagepath) {
    return Container(
      height: 99,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.42),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.black,
                    fontFamily: "Inter",
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: AppColors.black.withOpacity(0.10),
              borderRadius: BorderRadius.circular(5.42),
            ),
            child: Image.asset(imagepath),
          ),
        ],
      ),
    );
  }
}
