import 'package:get/get.dart';
import 'controllers/auth_controller.dart';

/// Auth Binding
/// Initializes AuthController for dependency injection
/// Uses Get.put() to ensure controller is always available for Get.find()
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put() instead of Get.lazyPut() to ensure controller is always available
    // when screens use Get.find<AuthController>()
    Get.put(AuthController(), permanent: false);
  }
}

