import 'package:get/get.dart';
import 'controllers/profile_controller.dart';

/// Profile Screen Binding
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}

