import 'package:car_wash_app/theme/app_colors.dart';
import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX for navigation
import '../models/job_model.dart';
import '../screens/jod_detail_screen.dart';
import '../controllers/jobs_controller.dart';
import '../services/jobs_service.dart';

class JobCard extends StatelessWidget {
  final JobModel job;

    JobCard({super.key, required this.job});

  final JobsService _jobsService = JobsService();

  Future<void> _handleAccept() async {
    try {
      final success = await _jobsService.acceptJob(job.id);
      if (success) {
        final jobController = Get.find<JobController>();
        
        // Refresh jobs to get updated status
        await jobController.fetchJobs();
        
        // Navigate to active tab since job is now accepted
        jobController.changeTab(JobStatus.active);
        
        Get.snackbar(
          'Success', 
          'Job accepted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error', 
          'Failed to accept job',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Error accepting job: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleReject() async {
    try {
      final success = await _jobsService.rejectJob(job.id);
      if (success) {
        Get.find<JobController>().fetchJobs();
        Get.snackbar('Success', 'Job rejected',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'Failed to reject job',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error rejecting job: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNew = job.status == JobStatus.newJob;
    bool isActive = job.status == JobStatus.active;

    return GestureDetector(
      // Navigation triggers when the whole card is tapped
      onTap: () => Get.to(() => JobDetailScreen(jobId: job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.black, width: 1),
          color: AppColors.white,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildVehicleIcon(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.customerName,
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: "Inter",
                                color: AppColors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            FittedBox(
                              child: Text(
                                "${job.vehicleType} • ${job.vehicleModel}",
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontFamily: "Inter",
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFF5E9FF)
                              : Color(0xFF6CB6FF).withOpacity(0.36),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isActive ? "Arrived" : "Confirm",
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFFA855F7)
                                : Color(0xFF2D4DD0),
                            fontSize: 14,
                            fontFamily: "Inter",
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _infoRow(AppImages.lucide_car, job.serviceName),
                  const SizedBox(height: 10),
                  _infoRow(AppImages.time, job.dateTime),
                  const SizedBox(height: 10),
                  _infoRow(AppImages.location, job.address),
                ],
              ),
            ),
            Divider(height: 1, color: Color(0xFF0A2540).withOpacity(0.49)),
            Padding(
              padding: const EdgeInsets.only(
                left: 9,
                right: 12,
                top: 16,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(AppImages.wallet, height: 28, width: 28),
                      const SizedBox(width: 3),
                      Text(
                        job.price.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (isNew)
                    Row(
                      children: [
                        _btn("Decline", Colors.red, true, 68, _handleReject),
                        const SizedBox(width: 8),
                        _btn(
                          "Accept Job",
                          const Color(0xFF0A2540),
                          false,
                          93,
                          _handleAccept,
                        ),
                      ],
                    )
                  else if (isActive)
                    Row(
                      children: [
                        Text(
                          "View Detail",
                          style: TextStyle(
                            color: AppColors.black.withOpacity(0.48),
                            fontSize: 10,
                            fontFamily: "Inter",
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: AppColors.black.withOpacity(0.48),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Button helper to accept an onTap callback
  Widget _btn(
    String txt,
    Color col,
    bool outlined,
    double width,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        width: width,
        // padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : col,
          border: outlined ? Border.all(color: col) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            txt,
            style: TextStyle(
              color: outlined ? col : Colors.white,
              fontWeight: FontWeight.w400,
              fontFamily: "Inter",
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(AppImages.truck),
    );
  }

  Widget _infoRow(String imagePath, String text) {
    return Row(
      children: [
        Image.asset(imagePath, height: 11, width: 18),
        const SizedBox(width: 8),
        FittedBox(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.black.withOpacity(0.48),
              fontFamily: "Inter",
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
