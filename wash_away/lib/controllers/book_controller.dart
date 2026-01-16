import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/service_model.dart' hide Vehicle;
import '../models/vehicle_type_model.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import '../models/draft_booking_model.dart';
import '../models/address_model.dart';
import '../models/add_vehicle_model.dart';
import '../screens/booking_confirm_screen.dart';
import '../features/services/services/service_service.dart';
import '../features/vehicles/services/vehicle_type_service.dart';
// DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
// import '../features/bookings/services/draft_booking_service.dart';
import '../features/bookings/services/booking_service.dart';
import '../features/bookings/services/coupon_service.dart';
import '../features/addresses/services/address_service.dart';
import '../features/vehicles/services/vehicle_service.dart';

class BookController extends GetxController {
  // Static flag to indicate resuming before controller creation
  static bool _willResume = false;
  static void setWillResume(bool value) => _willResume = value;
  
  PageController? _pageController;
  int _pageControllerKey = 0; // Key to force PageView recreation
  
  PageController get pageController {
    // Only create if it doesn't exist
    // Don't dispose here as it might be in use
    _pageController ??= PageController(initialPage: currentPage.value);
    return _pageController!;
  }
  
  // Get key for PageView to force recreation when needed
  int get pageControllerKey => _pageControllerKey;
  
  /// Check if PageController has clients attached
  bool get hasPageControllerClients {
    return _pageController != null && _pageController!.hasClients;
  }
  
  /// Dispose and recreate PageController (call this when screen needs reset)
  void resetPageController() {
    if (_pageController != null) {
      try {
        if (_pageController!.hasClients) {
          _pageController!.dispose();
        }
      } catch (e) {
        // Ignore errors during disposal
      }
      _pageController = null;
      _pageControllerKey++;
    }
  }
  
  final RxInt currentPage = 0.obs;

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

  // Booking services
  // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
  // final DraftBookingService _draftBookingService = DraftBookingService();
  final BookingService _bookingService = BookingService();
  final CouponService _couponService = CouponService();
  final AddressService _addressService = AddressService();
  final VehicleService _vehicleService = VehicleService();
  
  // Saved addresses and vehicles
  final RxList<Address> savedAddresses = <Address>[].obs;
  final RxList<AddVehicleModel> savedVehicles = <AddVehicleModel>[].obs;
  final RxBool isLoadingAddresses = false.obs;
  final RxBool isLoadingVehicles = false.obs;

  // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
  // Draft booking state
  // final Rx<DraftBooking?> currentDraft = Rx<DraftBooking?>(null);
  // final RxBool isLoadingDraft = false.obs;
  final RxBool isCreatingBooking = false.obs;
  bool _draftLoaded = false; // Flag to prevent loading draft multiple times
  bool _isResuming = false; // Flag to indicate we're resuming (prevents onInit interference)
  
  // Setter for resuming flag (used by resume flow)
  set isResuming(bool value) => _isResuming = value;

  // Selected Data
  final Rx<Service?> selectedService = Rx<Service?>(null);
  final Rx<VehicleType?> selectedVehicleType = Rx<VehicleType?>(null);
  
  // Backward compatibility - convert VehicleType to Vehicle
  List<Vehicle> get vehicles {
    final List<Color> colors = [
      Colors.blue,
      const Color(0xFF67B547),
      Colors.orange,
      Colors.grey,
    ];
    return vehicleTypes.asMap().entries.map((entry) {
      final index = entry.key;
      final vehicleType = entry.value;
      return vehicleType.toVehicle(
        color: index < colors.length ? colors[index] : Colors.blue,
      );
    }).toList();
  }
  
  final Rx<Vehicle?> selectedVehicle = Rx<Vehicle?>(null);
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final RxString selectedTime = ''.obs;
  final TextEditingController addressController = TextEditingController();
  final TextEditingController additionalLocationController = TextEditingController();
  final TextEditingController couponController = TextEditingController();
  final RxString selectedPaymentMethod = 'Credit Card'.obs;
  
  // Selected saved address and vehicle
  final Rx<Address?> selectedSavedAddress = Rx<Address?>(null);
  final Rx<AddVehicleModel?> selectedSavedVehicle = Rx<AddVehicleModel?>(null);
  
  // Coupon state
  final Rx<String?> appliedCouponCode = Rx<String?>(null);
  final RxDouble discountAmount = 0.0.obs;
  final RxBool isValidatingCoupon = false.obs;
  final RxString couponError = ''.obs;

  // Validation
  bool get isStage2Complete => selectedVehicleType.value != null || selectedVehicle.value != null;
  bool get isStage3Complete =>
      selectedDate.value != null &&
      selectedTime.value.isNotEmpty &&
      addressController.text.trim().isNotEmpty &&
      additionalLocationController.text.trim().isNotEmpty; // Add validation for new controller
  bool get isStage4Complete => selectedPaymentMethod.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    // If we're resuming (static flag or instance flag), skip draft loading and defaults
    // But still initialize basic things like listeners
    bool isResuming = _willResume || _isResuming;
    if (isResuming) {
      _isResuming = true; // Set instance flag
      _willResume = false; // Clear static flag
      print('🔄 [BookController] Resuming booking - skipping draft load in onInit');
    }
    
    // Reset PageController if it exists and has clients (from previous instance)
    // This ensures we start fresh when controller is reused
    if (_pageController != null && _pageController!.hasClients) {
      resetPageController();
    }
    // Initialize PageController if needed
    _pageController ??= PageController(initialPage: currentPage.value);
    
    // Always initialize listeners (needed for UI updates)
    addressController.addListener(() {
      _updateState();
      // Clear saved address selection if user manually edits the address field
      // (but only if the text doesn't match the selected saved address)
      if (selectedSavedAddress.value != null) {
        final savedAddressText = selectedSavedAddress.value!.fullAddress;
        final currentText = addressController.text.trim();
        // If user manually edited and it's different from saved address, clear selection
        if (currentText.isNotEmpty && currentText != savedAddressText) {
          selectedSavedAddress.value = null;
        }
      }
    });
    additionalLocationController.addListener(_updateState);
    couponController.addListener(() {
      // Clear coupon error when user types
      if (couponError.value.isNotEmpty) {
        couponError.value = '';
      }
    });
    
    // Fetch services and vehicle types from API
    fetchServices();
    fetchVehicleTypes();
    
    // Load saved addresses and vehicles
    fetchSavedAddresses();
    fetchSavedVehicles();
    
    // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
    // Load draft booking if exists
    // loadDraftBooking();
  }

  /// Reset controller for new booking
  void resetForNewBooking() {
    currentPage.value = 0;
    selectedService.value = null;
    selectedVehicleType.value = null;
    selectedVehicle.value = null;
    selectedDate.value = DateTime.now();
    selectedTime.value = '10:00 AM';
    addressController.clear();
    additionalLocationController.clear();
    selectedPaymentMethod.value = 'Credit Card';
    
    // Reset PageController
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.jumpToPage(0);
    } else {
      _pageController?.dispose();
      _pageController = PageController(initialPage: 0);
    }
  }

  // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
  /// Load draft booking
  // Future<void> loadDraftBooking() async {
  //   try {
  //     isLoadingDraft.value = true;
  //     final draft = await _draftBookingService.getDraft();
  //     
  //     if (draft != null) {
  //       currentDraft.value = draft;
  //       // Restore booking state from draft
  //       if (draft.serviceId != null) {
  //         try {
  //           final service = services.firstWhere((s) => s.id == draft.serviceId, orElse: () => services.first);
  //           if (service.id == draft.serviceId) {
  //             selectedService.value = service;
  //           }
  //         } catch (e) {
  //           // Service not found, skip
  //         }
  //       }
  //       if (draft.vehicleTypeId != null) {
  //         try {
  //           final vehicleType = vehicleTypes.firstWhere((v) => v.id == draft.vehicleTypeId, orElse: () => vehicleTypes.first);
  //           if (vehicleType.id == draft.vehicleTypeId) {
  //             selectedVehicleType.value = vehicleType;
  //             selectedVehicle.value = vehicleType.toVehicle();
  //           }
  //         } catch (e) {
  //           // Vehicle type not found, skip
  //         }
  //       }
  //       if (draft.selectedDate != null) {
  //         selectedDate.value = draft.selectedDate;
  //       }
  //       if (draft.selectedTime != null) {
  //         selectedTime.value = draft.selectedTime!;
  //       }
  //       if (draft.address != null) {
  //         addressController.text = draft.address!;
  //       }
  //       if (draft.additionalLocation != null) {
  //         additionalLocationController.text = draft.additionalLocation!;
  //       }
  //       if (draft.paymentMethod != null) {
  //         selectedPaymentMethod.value = draft.paymentMethod!;
  //       }
  //       // Navigate to the step saved in draft
  //       if (draft.step > 0 && draft.step <= 4) {
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (_pageController != null && _pageController!.hasClients) {
  //             _pageController!.jumpToPage(draft.step - 1);
  //             currentPage.value = draft.step - 1;
  //           }
  //         });
  //       }
  //     }
  //     isLoadingDraft.value = false;
  //   } catch (e) {
  //     isLoadingDraft.value = false;
  //     // Silently fail - draft loading is optional
  //   }
  // }

  // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
  /// Map payment method from UI to API format
  // String? _mapPaymentMethod(String? uiPaymentMethod) {
  //   if (uiPaymentMethod == null || uiPaymentMethod.isEmpty) {
  //     return null;
  //   }
  //   
  //   switch (uiPaymentMethod) {
  //     case 'Credit Card':
  //       return 'card';
  //     case 'Wallet':
  //       return 'wallet';
  //     case 'Apple Pay':
  //       return 'apple_pay';
  //     case 'Google Pay':
  //       return 'google_pay';
  //     case 'Cash':
  //       return 'cash';
  //     default:
  //       return 'cash'; // Default to cash
  //   }
  // }

  // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
  /// Save draft booking
  // Future<void> saveDraft() async {
  //   try {
  //     // Map payment method to API format
  //     final mappedPaymentMethod = _mapPaymentMethod(
  //       selectedPaymentMethod.value.isNotEmpty ? selectedPaymentMethod.value : null
  //     );
  //     
  //     final draft = DraftBooking(
  //       step: currentPage.value + 1,
  //       serviceId: selectedService.value?.id,
  //       vehicleTypeId: selectedVehicleType.value?.id,
  //       vehicleTypeName: selectedVehicleType.value?.displayName,
  //       selectedDate: selectedDate.value,
  //       selectedTime: selectedTime.value.isNotEmpty ? selectedTime.value : null,
  //       address: addressController.text.trim().isNotEmpty ? addressController.text.trim() : null,
  //       additionalLocation: additionalLocationController.text.trim().isNotEmpty ? additionalLocationController.text.trim() : null,
  //       paymentMethod: mappedPaymentMethod,
  //     );
  //     
  //     await _draftBookingService.saveDraft(draft);
  //   } catch (e) {
  //     // Silently fail - draft saving is optional
  //     print('Failed to save draft: $e');
  //   }
  // }

  // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
  /// Clear draft booking
  // Future<void> clearDraft() async {
  //   try {
  //     await _draftBookingService.deleteDraft();
  //     currentDraft.value = null;
  //   } catch (e) {
  //     print('Failed to clear draft: $e');
  //   }
  // }

  /// Fetch services from API
  Future<void> fetchServices() async {
    try {
      isLoadingServices.value = true;
      servicesError.value = '';

      final fetchedServices = await _serviceService.getAllServices();
      services.value = fetchedServices;

      isLoadingServices.value = false;
    } catch (e) {
      isLoadingServices.value = false;
      servicesError.value = e.toString();
      Get.snackbar(
        'Error',
        'Failed to load services: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Fetch vehicle types from API
  Future<void> fetchVehicleTypes() async {
    try {
      isLoadingVehicleTypes.value = true;
      vehicleTypesError.value = '';

      final fetchedVehicleTypes = await _vehicleTypeService.getAllVehicleTypes();
      vehicleTypes.value = fetchedVehicleTypes;
      
      // Set default selected vehicle type if available
      if (vehicleTypes.isNotEmpty && selectedVehicleType.value == null) {
        selectedVehicleType.value = vehicleTypes.last;
        selectedVehicle.value = vehicleTypes.last.toVehicle();
      }

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

  /// Fetch saved addresses
  Future<void> fetchSavedAddresses() async {
    try {
      isLoadingAddresses.value = true;
      final addresses = await _addressService.getAddresses();
      savedAddresses.value = addresses;
      
      print('📍 [BookController] Fetched ${addresses.length} saved addresses');
      
      // Preserve existing selection if it's still in the list
      if (selectedSavedAddress.value != null && addresses.isNotEmpty) {
        try {
          final existingSelection = addresses.firstWhere(
            (a) => a.id == selectedSavedAddress.value!.id,
            orElse: () => addresses.first,
          );
          // Only update if the selection changed
          if (existingSelection.id != selectedSavedAddress.value!.id) {
            selectedSavedAddress.value = existingSelection;
            addressController.text = existingSelection.fullAddress;
            print('📍 [BookController] Updated address selection: ${existingSelection.fullAddress}');
          }
        } catch (e) {
          // Selection not found, will set default below
          selectedSavedAddress.value = null;
        }
      }
      
      // Set default address if no selection exists
      if (addresses.isNotEmpty && selectedSavedAddress.value == null) {
        try {
          final defaultAddress = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
          selectedSavedAddress.value = defaultAddress;
          addressController.text = defaultAddress.fullAddress;
          print('📍 [BookController] Set default address: ${defaultAddress.fullAddress}');
        } catch (e) {
          // If firstWhere fails, just use first
          selectedSavedAddress.value = addresses.first;
          addressController.text = addresses.first.fullAddress;
        }
      }
      
      isLoadingAddresses.value = false;
    } catch (e) {
      isLoadingAddresses.value = false;
      print('❌ [BookController] Error fetching addresses: $e');
      // Show error to user
      Get.snackbar(
        'Warning',
        'Could not load saved addresses. You can enter address manually.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Fetch saved vehicles
  Future<void> fetchSavedVehicles() async {
    try {
      isLoadingVehicles.value = true;
      final vehicles = await _vehicleService.getVehicles();
      savedVehicles.value = vehicles;
      
      print('🚗 [BookController] Fetched ${vehicles.length} saved vehicles');
      
      // Preserve existing selection if it's still in the list
      if (selectedSavedVehicle.value != null && vehicles.isNotEmpty) {
        try {
          final existingSelection = vehicles.firstWhere(
            (v) => v.id == selectedSavedVehicle.value!.id,
            orElse: () => vehicles.first,
          );
          // Only update if the selection changed
          if (existingSelection.id != selectedSavedVehicle.value!.id) {
            selectedSavedVehicle.value = existingSelection;
            print('🚗 [BookController] Updated vehicle selection: ${existingSelection.nameAndDetails}');
          }
        } catch (e) {
          // Selection not found, will set default below
          selectedSavedVehicle.value = null;
        }
      }
      
      // Set default vehicle if no selection exists
      if (vehicles.isNotEmpty && selectedSavedVehicle.value == null) {
        try {
          final defaultVehicle = vehicles.firstWhere((v) => v.isDefault, orElse: () => vehicles.first);
          selectedSavedVehicle.value = defaultVehicle;
          print('🚗 [BookController] Set default vehicle: ${defaultVehicle.nameAndDetails}');
        } catch (e) {
          // If firstWhere fails, just use first
          selectedSavedVehicle.value = vehicles.first;
        }
      }
      
      isLoadingVehicles.value = false;
    } catch (e) {
      isLoadingVehicles.value = false;
      print('❌ [BookController] Error fetching vehicles: $e');
      // Show error to user
      Get.snackbar(
        'Warning',
        'Could not load saved vehicles.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void onClose() {
    _pageController?.dispose();
    _pageController = null;
    addressController.dispose();
    additionalLocationController.dispose();
    couponController.dispose();
    super.onClose();
  }

  void _updateState() {
    update(); // Trigger rebuild for button enablement
  }

  /// Get subtotal (base price)
  double get subtotal {
    if (selectedService.value != null) {
      // Check if there's vehicle-specific pricing
      final vehicleType = selectedVehicleType.value?.name.toLowerCase();
      if (vehicleType != null && 
          selectedService.value!.pricing != null && 
          selectedService.value!.pricing!.containsKey(vehicleType)) {
        final vehiclePrice = selectedService.value!.pricing![vehicleType];
        if (vehiclePrice != null && vehiclePrice > 0) {
          return vehiclePrice;
        }
      }
      return selectedService.value!.basePrice;
    }
    return 0.0;
  }

  /// Get final total after discount
  double get finalTotal {
    return (subtotal - discountAmount.value).clamp(0.0, double.infinity);
  }

  /// Apply coupon code
  Future<void> applyCoupon() async {
    final code = couponController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      couponError.value = 'Please enter a coupon code';
      Get.snackbar(
        'Error',
        'Please enter a coupon code',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (selectedService.value == null) {
      couponError.value = 'Please select a service first';
      Get.snackbar(
        'Error',
        'Please select a service first',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      isValidatingCoupon.value = true;
      couponError.value = '';

      final orderValue = subtotal;
      final couponData = await _couponService.validateCoupon(
        code: code,
        orderValue: orderValue,
      );

      // Update coupon state
      appliedCouponCode.value = couponData['coupon']['code'] as String;
      discountAmount.value = (couponData['discount'] as num).toDouble();
      
      Get.snackbar(
        'Success',
        'Coupon applied! You saved \$${discountAmount.value.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      couponError.value = e.toString().replaceAll('Exception: ', '');
      appliedCouponCode.value = null;
      discountAmount.value = 0.0;
      
      Get.snackbar(
        'Error',
        couponError.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isValidatingCoupon.value = false;
    }
  }

  /// Remove applied coupon
  void removeCoupon() {
    appliedCouponCode.value = null;
    discountAmount.value = 0.0;
    couponController.clear();
    couponError.value = '';
    Get.snackbar(
      'Info',
      'Coupon removed',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void navigateToNextPage(BuildContext context) async {
    if (currentPage.value < 3) {
      // Navigate to next page first
      final nextPage = currentPage.value + 1;
      
      // Ensure PageController exists (create if needed)
      if (_pageController == null) {
        _pageController = PageController(initialPage: currentPage.value);
      }
      
      // Wait for PageController to be ready (with timeout)
      int retries = 0;
      while (!pageController.hasClients && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        retries++;
      }
      
      // Update current page for UI responsiveness
      currentPage.value = nextPage;
      
      // Navigate PageView using post-frame callback to ensure PageView is built
      if (pageController.hasClients) {
        try {
          await pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        } catch (e) {
          print('Error navigating to page: $e');
          // Fallback: try jumpToPage if animateToPage fails
          try {
            pageController.jumpToPage(nextPage);
          } catch (e2) {
            print('Error jumping to page: $e2');
          }
        }
      } else {
        // If PageController still not ready, use post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (pageController.hasClients) {
            try {
              pageController.jumpToPage(nextPage);
            } catch (e) {
              print('Error jumping to page after post-frame: $e');
            }
          } else {
            // Last resort: try again after a short delay
            Future.delayed(const Duration(milliseconds: 200), () {
              if (pageController.hasClients) {
                try {
                  pageController.jumpToPage(nextPage);
                } catch (e) {
                  print('Error jumping to page after delay: $e');
                }
              }
            });
          }
        });
      }
      
      // Initialize stage 3 defaults when navigating to it (only if not already set)
      if (nextPage == 2) { // Stage 3 is index 2
        if (selectedDate.value == null) {
          final now = DateTime.now();
          selectedDate.value = DateTime(now.year, now.month, now.day);
        }
        if (selectedTime.value.isEmpty) {
          selectedTime.value = '10:00 AM';
        }
        
        // Refresh saved addresses and vehicles when entering stage 3
        fetchSavedAddresses();
        fetchSavedVehicles();
      }
      
      // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
      // Save draft after navigation (non-blocking)
      // saveDraft().catchError((e) {
      //   // Silently handle draft save errors
      //   print('Draft save error: $e');
      // });
    } else {
      // Step 4 complete - confirm booking
      await confirmBooking(context);
    }
  }

  /// Confirm booking
  Future<void> confirmBooking(BuildContext context) async {
    try {
      if (selectedService.value == null || 
          selectedVehicleType.value == null ||
          selectedDate.value == null ||
          selectedTime.value.isEmpty ||
          addressController.text.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Please complete all booking details',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isCreatingBooking.value = true;

      // Map payment method
      String paymentMethod = 'cash';
      switch (selectedPaymentMethod.value) {
        case 'Credit Card':
          paymentMethod = 'card';
          break;
        case 'Wallet':
          paymentMethod = 'wallet';
          break;
        case 'Apple Pay':
          paymentMethod = 'apple_pay';
          break;
        case 'Google Pay':
          paymentMethod = 'google_pay';
          break;
        default:
          paymentMethod = 'cash';
      }

      // Use saved address/vehicle if selected, otherwise use manual input
      // IMPORTANT: When a saved address is selected, use its full address and coordinates
      // This ensures the washer receives the exact saved address with proper coordinates
      String bookingAddress = addressController.text.trim();
      double? addressLatitude;
      double? addressLongitude;
      String? addressId;
      String? vehicleId;
      
      if (selectedSavedAddress.value != null) {
        // Use the saved address data (full address + coordinates)
        // This is the specific address the customer selected, which will be sent to the washer
        bookingAddress = selectedSavedAddress.value!.fullAddress;
        addressLatitude = selectedSavedAddress.value!.latitude;
        addressLongitude = selectedSavedAddress.value!.longitude;
        addressId = selectedSavedAddress.value!.id;
        print('📍 [createBooking] Using saved address: ${selectedSavedAddress.value!.label} - $bookingAddress (lat: $addressLatitude, lng: $addressLongitude)');
      } else {
        print('📍 [createBooking] Using manually entered address: $bookingAddress');
      }
      
      if (selectedSavedVehicle.value != null) {
        vehicleId = selectedSavedVehicle.value!.id;
      }

      final bookingData = await _bookingService.createBooking(
        serviceId: selectedService.value!.id ?? '',
        vehicleTypeId: selectedVehicleType.value?.id,
        vehicleId: vehicleId,
        vehicleTypeName: selectedVehicleType.value!.displayName,
        bookingDate: selectedDate.value!,
        timeSlot: selectedTime.value,
        address: bookingAddress,
        addressLatitude: addressLatitude,
        addressLongitude: addressLongitude,
        addressId: addressId,
        additionalLocation: additionalLocationController.text.trim().isNotEmpty 
            ? additionalLocationController.text.trim() 
            : null,
        paymentMethod: paymentMethod,
        couponCode: appliedCouponCode.value?.isNotEmpty == true ? appliedCouponCode.value : null,
      );

      // DRAFT BOOKING FUNCTIONALITY COMMENTED OUT
      // Clear draft after successful booking
      // await clearDraft();

      isCreatingBooking.value = false;

      // Navigate to booking confirmation screen with booking data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(bookingData: bookingData),
        ),
      );
    } catch (e) {
      isCreatingBooking.value = false;
      Get.snackbar(
        'Error',
        'Failed to create booking: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToPreviousPage() {
    if (currentPage.value > 0) {
      final previousPage = currentPage.value - 1;
      
      // Update currentPage first for immediate UI responsiveness
      currentPage.value = previousPage;
      
      // Navigate PageView using jumpToPage for reliable navigation
      if (pageController.hasClients) {
        try {
          pageController.jumpToPage(previousPage);
        } catch (e) {
          print('Error navigating to previous page: $e');
          // Fallback: try animateToPage
          try {
            pageController.animateToPage(
              previousPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } catch (e2) {
            print('Error animating to previous page: $e2');
          }
        }
      } else {
        // If PageController not ready, use post-frame callback
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (pageController.hasClients) {
            try {
              pageController.jumpToPage(previousPage);
            } catch (e) {
              print('Error jumping to previous page after post-frame: $e');
            }
          }
        });
      }
      
      // Clear selections if moving back
      if (previousPage == 2) {
        // Stage 3 - ensure date and time are set
        if (selectedDate.value == null) {
          final now = DateTime.now();
          selectedDate.value = DateTime(now.year, now.month, now.day);
        }
        if (selectedTime.value.isEmpty) {
          selectedTime.value = '10:00 AM';
        }
      }
      if (previousPage == 3) {
        // Stage 4 - reset payment method to default
        selectedPaymentMethod.value = 'Credit Card';
      }
    }
  }
}

