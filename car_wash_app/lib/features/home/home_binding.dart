import 'package:get/get.dart';
import 'controllers/home_controller.dart';

/// Home Screen Binding
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
