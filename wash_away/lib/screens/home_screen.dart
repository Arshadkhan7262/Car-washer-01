import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wash_away/screens/book_screen.dart';
import 'package:wash_away/screens/notification_screen.dart';
import 'package:wash_away/widgets/service_card_widget.dart';
import '../controllers/home_controller.dart';
import '../controllers/book_controller.dart';
import '../controllers/profile_controller.dart';
import '../features/notifications/controllers/notification_controller.dart';
import '../models/banner_model.dart' as banner_model;
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    const double appBarHeight = 130; // adjust height as needed

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(appBarHeight),
          child: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            // backgroundColor: primaryBackgroundColor,
            toolbarHeight: 120,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness== Brightness.dark? DarkTheme.card:LightTheme.card ,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.withValues(alpha: 0.8)
                          : Colors.black.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.9),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() {
                                final profileController = Get.isRegistered<ProfileController>()
                                    ? Get.find<ProfileController>()
                                    : Get.put(ProfileController());
                                final userName = profileController.userName.value.isNotEmpty
                                    ? profileController.userName.value
                                    : 'User';
                                return Text(
                                  userName,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationScreen(),
                              ),
                            );
                          },
                          child: Obx(() {
                            final notificationController = Get.isRegistered<NotificationController>()
                                ? Get.find<NotificationController>()
                                : Get.put(NotificationController());
                            final unreadCount = notificationController.unreadCount.value;
                            
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? DarkTheme.card
                                              : LightTheme.card,
                                          width: 2,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: 6,),
                    Obx(() => GestureDetector(
                      onTap: () {
                        // Allow user to refresh location by tapping
                        controller.fetchCurrentLocation();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            controller.isLoadingLocation.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7551D3)),
                                    ),
                                  )
                                : const Icon(Icons.location_on_outlined, color: Color(0xFF7551D3), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                controller.currentLocation.value,
                                style: GoogleFonts.inter(
                                  color: Color(0xFF7551D3),
                                  fontWeight: FontWeight.w300,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xff4E76E1), size: 12),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
      
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
      
       Padding(
        padding: EdgeInsets.only(left: 10),
         child: Text(
                        'Select Vehicle Type',
                        style: Theme.of(context).textTheme.headlineMedium
                      ),
       ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                    
                //      Text(
                //       'Select Vehicle Type',
                //       style: Theme.of(context).textTheme.headlineMedium
                //     ),
                //   ],
                // ),
                SizedBox(height: 15,),
                // Vehicle Type Buttons (Horizontal Scrollable)
                Obx(() {
                  if (controller.isLoadingVehicleTypes.value) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
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
                              style: Theme.of(context).textTheme.bodyMedium,
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
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: controller.vehicleTypes.take(4).toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final vehicleType = entry.value;
                          return Obx(() => GestureDetector(
                            onTap: () {
                              // Navigate to booking screen - start at step 1 (service selection)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookScreen(),
                                ),
                              ).then((_) {
                                // After returning from booking, refresh if needed
                                controller.fetchVehicleTypes();
                              });
                              // Set selected vehicle type in BookController after navigation
                              // Start at step 1 (page 0) so user can select service first
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                try {
                                  final bookController = Get.find<BookController>();
                                  bookController.selectedVehicleType.value = vehicleType;
                                  bookController.selectedVehicle.value = vehicleType.toVehicle();
                                  bookController.currentPage.value = 0; // Start at step 1 (service selection)
                                  // PageController will be initialized when BookScreen builds
                                } catch (e) {
                                  // Controller not found yet, will be set when screen loads
                                }
                              });
                            },
                            child: _buildVehicleTypeButton(
                              controller,
                              index,
                              vehicleType.imageUrl ?? vehicleType.iconPath ?? 'assets/images/car6.png',
                              vehicleType.displayName,
                              isNetworkImage: vehicleType.imageUrl != null,
                            ),
                          ));
                        }).toList(),
                      ),
                    ],
                  );
                }),
      
                // const SizedBox(height: 15),

                const SizedBox(height: 15),
      
                // --- Banner Carousel (from API or static fallback) ---
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: SizedBox(
                    height: 200,
                    child: Obx(() {
                      if (controller.isLoadingBanners.value) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                      final items = controller.banners.isEmpty
                          ? [_buildImageListItem(context, 'assets/images/gift.png')]
                          : controller.banners
                              .map((b) => _buildBannerItem(context, b))
                              .toList();
                      return PageView(
                        controller: controller.pageController,
                        children: items,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
      
                // Dots Indicator
                Obx(() {
                  final count = controller.banners.isEmpty
                      ? 1
                      : controller.banners.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(count, (index) {
                      return _buildDotIndicator(controller, index, count);
                    }),
                  );
                }),
                SizedBox(height: 8,),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 3,
                  children: [
                    Text(
                      'Our Services',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> BookScreen()));
                      },
                      child:  Text(
                        'See All >',
                        style: GoogleFonts.inter(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                // --- Service Cards (Image 1 and 2) ---
                SizedBox(height: 12,),

                // Display services from API
                Obx(() {
                  if (controller.isLoadingServices.value) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
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
                              style: Theme.of(context).textTheme.bodyMedium,
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  // Display first 3 services (or all if less than 3)
                  return Column(
                    children: controller.services.take(3).map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            // Navigate to booking screen with service pre-selected
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookScreen(),
                              ),
                            ).then((_) {
                              // After returning from booking, refresh services if needed
                              controller.fetchServices();
                            });
                            // Set selected service in BookController after navigation
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              try {
                                final bookController = Get.find<BookController>();
                                bookController.selectedService.value = service;
                                bookController.currentPage.value = 0;
                                if (bookController.pageController.hasClients) {
                                  bookController.pageController.jumpToPage(0);
                                }
                              } catch (e) {
                                // Controller not found yet, will be set when screen loads
                              }
                            });
                          },
                          child: ServiceCardWidget(service: service),
                        ),
                      );
                    }).toList(),
                  );
                }),
      
                // --- Premium Quality Banner (Image 2) ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001C34),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.yellow, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Premium Quality',
                            style: GoogleFonts.inter(
                              color: Color(0xffFFA24B),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                       Text(
                        'Get Your Car Sparkling Clean',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Professional car wash at your doorstep',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffffffff), // Purple
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child:  Text(
                          'Book Now',
                          style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
      
      
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeButton(
      HomeController controller,
      int index,
      String imagePath,
      String label, {
      bool isNetworkImage = false,
      }) {

    final bool isSelected = controller.selectedVehicleIndex.value == index;

    final Color selectedColor = controller.vehicleColors[index];

    return GestureDetector(
      onTap: () {
        controller.selectVehicle(index);
      },
      child: Column(
        children: [
          // Icon/Button Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // color: isSelected ? selectedColor :  Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: isNetworkImage
                ? Image.network(
                    imagePath,
                    width: 30,
                    height: 30,
                    color: Theme.of(Get.context!).brightness == Brightness.dark? Colors.white:Colors.black,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Theme.of(Get.context!).brightness == Brightness.dark? Colors.white:Colors.black,
                      );
                    },
                  )
                : Image.asset(
                    imagePath,
                    color: Theme.of(Get.context!).brightness == Brightness.dark? Colors.white:Colors.black,
                    width: 30,
                    height: 30,
                  ),
          ),
          const SizedBox(height: 2),
          // Label Text
          Text(
            label,
            style: GoogleFonts.inter(
              // color: isSelected ? selectedColor : Colors.grey.shade400,
              color: Theme.of(Get.context!).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required String price,
    required Color iconColor,
    bool isPopular = false,
    required BuildContext context,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical:1 ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                imagePath,
                width: MediaQuery.of(context).size.width * 0.1,
                height: MediaQuery.of(context).size.height * 0.08,
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isPopular) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEFBD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Popular',
                      style: GoogleFonts.inter(
                        color: Color(0xffBB732F),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // SizedBox(height: 10,),

              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).textTheme.titleMedium!.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 90 min (Time)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '90',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'min',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Full exterior wash
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                          : LightTheme.textPrimary.withValues(alpha: 0.25),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'exterior',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'wash',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Interior vacuum
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                          : LightTheme.textPrimary.withValues(alpha: 0.25),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Interior',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'vacuum',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DarkTheme.textPrimary.withValues(alpha: 0.25)
                              : LightTheme.textPrimary.withValues(alpha: 0.25),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }

  /// Banner card from API (title, subtitle, image_url, action_value as badge)
  Widget _buildBannerItem(BuildContext context, banner_model.Banner banner) {
    return GestureDetector(
      onTap: () {
        if (banner.actionType == 'service' && banner.actionValue.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => BookScreen()));
        } else if (banner.actionType == 'url' && banner.actionValue.isNotEmpty) {
          // Could open URL with url_launcher
        }
      },
      child: Container(
        width: 320,
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF2E70F0),
              Color(0xFF3391F3),
              Color(0xFF38B7F7),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: banner.imageUrl.isNotEmpty
                    ? Image.network(
                        banner.imageUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/gift.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Center(
                        child: Image.asset(
                          'assets/images/gift.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      banner.subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (banner.actionValue.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.actionValue,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the horizontal image list (Image 3 content) - static fallback
  Widget _buildImageListItem(BuildContext context, String imagePath) {
    return Container(
      width: 320,
      height: 100, // Reduced height for a sleeker look
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Refined padding
      margin: const EdgeInsets.only(right: 8), // Slightly reduced margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20), // Slightly tighter radius for smaller height
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF2E70F0),
            Color(0xFF3391F3),
            Color(0xFF38B7F7),
          ],
        ),
      ),
      child: Row(
        children: [
          // --- Leading Icon Container ---
          Container(
            width: 44, // Reduced from 50
            height: 44, // Reduced from 50
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Image.asset(
                imagePath,
                width: 24, // Reduced image size
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // --- Text Content ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ensures column only takes needed space
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'First Wash Free',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18, // Slightly smaller to fit new height
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get your first wash on us!',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13, // Slightly smaller
                  ),
                ),
                const SizedBox(height: 8),

                // --- Promo Badge ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Thinner padding
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '% FIRST 50',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
  // Widget _buildImageListItem(String assetPath) {
  //   return Container(
  //     width: 150,
  //
  //     margin: const EdgeInsets.only(right: 15),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(15),
  //       color: Theme.of(Get.context!).brightness == Brightness.dark? DarkTheme.card : LightTheme.card,
  //       image: DecorationImage(
  //         image: AssetImage(assetPath), // Replace with your actual assets
  //         fit: BoxFit.cover,
  //       ),
  //     ),
  //   );
  // }

  // Helper widget for the custom dotted indicator
  Widget _buildDotIndicator(HomeController controller, int index, int totalPages, {Color? selectedColor}) {
    // If no selectedColor is provided, use the PageView's current state
    final bool isSelected = selectedColor != null ? index == 0 : index == controller.currentPage.value;

    // Theme-based colors for dot indicator
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    final Color color = isSelected
        ? (isDarkTheme ? Colors.white : Colors.black)
        : (isDarkTheme ? const Color(0xFF666666) : const Color(0xFFD9D9D9));

    // The "Select Vehicle Type" dots are different from the Onboarding dots
    final double size = selectedColor != null ? 6.0 : 8.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}