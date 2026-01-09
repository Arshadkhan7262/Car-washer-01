import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../controllers/jobs_controller.dart';
import '../widgets/job_card.dart';
import '../widgets/job_tab_bar.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JobController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          "My Jobs",
          style: TextStyle(
            fontFamily: "Inter",
            color: AppColors.black,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 21),
          const JobTabBar(), // Ensure your TabBar calls controller.changeTab
          const SizedBox(height: 31),
          Expanded(
            child: Obx(() {
              var jobs = controller.filteredJobs;
              if (jobs.isEmpty) {
                return Center(
                  child: Text(
                    "No ${controller.selectedTab.value.name} jobs found",
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: jobs.length,
                itemBuilder: (context, index) => JobCard(job: jobs[index]),
              );
            }),
          ),
        ],
      ),
    );
  }
}
