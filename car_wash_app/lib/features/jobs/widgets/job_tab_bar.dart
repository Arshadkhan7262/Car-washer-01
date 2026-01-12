import 'package:car_wash_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/jobs_controller.dart';
import '../models/job_model.dart';

class JobTabBar extends StatelessWidget {
  const JobTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JobController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 42,
        width: Get.width * 0.9,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: Color(0xFF6CB6FF).withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            _buildTab(JobStatus.newJob, Icons.access_time, "New", controller),
            _buildTab(JobStatus.active, Icons.list_alt, "Active", controller),
            _buildTab(
              JobStatus.done,
              Icons.check_circle_outline,
              "Done",
              controller,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    JobStatus status,
    IconData icon,
    String label,
    JobController controller,
  ) {
    return Expanded(
      child: Obx(() {
        bool isSelected = controller.selectedTab.value == status;
        return GestureDetector(
          onTap: () => controller.changeTab(status),
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? AppColors.black : AppColors.black,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
                    color: isSelected ? Colors.black : Colors.black54,
                  ),
                ),
                if (status == JobStatus.newJob) ...[
                  const SizedBox(width: 6),
                  Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: Color(0xFF6CB6FF).withOpacity(0.36),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: FittedBox(
                        child: Text(
                          "${controller.newJobsCount}",
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontSize: 12,
                            color: Color(0xFF2D4DD0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
