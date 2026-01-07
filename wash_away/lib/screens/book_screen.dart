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
      if (controller.hasPageControllerClients) {
        controller.resetPageController();
      }
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

            // Display services from API
            return Column(
              children: controller.services.map((service) {
                return Obx(() {
                  final bool isSelected = controller.selectedService.value?.id == service.id;
                  return GestureDetector(
                    onTap: () {
                      controller.selectedService.value = service;
                      // Navigate immediately - controller handles PageView readiness
                      controller.navigateToNextPage(Get.context!);
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

  // --- STAGE 3: DATE & TIME SELECTION (Unchanged) ---
  Widget _buildDateTimeSelectionStage(BookController controller) {
    // Initialize defaults when this stage is first shown (only if not already set)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.selectedDate.value == null) {
        final now = DateTime.now();
        controller.selectedDate.value = DateTime(now.year, now.month, now.day);
      }
      if (controller.selectedTime.value.isEmpty) {
        controller.selectedTime.value = '10:00 AM';
      }
    });

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
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
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
          // Continue Button
          Obx(() => Center(
            child: SizedBox(
              width: MediaQuery.of(Get.context!).size.width*0.5,
              child: ElevatedButton(
                onPressed: controller.isStage3Complete ? () => controller.navigateToNextPage(Get.context!) : null,
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

  // --- STAGE 4: PAYMENT SELECTION (NEW) ---
  Widget _buildPaymentStage(BookController controller) {
    // Get selected service details
    final selectedService = controller.selectedService.value;
    final String serviceTitle = selectedService?.name ?? "Service";
    final String servicePrice = selectedService != null 
        ? "\$${selectedService.basePrice.toStringAsFixed(2)}"
        : "\$0.00";
    final String totalAmount = servicePrice;

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
            controller.selectedPaymentMethod.value = method['name'] as String;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('Order Summary', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w400)),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(serviceTitle, style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary.withValues(alpha: 0.48): LightTheme.textPrimary.withValues(alpha: 0.48), fontSize: 14,fontWeight: FontWeight.w400)),
                            Text(servicePrice, style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary.withValues(alpha: 0.48): LightTheme.textPrimary.withValues(alpha: 0.48), fontSize: 14,fontWeight: FontWeight.w400)),
                          ],
                        ),
                        const Divider(color: Colors.white30, height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text('Total', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w400)),
                            Text(totalAmount, style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  // Apply Coupon Section (payment1.jpeg)
                   Text('Apply Coupon', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: TextEditingController(), // Coupon controller - add to BookController if needed
                          hintText: 'Enter coupon code',
                          prefixIcon: Icons.discount_outlined,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {},
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
                        child:  Text('Apply', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w400)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  // Payment Method Section (payment1.jpeg and payment2.jpeg)
                   Text('Payment Method', style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ...paymentMethods.map((method) => _buildPaymentCard(controller, method)).toList(),
                ],
              ),
            ),
          ),

          // Pay Button (payment2.jpeg)
          Obx(() => Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(Get.context!).size.width*0.5,
                child: ElevatedButton(
                  onPressed: controller.isStage4Complete ? () => controller.navigateToNextPage(Get.context!) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.primary: LightTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Pay $totalAmount',
                      style: GoogleFonts.inter(color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }


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
}