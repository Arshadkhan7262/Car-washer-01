import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'book_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../controllers/dashboard_controller.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    
    final List<Widget> pages = const [
      HomeScreen(),
      BookScreen(),
      HistoryScreen(),
      ProfileScreen(),
    ];

    final List<_NavItem> items = const [
      _NavItem(label: 'Home', imagePath: 'assets/images/home.png'),
      _NavItem(label: 'Book', imagePath: 'assets/images/calendar2.png'),
      _NavItem(label: 'History', imagePath: 'assets/images/history.png'),
      _NavItem(label: 'Profile', imagePath: 'assets/images/user.png'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? DarkTheme.background 
          : LightTheme.background,
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: pages,
      )),
      bottomNavigationBar: _buildBottomNav(controller, items,context),
    );
  }

  Widget _buildBottomNav(DashboardController controller, List<_NavItem> items,BuildContext context) {
    final theme= Theme.of(context).bottomNavigationBarTheme;
    final barColor= theme.backgroundColor;
    final Color selectedColor= theme.selectedItemColor?? Colors.white;
    final unselectedColor= theme.unselectedItemColor?? Colors.white;

    // const Color barColor = Color(0xFF0B0D13);
    // const Color selectedColor = Color(0xFF8DA2FF);
    // const Color unselectedColor = Color(0xFFB8BDCA);
     Color pillColor = Theme.of(context).brightness == Brightness.dark?  DarkTheme.primary.withValues(alpha: 0.13):Color(0xFF151B2B).withValues(alpha: 0.13,);

    return Container(
      decoration: BoxDecoration(
        color: barColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Obx(() {
              final bool isSelected = index == controller.selectedIndex.value;
              return _NavButton(
                item: item,
                isSelected: isSelected,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                pillColor: pillColor,
                onTap: () => controller.changeIndex(index),
              );
            });
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.imagePath});

  final String label;
  final String imagePath;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.pillColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Color pillColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? pillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              item.imagePath,
              color: isSelected ? selectedColor : unselectedColor,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? selectedColor : unselectedColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
