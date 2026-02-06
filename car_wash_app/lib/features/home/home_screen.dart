import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/stat_card.dart';
import 'widgets/stats_grid.dart';
import 'widgets/quick_actions.dart';
import 'widgets/schedule_view.dart';
import 'controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Header Section
            Container(
              width: double.infinity,
              height: Get.height * (218 / Get.height),
              decoration: const BoxDecoration(
                color: Color(0xFF031E3D), // Deep Navy
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: Get.width * (23 / Get.width),
                  top: Get.height * (58 / Get.height),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome Back,",
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontFamily: "Inter",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: Get.height * (7 / Get.height)),
                    Obx(
                      () => Text(
                        controller.isLoading.value 
                          ? "Loading..." 
                          : (controller.washerName.value.isEmpty 
                              ? "Washer" 
                              : controller.washerName.value),
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 24,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: Get.height * (25 / Get.height)),
                    Container(
                      height: Get.height * (38 / Get.height),
                      width: Get.width * (128 / Get.width),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFD51B),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Obx(
                            () => Text(
                              "${controller.rating.value}  ",
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 15,
                                fontFamily: "Inter",
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            "• ${controller.jobsCount.value}jobs",
                            style: TextStyle(
                              color: Color(0xFFD9D9D9).withOpacity(0.57),
                              fontSize: 15,
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  // Overlapping Status Card
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: const StatusCard(),
                  ),
                  const StatsGrid(),
                  const SizedBox(height: 26),
                  const QuickActions(),
                  const SizedBox(height: 22),
                  const ScheduleView(),
                  const SizedBox(height: 20), // Extra padding at bottom for better scrolling
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
