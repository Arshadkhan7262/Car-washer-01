import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class PerformanceCard extends StatelessWidget {
  const PerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    
    return Container(
      height: 168,
      padding: EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(6),
        // Subtle grey border as seen in designs
        boxShadow: [
          BoxShadow(
            spreadRadius: 0,
            blurRadius: 4,
            offset: Offset(0, 0),
            color: AppColors.black.withOpacity(0.25),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Performance",
            style: TextStyle(
              fontFamily: "Inter",
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: [
              _statBox(
                AppImages.jobs,
                controller.totalJobs.value.toString(),
                "Total Jobs",
                const Color(0xFF2D4DD0), // Blue icon
              ),
              const SizedBox(width: 12),
              _statBox(
                AppImages.profile,
                controller.userRating.value.toStringAsFixed(1),
                "Total Rating",
                const Color(0xFFF59E0B), // Orange icon
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _statBox(String imagePath, String val, String label, Color iconColor) {
    return Expanded(
      child: Container(
        height: 106,
        padding: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          // Subtle grey border as seen in designs
          boxShadow: [
            BoxShadow(
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 0),
              color: AppColors.black.withOpacity(0.25),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 21, width: 24, color: iconColor),
            const SizedBox(height: 1.7),
            Text(
              val,
              style: const TextStyle(
                fontSize: 24,
                fontFamily: "Inter",
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: "Inter",
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
