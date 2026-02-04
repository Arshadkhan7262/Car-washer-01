import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';
import '../controllers/profile_controller.dart';
import 'profile_platform_stub.dart'
    if (dart.library.io) 'profile_platform_io.dart' as profile_platform;

class PaymentMethods extends StatefulWidget {
  const PaymentMethods({super.key});

  @override
  State<PaymentMethods> createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends State<PaymentMethods> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> methods = [
      {'name': 'Credit Card', 'details': 'Card payments via Stripe', 'imagePath': 'assets/images/card.png'},
      {'name': 'Wallet', 'details': null, 'imagePath': 'assets/images/wallet.png'},
      {'name': 'Cash', 'details': 'Pay on completion', 'imagePath': 'assets/images/cash.png'},
      if (profile_platform.isIOS)
        {'name': 'Apple Pay', 'details': 'Fast & secure', 'imagePath': 'assets/images/apple.png'},
      if (profile_platform.isAndroid)
        {'name': 'Google Pay', 'details': 'Fast & secure', 'imagePath': 'assets/images/googlepay.png'},
    ];

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkTheme ? DarkTheme.background : LightTheme.background,
        appBar: AppBar(
          title: const Text('Payment Methods'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            ...methods.map((method) {
              final String name = method['name'] as String;
              return _buildMethodRow(context, method, name, isDarkTheme);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodRow(
    BuildContext context,
    Map<String, dynamic> method,
    String name,
    bool isDarkTheme,
  ) {
    String? details = method['details'] as String?;
    if (name == 'Wallet') {
      if (Get.isRegistered<ProfileController>()) {
        return Obx(() {
          final controller = Get.find<ProfileController>();
          details = 'Balance: \$${controller.walletBalance.value.toStringAsFixed(2)}';
          return _methodCard(context, method, name, details, isDarkTheme);
        });
      }
      details = 'Balance: —';
    }
    return _methodCard(context, method, name, details, isDarkTheme);
  }

  Widget _methodCard(
    BuildContext context,
    Map<String, dynamic> method,
    String name,
    String? details,
    bool isDarkTheme,
  ) {
    return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDarkTheme ? DarkTheme.card : LightTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkTheme
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkTheme
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Image.asset(
                          method['imagePath'] as String,
                          width: 22,
                          height: 22,
                          color: isDarkTheme ? Colors.white : Colors.black,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.payment,
                            size: 22,
                            color: isDarkTheme ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              color: isDarkTheme ? DarkTheme.textPrimary : LightTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (details != null && details.isNotEmpty)
                            Text(
                              details,
                              style: GoogleFonts.inter(
                                color: isDarkTheme ? DarkTheme.textTertiary : LightTheme.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
  }
}
