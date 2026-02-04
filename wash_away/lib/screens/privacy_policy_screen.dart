import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? DarkTheme.textPrimary : LightTheme.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: titleColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(context, 'Last updated', isDark),
            _bodyText(
              context,
              'This Privacy Policy describes how Wash Away ("we", "our", or "us") collects, uses, and shares your information when you use our mobile application and car wash services.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '1. Information We Collect', isDark),
            _bodyText(
              context,
              'We may collect the following types of information:\n\n'
              '• Account information: name, email address, phone number, and profile picture (e.g. when you sign in with Google).\n\n'
              '• Vehicle information: vehicle type, license plate, and saved wash preferences.\n\n'
              '• Location data: address and location for service delivery and pickup, when you grant permission.\n\n'
              '• Payment information: payment method details are processed securely by our payment providers (e.g. Stripe); we do not store full card numbers.\n\n'
              '• Usage data: app usage, booking history, and device information (e.g. device type, OS) to improve our services.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '2. How We Use Your Information', isDark),
            _bodyText(
              context,
              'We use your information to:\n\n'
              '• Provide, maintain, and improve our car wash booking and payment services.\n\n'
              '• Process payments and manage your wallet and transactions.\n\n'
              '• Send you service-related notifications (e.g. booking confirmations, status updates).\n\n'
              '• Respond to your requests and support inquiries.\n\n'
              '• Comply with legal obligations and enforce our terms.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '3. Data Sharing', isDark),
            _bodyText(
              context,
              'We may share your information with:\n\n'
              '• Service providers (payment processors, cloud hosting, analytics) who assist in operating our app and backend.\n\n'
              '• Washers or partners who perform the car wash service, only as needed to fulfill your booking.\n\n'
              '• Law enforcement or authorities when required by law.\n\n'
              'We do not sell your personal information to third parties.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '4. Data Security', isDark),
            _bodyText(
              context,
              'We use industry-standard measures to protect your data, including encryption and secure APIs. Payment data is handled by certified payment providers.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '5. Your Choices', isDark),
            _bodyText(
              context,
              'You can:\n\n'
              '• Update your profile and preferences in the app.\n\n'
              '• Control push notifications in your device and app settings.\n\n'
              '• Request access to or deletion of your data by contacting our support team.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '6. Children', isDark),
            _bodyText(
              context,
              'Our services are not directed to individuals under 16. We do not knowingly collect personal information from children.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '7. Changes to This Policy', isDark),
            _bodyText(
              context,
              'We may update this Privacy Policy from time to time. We will notify you of material changes via the app or email where appropriate.',
              isDark,
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, '8. Contact Us', isDark),
            _bodyText(
              context,
              'For privacy-related questions or requests, contact us at:\n\nMITProgrammers@gmail.com',
              isDark,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? DarkTheme.textPrimary : LightTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _bodyText(BuildContext context, String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: isDark ? DarkTheme.textSecondary : LightTheme.textSecondary,
      ),
    );
  }
}
