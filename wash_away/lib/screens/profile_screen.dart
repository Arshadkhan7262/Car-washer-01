import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wash_away/screens/address_screen.dart';
import 'package:wash_away/screens/help_and_support.dart';
import 'package:wash_away/screens/my_vehicles_screen.dart';
import 'package:wash_away/screens/notification_screen.dart';
import 'package:wash_away/screens/payment_methods.dart';
import 'package:wash_away/screens/add_funds_screen.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  // --- Theme Colors and Constants ---
  static const Color primaryYellow = Color(0xFFFBC02D);       // Gold Member Star
  static const Color primaryBlue = Color(0xFF42A5F5);
  static const Color primaryRed = Color(0xFFE53935);// Avatar background

  // --- WIDGET BUILDERS ---

  // Custom Card for Stats (Total Washes, Total Spent, Wallet Balance)
  Widget _buildStatCard({
    required String value,
    required String label,
    Widget? subtitleWidget,
  }) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitleWidget != null) ...[
            const SizedBox(height: 6),
            subtitleWidget,
          ]
        ],
      ),
    );
  }

  // Custom List Tile for Settings
  Widget _buildSettingTile({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDarkTheme
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.grey.shade200, // Light grey like #E0E0E0
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 18,
            height: 18,
            color: isDarkTheme ? Colors.white : Colors.black,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.image_not_supported,
                size: 18,
                color: isDarkTheme ? Colors.white : Colors.black,
              );
            },
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Theme.of(Get.context!).brightness== Brightness.dark? DarkTheme.textPrimary: LightTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios, 
        size: 16,
        color: Theme.of(Get.context!).iconTheme.color,
      ),
      minLeadingWidth: 32, // Ensure icon is close to the title
    );
  }

  // Custom List Tile for Preferences (with switch)
  Widget _buildPreferenceTile({
    required String title,
    required String imagePath,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bool isDarkTheme = Theme.of(Get.context!).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          // color: isDarkTheme
          //     ? Colors.white.withOpacity(0.12)
          //     : Colors.grey.shade200, // Light grey like #E0E0E0
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 24,
            height: 24,
            color: Theme.of(Get.context!).brightness== Brightness.dark? Colors.white:Colors.grey,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.image_not_supported,
                size: 24,
                color: isDarkTheme ? Colors.white : Colors.black,
              );
            },
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Theme.of(Get.context!).brightness == Brightness.dark
              ? DarkTheme.textPrimary
              : LightTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      minLeadingWidth: 40,
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());
    final themeController = Get.find<ThemeController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Stack for User Info and Stats Card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dark Blue Background Section (Bottom Layer)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                    decoration: const BoxDecoration(
                      color: Color(0xff001C34),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar with Edit Button
                        Stack(
                          children: [
                            Obx(() => CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              child: Text(
                                controller.userInitial.value,
                                style: GoogleFonts.inter(
                                  color: const Color(0xff4E76E1),
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xff4E76E1),
                                    width: 2
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Color(0xff4E76E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        // Name and Email
                        Expanded(
                          child: Obx(() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.userName.value,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.userEmail.value,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Gold Member Tag
                              if (controller.isGoldMember.value)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xffFECF00).withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Color(0xffFECF00), size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Gold Member',
                                        style: TextStyle(
                                          color: Color(0xffFECF00),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ),
                  
                  // Stats Card (Top Layer with rounded top corners)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -60,
                    child: Obx(() {
                      final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDarkTheme ? DarkTheme.card : LightTheme.card,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildStatCard(
                              value: '${controller.totalWashes.value}',
                              label: 'Total Washes',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: isDarkTheme 
                                  ? Colors.white.withValues(alpha: 0.1) 
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                            _buildStatCard(
                              value: '\$${controller.totalSpent.value.toStringAsFixed(0)}',
                              label: 'Total Spent',
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: isDarkTheme 
                                  ? Colors.white.withValues(alpha: 0.1) 
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                            _buildStatCard(
                              value: '\$${controller.walletBalance.value.toStringAsFixed(0)}',
                              label: 'Wallet Balance',
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
              
              // Add spacing for the overlapping card
              const SizedBox(height: 80),
              
              // Content with padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
      
              // --- 3. Preferences/Settings Section ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? DarkTheme.card 
                      : LightTheme.card,
                  borderRadius: BorderRadius.circular(15),
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
                    _buildSettingTile(
                      title: 'My Vehicles',
                      imagePath: 'assets/images/car5.png', // Matches the image
                      onTap: () {
                        // Action for My Vehicles
                        debugPrint('My Vehicles tapped');
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> MyVehiclesScreen()));
                      },
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.1), 
                      height: 0, 
                      thickness: 1
                    ),
                    _buildSettingTile(
                      title: ' My Address',
                      imagePath: 'assets/images/locate2.png', // Matches the image
                      onTap: () {
                        // Action for My Vehicles
                        debugPrint('My Vehicles tapped');
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> AddressScreen()));
                      },
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.1), 
                      height: 0, 
                      thickness: 1
                    ),
                    // Payment Methods
                    _buildSettingTile(
                      title: 'Payment Methods',
                      imagePath: 'assets/images/pmethd.png', // Placeholder for the location pin in the image
                      onTap: () {
                        // Action for Payment Methods
                        debugPrint('Payment Methods tapped');
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> PaymentMethods()));
                      },
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.1), 
                      height: 0, 
                      thickness: 1
                    ),
                    // Add Funds to Wallet
                    _buildSettingTile(
                      title: 'Add Funds to Wallet',
                      imagePath: 'assets/images/wallet.png',
                      onTap: () async {
                        try {
                          // Navigate to Add Funds screen
                          debugPrint('Add Funds to Wallet tapped');
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddFundsScreen(),
                            ),
                          );
                          
                          // Refresh wallet balance if funds were added
                          if (result != null && result['success'] == true) {
                            await controller.fetchProfile();
                            Get.snackbar(
                              'Success',
                              'Funds added successfully',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          }
                        } catch (e, stackTrace) {
                          debugPrint('Error navigating to Add Funds: $e');
                          debugPrint('Stack trace: $stackTrace');
                          Get.snackbar(
                            'Error',
                            'Failed to open Add Funds screen: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.1), 
                      height: 0, 
                      thickness: 1
                    ),
      
                    // Notifications
                    _buildSettingTile(
                      title: 'Notifications',
                      imagePath: 'assets/images/notification.png', // Matches the bell in the image
                      onTap: () {
                        // Action for Notifications
                        debugPrint('Notifications tapped');
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> NotificationScreen()));
                      },
                    ),
                    Divider(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.black.withValues(alpha: 0.1), 
                      height: 0, 
                      thickness: 1
                    ),
      
                    // Help & Support
                    _buildSettingTile(
                      title: 'Help & Support',
                        imagePath: 'assets/images/question.png', // Matches the question mark in the image
                      onTap: () {
                        // Action for Help & Support
                        debugPrint('Help & Support tapped');
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> HelpAndSupport()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? DarkTheme.card 
                      : LightTheme.card,
                  borderRadius: BorderRadius.circular(15),
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
                    // Preferences Title
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                      child: Text(
                        'Preferences',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? DarkTheme.textPrimary 
                              : LightTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
      
                    // Notification
                    Obx(() => _buildPreferenceTile(
                      title: 'Push Notification',
                      imagePath: 'assets/images/push.png',
                      value: controller.pushNotificationEnabled.value,
                      onChanged: (value) {
                        controller.togglePushNotification(value);
                      },
                    )),

                    // Authentication
                    Obx(() => _buildPreferenceTile(
                      title: 'Two Factor Auth',
                      imagePath: 'assets/images/auth.png',

                      value: controller.twoFactorAuthEnabled.value,

                      onChanged: (value) {
                        controller.toggleTwoFactorAuth(value);
                      },
                    )),
                    // Divider(
                    //   color: Theme.of(context).brightness == Brightness.dark
                    //       ? Colors.white.withValues(alpha: 0.1)
                    //       : Colors.black.withValues(alpha: 0.1),
                    //   height: 0,
                    //   thickness: 1,
                    // ),
                    // Dark Mode
                    Obx(() {
                      final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            // color: isDarkTheme
                            //     ? Colors.white.withOpacity(0.12)
                            //     : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.dark_mode_outlined,
                              size: 24,
                              color: isDarkTheme ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        title: Text(
                          'Dark Mode',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? DarkTheme.textPrimary
                                : LightTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Switch(
                          value: themeController.isDarkMode.value,
                          onChanged: (value) {
                            themeController.setDarkMode(value);
                          },
                        ),
                        minLeadingWidth: 40,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

             _buildSignOutButton(controller),
              const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSignOutButton(ProfileController controller) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).brightness == Brightness.dark 
            ? DarkTheme.card 
            : LightTheme.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          // color: Theme.of(Get.context!).brightness == Brightness.dark 
          //     ? Color(0xffB30000).withValues(alpha: 0.1)
          //     : Color(0xffB30000).withValues(alpha: 0.1),
          color: Color(0xffB30000),
          width: 1.0,
        ),
      ),
      child: TextButton(
        onPressed: () {
          debugPrint('Sign Out tapped');
          controller.signOut();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Image.asset('assets/images/logout.png',height: 24,width: 24,),
            const SizedBox(width: 10),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: primaryRed,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Widget for the Custom Sign Out Button
