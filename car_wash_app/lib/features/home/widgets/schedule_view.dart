import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Schedule",
              style: TextStyle(
                fontFamily: "Inter",
                fontSize: 21,
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "View All",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 12,
                  color: AppColors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        // const SizedBox(height: 22),
        Container(
          height: 48,
          width: 48,
          // padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            AppImages.jobs,
            color: AppColors.black.withOpacity(0.57),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "No Jobs Today",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 18,
            color: AppColors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "You don't have any jobs scheduled for today. Check back later",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 14,
            color: AppColors.black.withOpacity(0.48),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
