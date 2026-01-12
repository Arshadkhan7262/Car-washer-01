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

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
  }

  /// Fetch jobs from API
  Future<void> fetchJobs() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final response = await _jobsService.getWasherJobs();
      
      if (response == null) {
        error.value = 'Failed to fetch jobs';
        isLoading.value = false;
        return;
      }

      final jobsList = response['jobs'] as List<dynamic>? ?? [];
      
      allJobs.value = jobsList.map((job) => _mapToJobModel(job)).toList();
      
      isLoading.value = false;
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      isLoading.value = false;
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
