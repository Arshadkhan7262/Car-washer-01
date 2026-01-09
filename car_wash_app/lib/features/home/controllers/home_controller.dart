import 'package:get/get.dart';
import '../../auth/services/auth_service.dart';
import '../services/home_service.dart';

class HomeController extends GetxController {
  final HomeService _homeService = HomeService();
  final AuthService _authService = AuthService();
  
  // Reactive states
  var isOnline = false.obs;
  var rating = 5.0.obs;
  var jobsCount = 0.obs; // Today's jobs
  var earnings = 0.00.obs; // Today's earnings
  var designedCount = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Load dashboard stats from API
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      
      // Check if account is pending or suspended - don't call API
      final cachedStatus = await _authService.getCachedAccountStatus();
      if (cachedStatus == 'pending' || cachedStatus == 'suspended') {
        // Set default values for pending/suspended accounts
        jobsCount.value = 0;
        earnings.value = 0.0;
        rating.value = 0.0;
        isOnline.value = false;
        isLoading.value = false;
        return;
      }
      
      final stats = await _homeService.getDashboardStats();
      
      if (stats != null) {
        // Update today's stats
        final today = stats['today'];
        if (today != null) {
          jobsCount.value = today['jobs'] ?? 0;
          earnings.value = (today['earnings'] ?? 0).toDouble();
        }
        
        // Update total stats
        final total = stats['total'];
        if (total != null) {
          rating.value = (total['rating'] ?? 0).toDouble();
        }
        
        // Update online status
        isOnline.value = stats['online_status'] ?? false;
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle online status
  Future<void> toggleStatus() async {
    // TODO: Call API to update online status
    // For now, just update locally
    isOnline.value = !isOnline.value;
  }
  
  /// Refresh dashboard data
  Future<void> refreshData() async {
    await loadDashboardData();
  }
}
