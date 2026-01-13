import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../profile/screens/profile_screen.dart';
import 'dashboard_controller.dart';
import '../home/home_screen.dart';
import '../jobs/screens/jobs_screen.dart';
import '../wallet/wallet_screen.dart';
import '../../util/images.dart';
import '../../features/auth/services/auth_service.dart';
import 'widgets/pending_approval_overlay.dart';
import 'widgets/suspended_account_overlay.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _overlayShown = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowOverlay();
  }

  void _checkAndShowOverlay() {
    // Check route arguments first (highest priority)
    final args = Get.arguments as Map<String, dynamic>?;
    final isPendingFromArgs = args?['isPending'] ?? false;
    final isSuspendedFromArgs = args?['isSuspended'] ?? false;

    if (isPendingFromArgs && !_overlayShown) {
      // Show overlay immediately in next frame (before dashboard renders)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_overlayShown) {
          _overlayShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const PendingApprovalOverlay(),
          );
        }
      });
      return;
    }

    if (isSuspendedFromArgs && !_overlayShown) {
      // Show overlay immediately in next frame (before dashboard renders)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_overlayShown) {
          _overlayShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SuspendedAccountOverlay(),
          );
        }
      });
      return;
    }

    // Check cached status asynchronously (for app restart scenarios)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_overlayShown || !mounted) return;

      final authService = AuthService();
      final cachedStatus = await authService.getCachedAccountStatus();
      
      if (cachedStatus == 'pending' && !_overlayShown) {
        _overlayShown = true;
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const PendingApprovalOverlay(),
          );
        }
      } else if (cachedStatus == 'suspended' && !_overlayShown) {
        _overlayShown = true;
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SuspendedAccountOverlay(),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    // List of screens for the navigation
    final List<Widget> screens = [
      const HomeScreen(),
      const JobsScreen(),
      const WalletScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: screens,
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeIndex,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            _navItem(
              context: context,
              label: "Home",
              selectedIcon: AppImages.selectedHome,
              unselectedIcon: AppImages.unSelectHome,
              index: 0,
            ),
            _navItem(
              context: context,
              label: "Jobs",
              selectedIcon: AppImages.selectedJobs,
              unselectedIcon: AppImages.unSelectJobs,
              index: 1,
            ),
            _navItem(
              context: context,
              label: "Wallet",
              selectedIcon: AppImages.selectedWellet,
              unselectedIcon: AppImages.unSelectWellet,
              index: 2,
            ),
            _navItem(
              context: context,
              label: "Profile",
              selectedIcon: AppImages.selectedProfile,
              unselectedIcon: AppImages.unSelectProfile,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem({
    required String label,
    required String selectedIcon,
    required String unselectedIcon,
    required int index,
    required BuildContext context,
  }) {
    final controller = Get.find<DashboardController>();
    final bool isSelected = controller.currentIndex.value == index;
    final Color iconColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).disabledColor;

    return BottomNavigationBarItem(
      icon: ColorFiltered(
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcATop),
        child: Image.asset(
          isSelected ? selectedIcon : unselectedIcon,
        width: 24,
        height: 24,
        ),
      ),
      label: label,
    );
  }
}
