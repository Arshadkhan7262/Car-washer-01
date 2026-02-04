import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

const String _supportEmail = 'MITProgrammers@gmail.com';

class HelpAndSupport extends StatelessWidget {
  const HelpAndSupport({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: _encodeQueryParameters({'subject': 'Wash Away – Support Request'}),
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      Get.snackbar(
        'Email copied',
        'Support email copied to clipboard.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    Get.snackbar(
      'Copied',
      'Support email copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? DarkTheme.textPrimary : LightTheme.textPrimary;
    final bodyColor = isDark ? DarkTheme.textSecondary : LightTheme.textSecondary;
    final cardColor = isDark ? DarkTheme.card : LightTheme.card;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: isDark ? DarkTheme.background : LightTheme.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
            Text(
              'Frequently asked questions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            _faqCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              title: 'How do I book a car wash?',
              body:
                  'Go to the Book tab, choose your service, select date/time and address, pick a payment method, and confirm your booking.',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _faqCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              title: 'How can I pay?',
              body:
                  'You can pay with Credit Card (Stripe), Wallet balance, Cash on completion, or Apple Pay / Google Pay where available.',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _faqCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              title: 'How do I add funds to my wallet?',
              body: 'Open Profile → Add Funds to Wallet, enter the amount, and complete payment with your preferred method.',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _faqCard(
              context,
              cardColor: cardColor,
              borderColor: borderColor,
              title: 'I have a problem with my booking',
              body:
                  'Check the History tab for booking status. For refunds, cancellations, or other issues, contact our support team using the email below.',
              isDark: isDark,
            ),
            const SizedBox(height: 28),
            Text(
              'Contact support',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email us for help, feedback, or account issues:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: bodyColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: isDark ? DarkTheme.primary : LightTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _supportEmail,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _launchEmail,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open email app'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDark ? DarkTheme.primary : LightTheme.primary,
                            side: BorderSide(
                              color: isDark
                                  ? DarkTheme.primary
                                  : LightTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyEmail,
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy email'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isDark ? DarkTheme.primary : LightTheme.primary,
                            side: BorderSide(
                              color: isDark
                                  ? DarkTheme.primary
                                  : LightTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _faqCard(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    required String title,
    required String body,
    required bool isDark,
  }) {
    final titleColor = isDark ? DarkTheme.textPrimary : LightTheme.textPrimary;
    final bodyColor = isDark ? DarkTheme.textSecondary : LightTheme.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}
