import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/performance_card.dart';
import '../widgets/settings_list.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Subtle grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2540),
        elevation: 0,
        title: Text(
          "My Profile",
          style: TextStyle(
            fontFamily: "Inter",
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ProfileHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  _buildStatusToggle(controller),
                  const SizedBox(height: 20),
                  const PerformanceCard(),
                  const SizedBox(height: 20),
                  const SettingsList(),
                  const SizedBox(height: 17),
                  _buildSignOutButton(controller),
                  const SizedBox(height: 15),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      fontFamily: "Inter",
                      color: AppColors.black.withOpacity(0.47),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(ProfileController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF2AE6C3)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 4, backgroundColor: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isOnline.value
                        ? "You are online"
                        : "You are offline",
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    "Go online to receive jobs",
                    style: TextStyle(
                      color: AppColors.white,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: controller.isOnline.value,
              onChanged: (val) => controller.toggleStatus(val),
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(ProfileController controller) {
    return GestureDetector(
      onTap: () => controller.signOut(),
      child: Container(
        height: 52,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppImages.logOut, height: 24, width: 24),
            SizedBox(width: 10),
            Text(
              "Sign Out",
              style: TextStyle(
                fontFamily: "Inter",
                color: AppColors.red,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
