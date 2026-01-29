import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/book_controller.dart';
import '../models/address_model.dart';
import '../models/add_vehicle_model.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../widgets/service_card_widget.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_pay_dialog.dart';
import '../widgets/apple_pay_dialog.dart';
import '../controllers/profile_controller.dart';
import '../services/stripe_payment_service.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late final BookController controller;

  @override
  void initState() {
    super.initState();
    // Use Get.find if controller exists, otherwise create new one
    if (Get.isRegistered<BookController>()) {
      controller = Get.find<BookController>();
      // Reset PageController if it has existing clients to prevent multiple attachments
      // This will create a new PageController with the current currentPage.value (which should be set from draft)
      if (controller.hasPageControllerClients) {
        controller.resetPageController();
      }
      // Ensure PageController is created with the correct initial page
      // Accessing pageController getter will create it with currentPage.value
      // The getter uses currentPage.value as initialPage, so it should be correct
      
      // After first frame, ensure we're on the correct page (in case draft was loaded)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.pageController.hasClients) {
          final targetPage = controller.currentPage.value;
          try {
            final currentPageIndex = controller.pageController.page?.round() ?? 0;
            if (currentPageIndex != targetPage) {
              controller.pageController.jumpToPage(targetPage);
            }
          } catch (e) {
            // If we can't read current page, just jump to target
            controller.pageController.jumpToPage(targetPage);
          }
        }
      });
    } else {
      controller = Get.put(BookController(), permanent: false);
    }
  }

  @override
  void dispose() {
    // Reset PageController when screen is disposed
    controller.resetPageController();
    super.dispose();
  }

  // Stepper Widget for App Bar
  Widget _buildStepper(BookController controller) {
    const Color primaryColor = Color(0xFF2E70F0);

    return Obx(() => Container(
      height: 4.0,
      margin: const EdgeInsets.only(bottom: 8.0, left: 20, right: 20),
      child: Row(
        children: List.generate(
          4,
              (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 5.0 : 0),
              color: index <= controller.currentPage.value ? primaryColor : Color(0xffD9D9D9),
            ),
          ),
        ),
      ),
    ));
  }

  // --- STAGE 1: SERVICE SELECTION (Updated to use API) ---
  Widget _buildServiceSelectionStage(BookController controller, BuildContext context) {
    const Color primaryColor = Color(0xFF42A5F5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the type of wash you need',
            style: GoogleFonts.inter(color: Theme.of(context).brightness == Brightness.dark
                ? DarkTheme.textSecondary
                : LightTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          // Display services from API
          Obx(() {
            if (controller.isLoadingServices.value) {
              return const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.servicesError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Failed to load services',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary
                              : LightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => controller.fetchServices(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (controller.services.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No services available',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkTheme.textPrimary
                          : LightTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }

            // Display all services from API in a list
            final allServices = controller.services.toList();
            
            return Column(
              children: allServices.map((service) {
                return Obx(() {
                  final bool isSelected = controller.selectedService.value?.id == service.id;
                  return GestureDetector(
                    onTap: () {
                      controller.selectedService.value = service;
                      // Use post-frame callback to ensure PageView is built
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        controller.navigateToNextPage(context);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: primaryColor, width: 2)
                            : Border.all(
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.25),
                                width: 1,
                              ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: ServiceCardWidget(service: service, showBorder: false),
                      ),
                    ),
                  );
                });
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionStage(BookController controller, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Vehicle Type',
            style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.isLoadingVehicleTypes.value) {
              return const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.vehicleTypesError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Failed to load vehicle types',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary
                              : LightTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => controller.fetchVehicleTypes(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (controller.vehicleTypes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No vehicle types available',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkTheme.textPrimary
                          : LightTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: controller.vehicleTypes.map((vehicleType) {
                final isSelected = controller.selectedVehicleType.value?.id == vehicleType.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        controller.selectedVehicleType.value = vehicleType;
                        controller.selectedVehicle.value = vehicleType.toVehicle();
                        // Don't auto-navigate, let user click Next button
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: vehicleType.imageUrl != null
                                ? Image.network(
                                    vehicleType.imageUrl!,
                                    height: 30,
                                    width: 30,
                                    color: Theme.of(Get.context!).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported,
                                        size: 30,
                                        color: Theme.of(Get.context!).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      );
                                    },
                                  )
                                : (vehicleType.iconPath?.isNotEmpty ?? false)
                                    ? Image.asset(
                                        vehicleType.iconPath!,
                                        height: 30,
                                        width: 30,
                                        color: Theme.of(Get.context!).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.image_not_supported,
                                            size: 30,
                                            color: Theme.of(Get.context!).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        size: 30,
                                        color: Theme.of(Get.context!).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vehicleType.displayName,
                            style: GoogleFonts.inter(
                              color: Theme.of(Get.context!).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 20),
          // Continue Button
          Obx(() => Center(
            child: SizedBox(
              width: MediaQuery.of(Get.context!).size.width*0.5,
              child: ElevatedButton(
                onPressed: controller.isStage2Complete ? () => controller.navigateToNextPage(Get.context!) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Next',
                    style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // --- STAGE 3: DATE & TIME SELECTION ---
  Widget _buildDateTimeSelectionStage(BookController controller) {
    // Initialize date and time immediately when Stage 3 builds (if not already set)
    // This ensures the "Next" button is enabled as soon as address fields are filled
    if (controller.selectedDate.value == null) {
      final now = DateTime.now();
      controller.selectedDate.value = DateTime(now.year, now.month, now.day);
    }
    if (controller.selectedTime.value.isEmpty) {
      controller.selectedTime.value = '10:00 AM';
    }

    final List<String> availableTimes = [
      '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
      '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM', '06:00 PM',
    ];

    Widget _buildDateTile(BookController controller, DateTime date, BuildContext context) {
      return Obx(() {
        final selectedDate = controller.selectedDate.value;
        final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        // Compare dates properly by normalizing to start of day
        final bool isSelected = selectedDate != null &&
            selectedDate.year == date.year &&
            selectedDate.month == date.month &&
            selectedDate.day == date.day;
        return GestureDetector(
          onTap: () {
            // Set date normalized to start of day
            controller.selectedDate.value = DateTime(date.year, date.month, date.day);
          },
        child: Container(
          width: 70,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDarkTheme
                ? DarkTheme.card
                : LightTheme.card),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkTheme 
                  ? Colors.white.withValues(alpha: 0.25) 
                  : Colors.black.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  color: isSelected 
                      ? (isDarkTheme ? Colors.black : Colors.white)
                      : null,
                ),
              ),
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? (isDarkTheme ? Colors.black : Colors.white)
                      : null,
                ),
              ),
              Text(
                ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1],
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  color: isSelected 
                      ? (isDarkTheme ? Colors.black : Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
      });
    }

    Widget _buildTimeButton(BookController controller, String time) {
      return Obx(() {
        final bool isSelected = time == controller.selectedTime.value;
        final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () {
            controller.selectedTime.value = time;
          },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(Get.context!).colorScheme.primary
                : (isDarkTheme
            ? DarkTheme.card
            : LightTheme.card),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkTheme 
                  ? Colors.white.withValues(alpha: 0.25) 
                  : Colors.black.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            time,
            textAlign: TextAlign.center,
            style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
              color: isSelected 
                  ? (isDarkTheme ? Colors.black : Colors.white)
                  : null,
            ),
          ),
        ),
      );
      });
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Date', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        // Always use current date as base, not selectedDate
                        final now = DateTime.now();
                        final baseNormalized = DateTime(now.year, now.month, now.day);
                        final date = baseNormalized.add(Duration(days: index));
                        return _buildDateTile(controller, date, context);
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                   Text('Select Time', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: availableTimes.length,
                    itemBuilder: (context, index) {
                      return _buildTimeButton(controller, availableTimes[index]);
                    },
                  ),
                  const SizedBox(height: 30),
                  Text('Select Time', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary:LightTheme.textPrimary , fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Saved Addresses Dropdown
                  Obx(() {
                    print('🔄 [BookScreen] Addresses dropdown rebuild - Count: ${controller.savedAddresses.length}, Loading: ${controller.isLoadingAddresses.value}');
                    if (controller.isLoadingAddresses.value) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    
                    if (controller.savedAddresses.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Address', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary:LightTheme.textPrimary , fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.card : LightTheme.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(Get.context!).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Address>(
                                value: controller.selectedSavedAddress.value,
                                hint: Text('Select saved address', style: GoogleFonts.inter(
                                  color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.textTertiary : LightTheme.textTertiary,
                                )),
                                isExpanded: true,
                                items: controller.savedAddresses.map((address) {
                                  return DropdownMenuItem<Address>(
                                    value: address,
                                    child: Text(
                                      '${address.label}: ${address.fullAddress}',
                                      style: GoogleFonts.inter(
                                        color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Address? address) {
                                  controller.selectedSavedAddress.value = address;
                                  if (address != null) {
                                    controller.addressController.text = address.fullAddress;
                                    controller.addressText.value = address.fullAddress; // Update reactive variable
                                  } else {
                                    controller.addressText.value = ''; // Clear reactive variable
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Show selected saved address indicator
                          Obx(() {
                            if (controller.selectedSavedAddress.value != null) {
                              final selectedAddress = controller.selectedSavedAddress.value!;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Using saved address: ${selectedAddress.label}',
                                            style: GoogleFonts.inter(
                                              color: Colors.green.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            selectedAddress.fullAddress,
                                            style: GoogleFonts.inter(
                                              color: Theme.of(Get.context!).brightness == Brightness.dark
                                                  ? DarkTheme.textSecondary
                                                  : LightTheme.textSecondary,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          Text('OR Enter Address Manually', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textSecondary:LightTheme.textSecondary , fontSize: 12)),
                          const SizedBox(height: 10),
                        ],
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Address', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary:LightTheme.textPrimary , fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: controller.addressController,
                          hintText: 'Enter your Address',
                        ),
                      ],
                    );
                  }),
                  
                  const SizedBox(height: 20),
                  Text('Select Vehicle Type', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary:LightTheme.textPrimary , fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Saved Vehicles Dropdown
                  Obx(() {
                    print('🔄 [BookScreen] Vehicles dropdown rebuild - Count: ${controller.savedVehicles.length}, Loading: ${controller.isLoadingVehicles.value}');
                    if (controller.isLoadingVehicles.value) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    
                    if (controller.savedVehicles.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Vehicle', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary:LightTheme.textPrimary , fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.card : LightTheme.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(Get.context!).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AddVehicleModel>(
                                value: controller.selectedSavedVehicle.value,
                                hint: Text('Select saved vehicle', style: GoogleFonts.inter(
                                  color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.textTertiary : LightTheme.textTertiary,
                                )),
                                isExpanded: true,
                                items: controller.savedVehicles.map((vehicle) {
                                  return DropdownMenuItem<AddVehicleModel>(
                                    value: vehicle,
                                    child: Text(
                                      '${vehicle.nameAndDetails} - ${vehicle.detailsLine}',
                                      style: GoogleFonts.inter(
                                        color: Theme.of(Get.context!).brightness == Brightness.dark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (AddVehicleModel? vehicle) {
                                  controller.selectedSavedVehicle.value = vehicle;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }
                    
                    return const SizedBox.shrink();
                  }),
                  
                  CustomTextField(
                    controller: controller.additionalLocationController,
                    hintText: 'Get code , parking spot etc',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Continue Button - Observe all reactive values for validation
          Obx(() {
            // Access all reactive values to ensure proper tracking
            final hasDate = controller.selectedDate.value != null;
            final hasTime = controller.selectedTime.value.isNotEmpty;
            final hasSavedAddress = controller.selectedSavedAddress.value != null;
            // Use reactive variable for manual address text
            final hasManualAddress = controller.addressText.value.trim().isNotEmpty;
            final hasAddress = hasSavedAddress || hasManualAddress;
            final hasVehicleType = controller.selectedVehicleType.value != null;
            final hasSavedVehicle = controller.selectedSavedVehicle.value != null;
            final hasVehicle = hasVehicleType || hasSavedVehicle;
            // Use reactive variable for additional location text
            final hasAdditionalLocation = controller.additionalLocationText.value.trim().isNotEmpty;
            
            final isComplete = hasDate && hasTime && hasAddress && hasVehicle && hasAdditionalLocation;
            
            return Center(
              child: SizedBox(
                width: MediaQuery.of(Get.context!).size.width*0.5,
                child: ElevatedButton(
                  onPressed: isComplete ? () => controller.navigateToNextPage(Get.context!) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Next',
                      style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Build payment method details based on selection
  Widget _buildPaymentMethodDetails(BookController controller, BuildContext context) {
    final selectedMethod = controller.selectedPaymentMethod.value;
    
    if (selectedMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    switch (selectedMethod) {
      case 'Credit Card':
        return _buildCreditCardDetails(controller, context);
      case 'Google Pay':
        return _buildGooglePayDetails(controller, context);
      case 'Wallet':
        return _buildWalletDetails(controller, context);
      case 'Cash':
        return _buildCashDetails(controller, context);
      default:
        return const SizedBox.shrink();
    }
  }

  // Credit Card Details - Payment Sheet will handle card entry
  Widget _buildCreditCardDetails(BookController controller, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? DarkTheme.card : LightTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: isDark ? DarkTheme.primary : LightTheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Credit Card',
                style: GoogleFonts.inter(
                  color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You will be prompted to enter your card details securely when you click the Pay button. A secure payment form will appear.',
            style: GoogleFonts.inter(
              color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  color: isDark ? DarkTheme.primary : LightTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your card details are secure and encrypted by Stripe',
                    style: GoogleFonts.inter(
                      color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Google Pay Details
  Widget _buildGooglePayDetails(BookController controller, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? DarkTheme.card : LightTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Google Pay',
                style: GoogleFonts.inter(
                  color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You will be redirected to Google Pay for authentication when you proceed with payment.',
            style: GoogleFonts.inter(
              color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Wallet Details
  Widget _buildWalletDetails(BookController controller, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileController = Get.find<ProfileController>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? DarkTheme.card : LightTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wallet, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Wallet Balance',
                style: GoogleFonts.inter(
                  color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final balance = profileController.walletBalance.value;
            final amount = controller.finalTotal;
            final remaining = balance - amount;
            final hasSufficientBalance = balance >= amount;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Balance',
                      style: GoogleFonts.inter(
                        color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Amount to Pay',
                      style: GoogleFonts.inter(
                        color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining Balance',
                      style: GoogleFonts.inter(
                        color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${remaining.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: hasSufficientBalance ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!hasSufficientBalance) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Insufficient balance. Please add funds or use another payment method.',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  // Cash Details
  Widget _buildCashDetails(BookController controller, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? DarkTheme.card : LightTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.money, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                'Cash Payment',
                style: GoogleFonts.inter(
                  color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You will pay \$${controller.finalTotal.toStringAsFixed(2)} in cash when the service is completed.',
            style: GoogleFonts.inter(
              color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Handle payment processing and booking confirmation
  Future<void> _handlePaymentAndBooking(BookController controller, BuildContext context) async {
    final selectedMethod = controller.selectedPaymentMethod.value;
    final paymentService = StripePaymentService();
    final amount = controller.finalTotal;
    
    print('🔄 [BookScreen] Starting payment - Method: $selectedMethod, Amount: $amount');
    
    try {
      // Process payment based on method
      Map<String, dynamic>? paymentResult;
      
      if (selectedMethod == 'Credit Card') {
        // Don't show loading dialog - Payment Sheet will handle its own UI
        print('🔄 [BookScreen] Starting credit card payment with Payment Sheet');
        
        try {
          // Use Stripe Payment Sheet for credit card payment
          // This will show a bottom sheet with card entry fields
          paymentResult = await paymentService.presentPaymentSheet(
            amount: amount,
            currency: 'USD',
            preferredPaymentMethod: 'Credit Card',
          );
          
          print('✅ [BookScreen] Payment Sheet completed successfully');
        } catch (paymentError) {
          // Check if user cancelled
          final errorString = paymentError.toString().toLowerCase();
          if (errorString.contains('cancelled') || errorString.contains('canceled')) {
            print('ℹ️ [BookScreen] User cancelled payment');
            return; // User cancelled, don't show error
          }
          // Re-throw other errors to be caught by outer catch block
          rethrow;
        }
        
      } else if (selectedMethod == 'Google Pay') {
        // Show custom Google Pay dialog with button
        print('🔄 [BookScreen] Starting Google Pay payment');
        
        paymentResult = await _showGooglePayDialog(context, amount, paymentService);
        print('🔄 [BookScreen] Google Pay result: $paymentResult');
        
        if (paymentResult == null) {
          print('⚠️ [BookScreen] Google Pay was cancelled or failed');
          return; // User cancelled or payment failed
        }
        
        print('✅ [BookScreen] Google Pay payment completed');
        
      } else if (selectedMethod == 'Apple Pay') {
        // Show custom Apple Pay dialog with button
        print('🔄 [BookScreen] Starting Apple Pay payment');
        
        paymentResult = await _showApplePayDialog(context, amount, paymentService);
        print('🔄 [BookScreen] Apple Pay result: $paymentResult');
        
        if (paymentResult == null) {
          print('⚠️ [BookScreen] Apple Pay was cancelled or failed');
          return; // User cancelled or payment failed
        }
        
        print('✅ [BookScreen] Apple Pay payment completed');
        
      } else if (selectedMethod == 'Wallet') {
        // Show loading
        Get.dialog(
          Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        
        // Check wallet balance
        final profileController = Get.find<ProfileController>();
        final balance = profileController.walletBalance.value;
        
        if (balance < amount) {
          Get.back(); // Close loading
          Get.snackbar(
            'Insufficient Balance',
            'Your wallet balance is \$${balance.toStringAsFixed(2)}. Please add funds or use another payment method.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
        
        // Wallet payment is processed server-side during booking
        // No need to process payment here, just proceed to booking
        paymentResult = {'success': true, 'status': 'succeeded', 'method': 'wallet'};
        Get.back(); // Close loading
        
      } else if (selectedMethod == 'Cash') {
        // Cash payment - no processing needed
        paymentResult = {'success': true, 'status': 'pending', 'method': 'cash'};
      }
      
      // If payment succeeded (or cash/wallet), proceed with booking
      if (paymentResult != null && (paymentResult['success'] == true || selectedMethod == 'Cash')) {
        print('✅ [BookScreen] Payment successful, proceeding with booking');
        print('🔄 [BookScreen] Payment result details: $paymentResult');
        await controller.confirmBooking(context);
      } else {
        print('❌ [BookScreen] Payment result check failed');
        print('   paymentResult: $paymentResult');
        print('   paymentResult != null: ${paymentResult != null}');
        if (paymentResult != null) {
          print('   paymentResult[success]: ${paymentResult['success']}');
          print('   selectedMethod: $selectedMethod');
        }
        throw Exception('Payment processing failed');
      }
      
    } catch (e) {
      // Close loading if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Show detailed error for debugging
      print('❌ [BookScreen] Payment error: $errorMessage');
      print('❌ [BookScreen] Error type: ${e.runtimeType}');
      
      Get.snackbar(
        'Payment Failed',
        errorMessage.contains('cancelled') || errorMessage.contains('canceled')
            ? 'Payment cancelled by user'
            : errorMessage.isEmpty 
                ? 'An unknown error occurred. Please check console logs.'
                : errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // --- STAGE 4: PAYMENT SELECTION (NEW) ---
  Widget _buildPaymentStage(BookController controller) {

    List<Map<String, dynamic>> paymentMethods = [
      {'name': 'Credit Card', 'details': '**** 4242', 'imagePath': 'assets/images/card.png', 'balance': null},
      {'name': 'Wallet', 'details': 'Balance: \$50.00', 'imagePath': 'assets/images/wallet.png', 'balance': '50.00'},
      {'name': 'Cash', 'details': 'Pay on completion', 'imagePath': 'assets/images/cash.png', 'balance': null},
      {'name': 'Apple Pay', 'details': 'Fast & secure', 'imagePath': 'assets/images/apple.png', 'balance': null},
      {'name': 'Google Pay', 'details': 'Fast & secure', 'imagePath': 'assets/images/googlepay.png', 'balance': null},
    ];

    Widget _buildPaymentCard(BookController controller, Map<String, dynamic> method) {
      return Obx(() {
        final bool isSelected = controller.selectedPaymentMethod.value == method['name'];
        final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () {
            final methodName = method['name'] as String;
            controller.selectedPaymentMethod.value = methodName;
            
            // Just select the payment method - payment will be processed when user clicks Pay
            // No navigation needed - payment details are shown inline
          },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkTheme ? DarkTheme.paymentCardSelected.withValues(alpha: 0.13) : LightTheme.paymentCardSelected.withValues(alpha: 0.13))
                : (isDarkTheme ? DarkTheme.paymentCardUnselected : LightTheme.paymentCardUnselected),
            borderRadius: BorderRadius.circular(12),
            border: isSelected 
                ? Border.all(color: isDarkTheme ? DarkTheme.paymentCardSelected : LightTheme.paymentCardSelected, width: 2) 
                : Border.all(
                    color: isDarkTheme
                        ? DarkTheme.primary.withValues(alpha: 0.13)
                        : LightTheme.primary.withValues(alpha: 0.13),
                    width: 1,
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: MediaQuery.of(Get.context!).textScaleFactor * 40,
                height: MediaQuery.of(Get.context!).textScaleFactor * 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(Get.context!).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                  // border: Border.all(
                  //   color: Theme.of(Get.context!).brightness == Brightness.dark
                  //       ? Colors.white.withOpacity(0.25)
                  //       : Colors.black.withOpacity(0.25),
                  //   width: 1,
                  // ),
                ),
                child: Center(
                  child: Image.asset(
                    method['imagePath'] as String,
                    width: MediaQuery.of(Get.context!).textScaleFactor * 20,
                    height: MediaQuery.of(Get.context!).textScaleFactor * 20,
                    color: Theme.of(Get.context!).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to a placeholder icon if image fails to load
                      return Icon(
                        Icons.image_not_supported,
                        size: MediaQuery.of(Get.context!).textScaleFactor * 20,
                        color: Theme.of(Get.context!).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'] as String,
                      style:  GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      method['details'] as String,
                      style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textTertiary: LightTheme.textTertiary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: isDarkTheme ? DarkTheme.paymentCardSelected : LightTheme.paymentCardSelected, size: 24),
            ],
          ),
        ),
      );
      });
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary , fontSize: 20, fontWeight: FontWeight.bold)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Order Summary Section (payment1.jpeg)
                  Container(
                    padding:  EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.card: LightTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(Get.context!).brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.25) 
                            : Colors.black.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Obx(() {
                      // Get selected service details reactively
                      final selectedService = controller.selectedService.value;
                      final String serviceTitle = selectedService?.name ?? "Service";
                      final double subtotal = controller.subtotal;
                      final double discount = controller.discountAmount.value;
                      final double finalTotal = controller.finalTotal;
                      final bool hasDiscount = discount > 0;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Summary', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w400)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(serviceTitle, style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary.withValues(alpha: 0.48): LightTheme.textPrimary.withValues(alpha: 0.48), fontSize: 14,fontWeight: FontWeight.w400)),
                              Text("\$${subtotal.toStringAsFixed(2)}", style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary.withValues(alpha: 0.48): LightTheme.textPrimary.withValues(alpha: 0.48), fontSize: 14,fontWeight: FontWeight.w400)),
                            ],
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount', style: GoogleFonts.inter(color: Colors.green.shade600, fontSize: 14, fontWeight: FontWeight.w400)),
                                Text("-\$${discount.toStringAsFixed(2)}", style: GoogleFonts.inter(color: Colors.green.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                          const Divider(color: Colors.white30, height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w400)),
                              Text("\$${finalTotal.toStringAsFixed(2)}", style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 30),
                  // Apply Coupon Section (payment1.jpeg)
                  Text('Apply Coupon', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Obx(() {
                    final hasCoupon = controller.appliedCouponCode.value != null && controller.appliedCouponCode.value!.isNotEmpty;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: controller.couponController,
                                hintText: hasCoupon ? controller.appliedCouponCode.value! : 'Enter coupon code',
                                prefixIcon: Icons.discount_outlined,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (hasCoupon)
                              ElevatedButton(
                                onPressed: () => controller.removeCoupon(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text('Remove', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
                              )
                            else
                              ElevatedButton(
                                onPressed: controller.isValidatingCoupon.value ? null : () => controller.applyCoupon(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.card: LightTheme.card,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Theme.of(Get.context!).brightness == Brightness.dark 
                                          ? Colors.white.withValues(alpha: 0.25) 
                                          : Colors.black.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: controller.isValidatingCoupon.value
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Theme.of(Get.context!).brightness == Brightness.dark
                                                ? DarkTheme.textPrimary
                                                : LightTheme.textPrimary,
                                          ),
                                        ),
                                      )
                                    : Text('Apply', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w400)),
                              ),
                          ],
                        ),
                        if (controller.couponError.value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              controller.couponError.value,
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (hasCoupon)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Coupon "${controller.appliedCouponCode.value ?? 'N/A'}" applied! You saved \$${controller.discountAmount.value.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        color: Colors.green.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }),

                  const SizedBox(height: 30),
                  // Payment Method Section (payment1.jpeg and payment2.jpeg)
                   Text('Payment Method', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...paymentMethods.map((method) => _buildPaymentCard(controller, method)).toList(),
                  
                  // Show payment method details inline
                  const SizedBox(height: 20),
                  Obx(() => _buildPaymentMethodDetails(controller, context)),
                ],
              ),
            ),
          ),

          // Pay Button (payment2.jpeg)
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(Get.context!).size.width*0.5,
                  child: ElevatedButton(
                    onPressed: controller.isStage4Complete 
                        ? () => _handlePaymentAndBooking(controller, context) 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.primary: LightTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Pay \$${controller.finalTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Removed unused method - payments are now processed inline using Payment Sheet

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,),
          onPressed: () {
            if (controller.currentPage.value > 0) {
              controller.navigateToPreviousPage();
            } else {
              Navigator.pop(context); // Exit the screen
            }
          },
        ),
        title: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Book a Service', style: GoogleFonts.inter(color:  Theme.of(context).brightness == Brightness.dark
                 ? DarkTheme.textPrimary
                 : LightTheme.textPrimary, fontSize: 20,fontWeight: FontWeight.w600)),
            Text('Step ${controller.currentPage.value + 1} of 4', style: GoogleFonts.inter(color:  Theme.of(context).brightness == Brightness.dark
                ? DarkTheme.textTertiary
                : LightTheme.textTertiary, fontSize: 12)),
          ],
        )),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12.0),
          child: _buildStepper(controller),
        ),
      ),
      body: PageView(
        key: ValueKey('booking_pageview_${controller.pageControllerKey}'), // Unique key to prevent multiple attachments
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
        onPageChanged: (index) {
          controller.currentPage.value = index;
        },
        children: <Widget>[
          _buildServiceSelectionStage(controller, context), // Stage 1
          _buildVehicleSelectionStage(controller, context),  // Stage 2
          _buildDateTimeSelectionStage(controller), // Stage 3
          _buildPaymentStage(controller),          // Stage 4 (New)
        ],
      ),
    );
  }

  /// Show Google Pay dialog with custom button
  Future<Map<String, dynamic>?> _showGooglePayDialog(
    BuildContext context,
    double amount,
    StripePaymentService paymentService,
  ) async {
    final completer = Completer<Map<String, dynamic>?>();
    bool paymentInitiated = false;
    
    Get.dialog(
      GooglePayDialog(
        amount: amount,
        currency: 'USD',
        isLoading: false,
        onPayPressed: () async {
          paymentInitiated = true;
          Get.back(); // Close dialog
          
          // Show loading
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );
          
          try {
            final result = await paymentService.processGooglePay(
              amount: amount,
              currency: 'USD',
            );
            Get.back(); // Close loading
            
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (e) {
            Get.back(); // Close loading
            Get.snackbar(
              'Payment Failed',
              e.toString().replaceAll('Exception: ', ''),
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
      ),
      barrierDismissible: true,
    ).then((_) {
      // If dialog is dismissed without payment being initiated, complete with null
      if (!paymentInitiated && !completer.isCompleted) {
        completer.complete(null);
      }
    });
    
    return completer.future;
  }

  /// Show Apple Pay dialog with custom button
  Future<Map<String, dynamic>?> _showApplePayDialog(
    BuildContext context,
    double amount,
    StripePaymentService paymentService,
  ) async {
    final completer = Completer<Map<String, dynamic>?>();
    bool paymentInitiated = false;
    
    Get.dialog(
      ApplePayDialog(
        amount: amount,
        currency: 'USD',
        isLoading: false,
        onPayPressed: () async {
          paymentInitiated = true;
          Get.back(); // Close dialog
          
          // Show loading
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );
          
          try {
            final result = await paymentService.processApplePay(
              amount: amount,
              currency: 'USD',
            );
            Get.back(); // Close loading
            
            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (e) {
            Get.back(); // Close loading
            Get.snackbar(
              'Payment Failed',
              e.toString().replaceAll('Exception: ', ''),
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          }
        },
      ),
      barrierDismissible: true,
    ).then((_) {
      // If dialog is dismissed without payment being initiated, complete with null
      if (!paymentInitiated && !completer.isCompleted) {
        completer.complete(null);
      }
    });
    
    return completer.future;
  }
}