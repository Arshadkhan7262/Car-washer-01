import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    
    return Obx(() => Stack(
      children: [
        // Navy Background Block
        Container(height: 60, color: const Color(0xFF0A2540)),
        // White Profile Card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.25),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF0A2540),
                          child: Text(
                            _getInitials(controller.userName.value),
                            style: const TextStyle(
                              fontFamily: "Inter",
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.userName.value.isEmpty 
                                  ? "Loading..." 
                                  : controller.userName.value,
                              style: const TextStyle(
                                fontFamily: "Inter",
                                color: AppColors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFB800),
                                  size: 18,
                                ),
                                Text(
                                  " ${controller.userRating.value.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontFamily: "Inter",
                                    color: AppColors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  "  • ${controller.completedJobs.value} jobs",
                                  style: TextStyle(
                                    fontFamily: "Inter",
                                    color: AppColors.black.withOpacity(0.48),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _infoBox(AppImages.mail, "Email", controller.email.value.isEmpty ? "N/A" : controller.email.value),
                    const SizedBox(height: 12),
                    _infoBox(AppImages.phone, "Phone", controller.phone.value.isEmpty ? "N/A" : controller.phone.value),
                  ],
                ),
        ),
      ],
    ));
  }

  Widget _infoBox(String imagePath, String label, String value) {
    return Container(
      // height: 57,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(
          0xFF6CB6FF,
        ).withOpacity(0.10), // Exact Figma light blue
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Image.asset(imagePath, height: 12, width: 16),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: "Inter",
                  color: AppColors.black.withOpacity(0.48),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: "Inter",
                  color: AppColors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
