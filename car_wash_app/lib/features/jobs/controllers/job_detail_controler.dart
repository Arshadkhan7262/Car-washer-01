import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/job_detail_model.dart';
import '../services/jobs_service.dart';

class JobDetailController extends GetxController {
  final String jobId;
  final JobsService _jobsService = JobsService();
  
  var jobDetail = JobDetailModel(
    bookingId: "",
    schedule: "",
    customerName: "",
    customerPhone: "",
    vehicleType: "",
    vehicleModel: "",
    vehicleColor: "",
    packageName: "",
    totalPrice: 0.0,
    paymentMethod: "",
    address: "",
    currentStep: JobStep.assigned,
  ).obs;
  
  var isLoading = false.obs;
  var error = ''.obs;

  JobDetailController({required this.jobId});

  @override
  void onInit() {
    super.onInit();
    fetchJobDetails();
    // Set up periodic refresh for real-time updates (every 5 seconds)
    _startPeriodicRefresh();
  }

  Timer? _refreshTimer;

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isLoading.value) {
        fetchJobDetails();
      }
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Fetch job details from API
  Future<void> fetchJobDetails() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final jobData = await _jobsService.getJobById(jobId);
      
      if (jobData == null) {
        error.value = 'Failed to fetch job details';
        isLoading.value = false;
        return;
      }

      jobDetail.value = _mapToJobDetailModel(jobData);
      isLoading.value = false;
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      isLoading.value = false;
      print('Error fetching job details: $e');
    }
  }

  /// Map backend job data to JobDetailModel
  JobDetailModel _mapToJobDetailModel(Map<String, dynamic> job) {
    // Map backend status to JobStep
    JobStep currentStep = JobStep.assigned;
    final backendStatus = job['status'] as String? ?? 'pending';
    
    switch (backendStatus) {
      case 'pending':
        // When admin assigns washer, status is 'pending' - show as assigned
        currentStep = JobStep.assigned;
        break;
      case 'accepted':
        // When washer accepts, they're getting ready to go
        currentStep = JobStep.assigned;
        break;
      case 'on_the_way':
        currentStep = JobStep.onTheWay;
        break;
      case 'arrived':
        currentStep = JobStep.arrived;
        break;
      case 'in_progress':
        currentStep = JobStep.washing;
        break;
      case 'completed':
        currentStep = JobStep.completed;
        break;
      default:
        currentStep = JobStep.assigned;
    }

    // Format schedule
    String schedule = '';
    if (job['booking_date'] != null && job['time_slot'] != null) {
      try {
        final date = DateTime.parse(job['booking_date']);
        final formattedDate = DateFormat('MMM d').format(date);
        schedule = '$formattedDate-${job['time_slot']}';
      } catch (e) {
        schedule = '${job['booking_date']}-${job['time_slot']}';
      }
    }

    // Get customer info
    String customerName = 'Unknown';
    String customerPhone = 'N/A';
    if (job['customer_id'] != null && job['customer_id'] is Map) {
      customerName = job['customer_id']['name'] ?? 'Unknown';
      customerPhone = job['customer_id']['phone'] ?? 'N/A';
    } else {
      customerName = job['customer_name'] ?? 'Unknown';
      customerPhone = job['customer_phone'] ?? 'N/A';
    }

    // Get service name
    String serviceName = 'Service';
    if (job['service_id'] != null && job['service_id'] is Map) {
      serviceName = job['service_id']['name'] ?? 'Service';
    } else {
      serviceName = job['service_name'] ?? 'Service';
    }

    // Get vehicle info
    String vehicleType = job['vehicle_type']?.toString().toUpperCase() ?? 'Unknown';
    String vehicleModel = job['vehicle_model']?.toString() ?? 'N/A';
    String vehicleColor = job['vehicle_color']?.toString() ?? 'N/A';

    // Get payment method
    String paymentMethod = job['payment_method']?.toString().toUpperCase() ?? 'CASH';

    return JobDetailModel(
      bookingId: job['booking_id']?.toString() ?? job['_id']?.toString() ?? '',
      schedule: schedule,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicleType: vehicleType,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      packageName: serviceName,
      totalPrice: (job['total'] ?? job['base_price'] ?? 0.0).toDouble(),
      paymentMethod: paymentMethod,
      address: job['address']?.toString() ?? 'Address not provided',
      currentStep: currentStep,
    );
  }

  /// Update job status step
  Future<void> updateStep(JobStep nextStep) async {
    try {
      // Don't set isLoading to true - keep UI responsive
      String status;
      String statusMessage;
      
      switch (nextStep) {
        case JobStep.onTheWay:
          status = 'on_the_way';
          statusMessage = 'Journey started!';
          break;
        case JobStep.arrived:
          status = 'arrived';
          statusMessage = 'Arrived at location!';
          break;
        case JobStep.washing:
          status = 'in_progress';
          statusMessage = 'Washing started!';
          break;
        case JobStep.completed:
          status = 'completed';
          statusMessage = 'Job completed!';
          break;
        default:
          status = 'accepted';
          statusMessage = 'Status updated!';
      }

      // Update optimistically - update local state first for instant feedback
      final currentJobDetail = jobDetail.value;
      jobDetail.value = JobDetailModel(
        bookingId: currentJobDetail.bookingId,
        schedule: currentJobDetail.schedule,
        customerName: currentJobDetail.customerName,
        customerPhone: currentJobDetail.customerPhone,
        vehicleType: currentJobDetail.vehicleType,
        vehicleModel: currentJobDetail.vehicleModel,
        vehicleColor: currentJobDetail.vehicleColor,
        packageName: currentJobDetail.packageName,
        totalPrice: currentJobDetail.totalPrice,
        paymentMethod: currentJobDetail.paymentMethod,
        address: currentJobDetail.address,
        currentStep: nextStep,
      );

      // Show success message immediately
      Get.snackbar(
        'Done!',
        statusMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );

      // Update in background - don't block UI
      final success = await _jobsService.updateJobStatus(jobId, status);
      
      if (success) {
        // Refresh job details silently in background to sync with backend
        fetchJobDetails();
      } else {
        // Revert optimistic update on failure
        await fetchJobDetails();
        Get.snackbar(
          'Error',
          'Failed to update status. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      await fetchJobDetails();
      Get.snackbar(
        'Error',
        'Error updating status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Complete job
  Future<void> completeJob({String? note}) async {
    try {
      // Update optimistically - update local state first for instant feedback
      final currentJobDetail = jobDetail.value;
      jobDetail.value = JobDetailModel(
        bookingId: currentJobDetail.bookingId,
        schedule: currentJobDetail.schedule,
        customerName: currentJobDetail.customerName,
        customerPhone: currentJobDetail.customerPhone,
        vehicleType: currentJobDetail.vehicleType,
        vehicleModel: currentJobDetail.vehicleModel,
        vehicleColor: currentJobDetail.vehicleColor,
        packageName: currentJobDetail.packageName,
        totalPrice: currentJobDetail.totalPrice,
        paymentMethod: currentJobDetail.paymentMethod,
        address: currentJobDetail.address,
        currentStep: JobStep.completed,
      );

      // Show success message immediately
      Get.snackbar(
        'Job Completed!',
        'Great work! The job has been completed successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );

      // Update in background - don't block UI
      final success = await _jobsService.completeJob(jobId, note: note);
      
      if (success) {
        // Refresh job details silently in background to sync with backend
        fetchJobDetails();
      } else {
        // Revert optimistic update on failure
        await fetchJobDetails();
        Get.snackbar(
          'Error',
          'Failed to complete job. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      await fetchJobDetails();
      Get.snackbar(
        'Error',
        'Error completing job: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
