import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionItem(
          AppImages.jobs,
          "View Jobs",
          const Color(0xFF6CB6FF1A).withOpacity(0.10),
          Colors.blue,
        ),
        _actionItem(
          AppImages.wallet,
          "Wallet",
          const Color(0xFFE8F5E9),
          Colors.green,
        ),
        _actionItem(
          AppImages.profile,
          "Profile",
          const Color(0xFFF3E5F5),
          Colors.purple,
        ),
      ],
    );
  }

  Widget _actionItem(
    String Imagepath,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      height: Get.height * 0.11,
      width: Get.width * 0.26,
      // padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.25),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: Get.height * 0.05,
            width: Get.width * 0.11,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(5.42),
            ),
            child: Image.asset(Imagepath, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: "Inter",
              // fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
