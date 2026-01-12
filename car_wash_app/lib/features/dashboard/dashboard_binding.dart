import 'package:get/get.dart';
import 'dashboard_controller.dart';
import '../home/home_binding.dart';
import '../jobs/jobs_binding.dart';
import '../wallet/wallet_binding.dart';
import '../profile/profile_binding.dart';

/// Dashboard Binding
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    // Initialize all feature bindings
    HomeBinding().dependencies();
    JobsBinding().dependencies();
    WalletBinding().dependencies();
    ProfileBinding().dependencies();
  }
}


