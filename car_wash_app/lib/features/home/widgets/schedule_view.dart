import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../jobs/controllers/jobs_controller.dart';
import '../../jobs/models/job_model.dart';
import '../../jobs/screens/jod_detail_screen.dart';
import '../../dashboard/dashboard_controller.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  /// Get today's jobs from JobController
  List<JobModel> _getTodayJobs() {
    if (!Get.isRegistered<JobController>()) {
      return [];
    }
    
    final jobController = Get.find<JobController>();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return jobController.allJobs.where((job) {
      // Parse booking_date from dateTime string (format: "MMM d, yyyy • time")
      if (job.dateTime.isEmpty) {
        return false;
      }
      
      try {
        final dateTimeParts = job.dateTime.split(' • ');
        if (dateTimeParts.isNotEmpty) {
          final dateStr = dateTimeParts[0].trim();
          
          // Try parsing with the expected format
          DateTime? parsedDate;
          try {
            parsedDate = DateFormat('MMM d, yyyy').parse(dateStr);
          } catch (e) {
            // Try alternative formats
            try {
              parsedDate = DateFormat('MMM d yyyy').parse(dateStr);
            } catch (e2) {
              try {
                parsedDate = DateTime.parse(dateStr);
              } catch (e3) {
                return false;
              }
            }
          }
          
          if (parsedDate != null) {
            final jobDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            // Check if job is today or in the future (for today's schedule)
            return jobDate.isAtSameMomentAs(todayStart) || 
                   (jobDate.isAfter(todayStart) && jobDate.isBefore(todayEnd));
          }
        }
      } catch (e) {
        // If parsing fails, skip this job
        return false;
      }
      return false;
    }).toList()
      ..sort((a, b) {
        // Sort by status: new jobs first, then active, then done
        if (a.status != b.status) {
          if (a.status == JobStatus.newJob) return -1;
          if (b.status == JobStatus.newJob) return 1;
          if (a.status == JobStatus.active) return -1;
          if (b.status == JobStatus.active) return 1;
        }
        // Then sort by dateTime
        return a.dateTime.compareTo(b.dateTime);
      });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure JobController is initialized
    if (!Get.isRegistered<JobController>()) {
      Get.put(JobController());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              onPressed: () {
                // Navigate to Jobs tab (index 1)
                if (Get.isRegistered<DashboardController>()) {
                  final dashboardController = Get.find<DashboardController>();
                  dashboardController.changeIndex(1);
                }
              },
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
        const SizedBox(height: 16),
        Obx(() {
          if (!Get.isRegistered<JobController>()) {
            return _buildEmptyState();
          }
          
          final jobController = Get.find<JobController>();
          
          // Show loading state if jobs are being fetched
          if (jobController.isLoading.value && jobController.allJobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final todayJobs = _getTodayJobs();
          
          if (todayJobs.isEmpty) {
            return _buildEmptyState();
          }
          
          // Show up to 3 jobs, then "View All" for more
          final jobsToShow = todayJobs.take(3).toList();
          final hasMore = todayJobs.length > 3;
          
          return Column(
            children: [
              ...jobsToShow.map((job) => _buildScheduleCard(job)),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () {
                      if (Get.isRegistered<DashboardController>()) {
                        final dashboardController = Get.find<DashboardController>();
                        dashboardController.changeIndex(1);
                      }
                    },
                    child: Text(
                      "View ${todayJobs.length - 3} more jobs",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: 14,
                        color: AppColors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildScheduleCard(JobModel job) {
    final isNew = job.status == JobStatus.newJob;
    final isActive = job.status == JobStatus.active;
    
    return GestureDetector(
      onTap: () {
        // Navigate to job detail screen
        Get.to(() => JobDetailScreen(jobId: job.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Time/Status indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: isNew 
                    ? Colors.blue 
                    : isActive 
                        ? Colors.purple 
                        : Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Job details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.customerName,
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontSize: 16,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isNew
                              ? Colors.blue.withOpacity(0.1)
                              : isActive
                                  ? Colors.purple.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isNew
                              ? "New"
                              : isActive
                                  ? "Active"
                                  : "Done",
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 11,
                            color: isNew
                                ? Colors.blue
                                : isActive
                                    ? Colors.purple
                                    : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.dateTime,
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 13,
                            color: AppColors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          job.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 13,
                            color: AppColors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 14,
                        color: AppColors.black.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        job.serviceName,
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 13,
                          color: AppColors.black.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "\$${job.price.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontSize: 15,
                          color: AppColors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.black.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          height: 48,
          width: 48,
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
        const SizedBox(height: 4),
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
