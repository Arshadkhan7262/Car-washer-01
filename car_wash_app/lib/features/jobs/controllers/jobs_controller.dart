import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/job_model.dart';
import '../services/jobs_service.dart';

class JobController extends GetxController {
  final JobsService _jobsService = JobsService();
  
  var selectedTab = JobStatus.newJob.obs;
  var allJobs = <JobModel>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
    
    // Start periodic refresh every 5 seconds to get new jobs instantly
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isLoading.value) {
        fetchJobs(silent: true); // Silent refresh - don't show loading
      }
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Fetch jobs from API
  Future<void> fetchJobs({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading.value = true;
      }
      error.value = '';
      
      final response = await _jobsService.getWasherJobs();
      
      if (response == null) {
        if (!silent) {
          error.value = 'Failed to fetch jobs';
          isLoading.value = false;
        }
        return;
      }

      final jobsList = response['jobs'] as List<dynamic>? ?? [];
      
      // Check if new jobs were added (for notification)
      final previousJobsCount = allJobs.length;
      final previousNewJobsCount = newJobsCount;
      
      allJobs.value = jobsList.map((job) => _mapToJobModel(job)).toList();
      
      // If new job was assigned, show notification
      if (!silent && allJobs.length > previousJobsCount) {
        final newJobs = allJobs.length - previousJobsCount;
        if (newJobs > 0) {
          Get.snackbar(
            'New Job Assigned',
            'You have $newJobs new job${newJobs > 1 ? 's' : ''}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      }
      
      // If new job count increased, switch to new jobs tab
      if (!silent && newJobsCount > previousNewJobsCount && previousNewJobsCount == 0) {
        // Don't auto-switch if user is viewing active/done jobs
        // Only switch if they're already on new jobs tab or no jobs were showing
      }
      
      if (!silent) {
        isLoading.value = false;
      }
    } catch (e) {
      if (!silent) {
        error.value = 'Error: ${e.toString()}';
        isLoading.value = false;
      }
      print('Error fetching jobs: $e');
    }
  }

  /// Map backend job data to JobModel
  JobModel _mapToJobModel(Map<String, dynamic> job) {
    // Map backend status to UI status
    JobStatus status;
    final backendStatus = job['status'] as String? ?? 'pending';
    
    if (backendStatus == 'pending') {
      status = JobStatus.newJob;
    } else if (backendStatus == 'completed') {
      status = JobStatus.done;
    } else {
      // accepted, on_the_way, arrived, in_progress -> active
      status = JobStatus.active;
    }

    // Format date and time
    String dateTime = '';
    if (job['booking_date'] != null && job['time_slot'] != null) {
      try {
        final date = DateTime.parse(job['booking_date']);
        final formattedDate = DateFormat('MMM d, yyyy').format(date);
        dateTime = '$formattedDate • ${job['time_slot']}';
      } catch (e) {
        dateTime = '${job['booking_date']} • ${job['time_slot']}';
      }
    }

    // Get customer name
    String customerName = 'Unknown';
    if (job['customer_id'] != null) {
      if (job['customer_id'] is Map) {
        customerName = job['customer_id']['name'] ?? 'Unknown';
      } else {
        customerName = job['customer_name'] ?? 'Unknown';
      }
    }

    // Get service name
    String serviceName = 'Service';
    if (job['service_id'] != null && job['service_id'] is Map) {
      serviceName = job['service_id']['name'] ?? 'Service';
    } else {
      serviceName = job['service_name'] ?? 'Service';
    }

    return JobModel(
      id: job['_id']?.toString() ?? job['id']?.toString() ?? '',
      customerName: customerName,
      vehicleType: job['vehicle_type']?.toString().toUpperCase() ?? 'Unknown',
      vehicleModel: job['vehicle_model']?.toString() ?? 'N/A',
      serviceName: serviceName,
      dateTime: dateTime,
      address: job['address']?.toString() ?? 'Address not provided',
      price: (job['total'] ?? job['base_price'] ?? 0.0).toDouble(),
      status: status,
    );
  }

  void changeTab(JobStatus status) => selectedTab.value = status;

  // Filtered list based on tab
  List<JobModel> get filteredJobs =>
      allJobs.where((job) => job.status == selectedTab.value).toList();

  int get newJobsCount =>
      allJobs.where((j) => j.status == JobStatus.newJob).length;
}
