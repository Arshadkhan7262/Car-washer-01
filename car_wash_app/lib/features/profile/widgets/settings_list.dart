import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';

class SettingsList extends StatelessWidget {
  const SettingsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * (300 / Get.height),
      // padding: const EdgeInsets.symmetric(vertical: 8),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 21),
            child: Text(
              "Settings",
              style: TextStyle(
                fontSize: 16,
                fontFamily: "Inter",
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
          _item(
            Icons.notifications_none_rounded,
            "Notifications",
            AppImages.notification,
            Color(0xFFF6CB6FF).withOpacity(0.36),
          ),
          // _item(
          //   Icons.language_rounded,
          //   "Language",
          //   AppImages.language,
          //   Color(0xFFB84CD1).withOpacity(0.10),
          //   trailing: "English",
          // ),
          _item(
            Icons.shield_outlined,
            "Privacy & Security",
            AppImages.privacy,
            AppColors.black.withOpacity(0.10),
          ),
          _item(
            Icons.settings_outlined,
            "App Settings",
            AppImages.setting,
            AppColors.black.withOpacity(0.10),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _item(
    IconData icon,
    String title,
    String imagePath,
    Color bg, {
    String? trailing,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            height: 30,
            width: 30,
            // padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(5.42),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(imagePath, height: 16, width: 16),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: "Inter",
              fontWeight: FontWeight.w400,
              color: AppColors.black,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null)
                Text(
                  trailing,
                  style: TextStyle(
                    fontFamily: "Inter",
                    fontSize: 12,
                    color: AppColors.black.withOpacity(0.48),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.black.withOpacity(0.48),
              ),
            ],
          ),
        ),
        if (!isLast) ...{
          SizedBox(height: 12),
          Divider(
            height: 1,
            indent: 20,
            endIndent: 16,
            color: Color(0xFF0A2540).withOpacity(.20),
          ),
        },
      ],
    );
  }
}
