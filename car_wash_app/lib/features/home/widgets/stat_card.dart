import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Container(
      height: Get.height * (78 / Get.height),
      width: Get.width * (382 / Get.width),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Color(0xFFF7FFFE),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF000000).withOpacity(0.25),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Aligns items vertically in the center
        children: [
          // Status indicator dot
          Obx(
            () => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.isOnline.value
                    ? Colors.green
                    : Color(0xFF0A2540).withOpacity(0.49),
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Text section
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    controller.isOnline.value
                        ? "You are online"
                        : "You are offline",
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: "Inter",
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                Text(
                  "Go online to receive jobs",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: "Inter",
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0A2540).withOpacity(0.49),
                  ),
                ),
              ],
            ),
          ),
          // Toggle Switch
          Obx(
            () => Switch.adaptive(
              value: controller.isOnline.value,
              activeColor: Colors.white,
              activeTrackColor: Colors.green,
              trackOutlineColor: MaterialStateColor.resolveWith(
                (states) => const Color(0xFF0A2540).withOpacity(0.49),
              ),
              thumbIcon: MaterialStateProperty.all(
                Icon(
                  Icons.circle,
                  color: const Color(0xFF0A2540).withOpacity(0.49),
                ),
              ),
              thumbColor: MaterialStateColor.resolveWith(
                (states) => controller.isOnline.value
                    ? Colors.white
                    : Color(0xFF0A2540).withOpacity(0.49),
              ),
              onChanged: (value) {
                controller.toggleStatus(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
