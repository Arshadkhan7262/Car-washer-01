import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../features/services/services/service_service.dart';
import '../features/vehicles/services/vehicle_type_service.dart';
import '../models/service_model.dart';
import '../models/vehicle_type_model.dart';
import '../services/location_service.dart';
import '../features/notifications/controllers/fcm_token_controller.dart';

class HomeController extends GetxController {
  // State for Vehicle Type Selection
  final RxInt selectedVehicleIndex = 0.obs;
  
  // Custom colors for selected vehicle type buttons
  final List<Color> vehicleColors = [
    Colors.blue,
    const Color(0xFF67B547),
    Colors.orange,
    Colors.grey,
  ];
  
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  Timer? autoSlideTimer;
  VoidCallback? _pageControllerListener;

  // Services state
  final ServiceService _serviceService = ServiceService();
  final RxList<Service> services = <Service>[].obs;
  final RxBool isLoadingServices = false.obs;
  final RxString servicesError = ''.obs;

  // Vehicle types state
  final VehicleTypeService _vehicleTypeService = VehicleTypeService();
  final RxList<VehicleType> vehicleTypes = <VehicleType>[].obs;
  final RxBool isLoadingVehicleTypes = false.obs;
  final RxString vehicleTypesError = ''.obs;

  // Location state
  final LocationService _locationService = LocationService();
  final RxString currentLocation = 'Current Location'.obs;
  final RxBool isLoadingLocation = false.obs;

  /// Request notification permission after location permission is granted
  Future<void> _requestNotificationPermission() async {
    try {
      // Get or create FCM token controller
      FcmTokenController? fcmController;
      if (Get.isRegistered<FcmTokenController>()) {
        fcmController = Get.find<FcmTokenController>();
      } else {
        fcmController = Get.put(FcmTokenController());
      }
      
      // Now request notification permission and initialize FCM token
      if (fcmController != null) {
        await fcmController.initializeFcmToken();
        print('✅ [HomeController] Notification permission requested after location permission');
      }
    } catch (e) {
      print('❌ [HomeController] Error requesting notification permission: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Store listener reference for proper cleanup
    _pageControllerListener = () {
      currentPage.value = pageController.page?.round() ?? 0;
    };
    pageController.addListener(_pageControllerListener!);

    // Delay timer start until PageView is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start auto-slide timer only after PageView is attached
      autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        // Check if PageController is attached before animating
        if (pageController.hasClients) {
          final nextPage = (currentPage.value + 1) % 3;
          pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    });

    // Fetch services and vehicle types on init
    fetchServices();
    fetchVehicleTypes();
    
    // Fetch current location on init
    fetchCurrentLocation();
  }

  @override
  void onClose() {
    autoSlideTimer?.cancel();
    autoSlideTimer = null;
    // Remove listener before disposing
    if (_pageControllerListener != null) {
      pageController.removeListener(_pageControllerListener!);
      _pageControllerListener = null;
    }
    // Safely dispose PageController
    if (pageController.hasClients) {
      pageController.dispose();
    }
    super.onClose();
  }

  void selectVehicle(int index) {
    selectedVehicleIndex.value = index;
  }

  /// Fetch services from API
  Future<void> fetchServices({bool? isPopular}) async {
    try {
      isLoadingServices.value = true;
      servicesError.value = '';

      final fetchedServices = await _serviceService.getAllServices(isPopular: isPopular);
      services.value = fetchedServices;

      isLoadingServices.value = false;
    } catch (e) {
      isLoadingServices.value = false;
      servicesError.value = e.toString();
      // Don't show snackbar during initialization to avoid blocking UI
      print('❌ [HomeController] Failed to load services: $e');
      // Show snackbar only after app is initialized
      Future.delayed(const Duration(seconds: 2), () {
        if (Get.context != null) {
          Get.snackbar(
            'Error',
            'Failed to load services: ${e.toString()}',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      });
    }
  }

  /// Fetch vehicle types from API
  Future<void> fetchVehicleTypes() async {
    try {
      isLoadingVehicleTypes.value = true;
      vehicleTypesError.value = '';

      final fetchedVehicleTypes = await _vehicleTypeService.getAllVehicleTypes();
      vehicleTypes.value = fetchedVehicleTypes;

      isLoadingVehicleTypes.value = false;
    } catch (e) {
      isLoadingVehicleTypes.value = false;
      vehicleTypesError.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load vehicle types: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Fetch current location
  Future<void> fetchCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      print('📍 [Location] Starting location fetch...');
      
      // FIRST: Check if location services are enabled on the device
      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      print('📍 [Location] Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        // Location services are disabled
        currentLocation.value = 'Current Location';
        isLoadingLocation.value = false;
        print('📍 [Location] Location services disabled');
        Get.snackbar(
          'Location Disabled',
          'Turn on the device location',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
        );
        return;
      }
      
      // SECOND: Check permission
      LocationPermission permission = await _locationService.checkPermission();
      print('📍 [Location] Permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await _locationService.requestPermission();
        print('📍 [Location] Permission after request: $permission');
        
        if (permission == LocationPermission.denied) {
          currentLocation.value = 'Current Location';
          isLoadingLocation.value = false;
          print('📍 [Location] Permission denied, using default');
          Get.snackbar(
            'Permission Denied',
            'Location permission is required to show your current address.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        currentLocation.value = 'Current Location';
        isLoadingLocation.value = false;
        print('📍 [Location] Permission denied forever, using default');
        Get.snackbar(
          'Permission Required',
          'Location permission is permanently denied. Please enable it in settings.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Note: Notification permission is already requested during login/auth flow
      // No need to request again here - FCM token should already be registered
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        print('📍 [Location] Permission granted');
        // Just ensure FCM token is still registered (refresh if needed)
        if (Get.isRegistered<FcmTokenController>()) {
          final fcmController = Get.find<FcmTokenController>();
          if (fcmController.fcmToken.value.isEmpty) {
            // Token not registered yet, try to initialize
            await fcmController.initializeFcmToken();
          }
        }
      }

      // Get location place name (city/locality) - e.g., "Sant Pora"
      print('📍 [Location] Fetching place name...');
      String? placeName = await _locationService.getCurrentLocationPlaceName();
      print('📍 [Location] Place name received: $placeName');
      
      if (placeName != null && placeName.isNotEmpty) {
        print('📍 [Location] Updating location to: $placeName');
        currentLocation.value = placeName; // Will show "Sant Pora" or actual location
      } else {
        print('📍 [Location] No place name found, using default');
        currentLocation.value = 'Current Location';
      }
      
      isLoadingLocation.value = false;
      print('📍 [Location] Location fetch completed. Current value: ${currentLocation.value}');
    } catch (e) {
      print('❌ [Location] Error: $e');
      isLoadingLocation.value = false;
      currentLocation.value = 'Current Location';
      Get.snackbar(
        'Error',
        'Failed to get location: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

