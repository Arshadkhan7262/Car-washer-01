import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    
    return Row(
      children: [
        // Today's Jobs Card
        Expanded(
          child: Obx(
            () => _buildStatCard(
              title: "Today's Jobs",
              value: "\$${controller.earnings.value.toStringAsFixed(2)}",
              subtitle: "${controller.jobsCount.value} total completed",
              ImagePath: Image.asset(AppImages.selectedJobs),
              isPositive: false,
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Today's Earning Card
        Expanded(
          child: Obx(
            () => _buildStatCard(
              title: "Today's Earning",
              value: "\$${controller.earnings.value.toStringAsFixed(2)}",
              subtitle: "+12% vs last week",
              ImagePath: Image.asset(AppImages.updateLive),
              isPositive: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? live = "Live Update",
    required String subtitle,
    required Image ImagePath,
    required bool isPositive,
  }) {
    return Container(
      height: Get.height * (133 / Get.height),
      width: Get.width * (180 / Get.width),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.25),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 11,
          right: 10,
          // top: Get.height * (20 / Get.height),
          // bottom: Get.height * (30 / Get.height),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Inter",
                    color: AppColors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    height: 34,
                    width: 34,
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.black.withOpacity(0.10),
                    ),
                    child: ImagePath,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: "Inter",
                    color: AppColors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isPositive)
                  Text(
                    live!,
                    style: const TextStyle(
                      fontFamily: "Inter",
                      color: AppColors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isPositive ? AppColors.green : AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
