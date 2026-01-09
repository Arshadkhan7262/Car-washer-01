import 'package:get/get.dart';

/// Home Controller
class HomeController extends GetxController {
  // Observable variables
  final _isLoading = false.obs;
  final _data = <String, dynamic>{}.obs;
  
  // Getters
  bool get isLoading => _isLoading.value;
  Map<String, dynamic> get data => _data;
  
  @override
  void onInit() {
    super.onInit();
    _loadData();
  }
  
  /// Load initial data
  Future<void> _loadData() async {
    _isLoading.value = true;
    try {
      // TODO: Implement data loading logic
      await Future.delayed(const Duration(seconds: 1));
      _data.value = {
        'message': 'Welcome to Car Wash Pro',
      };
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Refresh data
  Future<void> refresh() async {
    await _loadData();
  }
}

