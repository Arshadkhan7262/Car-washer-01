import 'package:car_wash_app/features/jobs/controllers/jobs_controller.dart';
import 'package:get/get.dart';

/// Jobs Screen Binding
class JobsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobController>(() => JobController());
  }
}
