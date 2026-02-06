# Flutter CMS Integration Guide

## Open CMS Pages in External Browser

Use `url_launcher` package to open CMS pages in the device's external browser.

### 1. Add Dependency

Add to `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.2.4
```

### 2. Create CMS Helper

Create `lib/utils/cms_helper.dart`:
```dart
import 'package:url_launcher/url_launcher.dart';

class CMSHelper {
  // Base URL for your admin panel public view
  // Change this to your production URL
  static const String baseUrl = 'https://your-admin-panel.com';
  
  // For development/testing
  // static const String baseUrl = 'http://localhost:5173'; // Vite dev server
  // static const String baseUrl = 'http://192.168.1.100:5173'; // Network IP

  /// Opens a CMS page in the external browser
  /// 
  /// [slug] - The CMS page slug (e.g., 'privacy-customer', 'terms-washer')
  /// 
  /// Returns true if the URL was launched successfully
  static Future<bool> openCMSPage(String slug) async {
    final url = Uri.parse('$baseUrl/view/$slug');
    
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Opens in external browser
        );
      } else {
        print('Cannot launch URL: $url');
        return false;
      }
    } catch (e) {
      print('Error launching URL: $e');
      return false;
    }
  }

  /// Get the public URL for a CMS page (useful for sharing)
  static String getCMSPageUrl(String slug) {
    return '$baseUrl/view/$slug';
  }
}
```

### 3. Usage Examples

#### Example 1: Privacy Policy Button
```dart
import 'package:flutter/material.dart';
import '../utils/cms_helper.dart';

class PrivacyPolicyButton extends StatelessWidget {
  final String slug; // 'privacy-customer' or 'privacy-washer'
  
  const PrivacyPolicyButton({Key? key, required this.slug}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.privacy_tip),
      title: const Text('Privacy Policy'),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final launched = await CMSHelper.openCMSPage(slug);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open Privacy Policy'),
            ),
          );
        }
      },
    );
  }
}
```

#### Example 2: Terms & Conditions in Settings
```dart
import 'package:flutter/material.dart';
import '../utils/cms_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CMSHelper.openCMSPage('terms-customer'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CMSHelper.openCMSPage('privacy-customer'),
          ),
          ListTile(
            title: const Text('FAQ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CMSHelper.openCMSPage('faq-general'),
          ),
          ListTile(
            title: const Text('About Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CMSHelper.openCMSPage('about-us'),
          ),
        ],
      ),
    );
  }
}
```

#### Example 3: Washer App Profile Screen
```dart
import 'package:flutter/material.dart';
import '../utils/cms_helper.dart';

class WasherProfileScreen extends StatelessWidget {
  const WasherProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          // ... other profile items ...
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            subtitle: const Text('View our terms'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => CMSHelper.openCMSPage('terms-washer'),
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we protect your data'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => CMSHelper.openCMSPage('privacy-washer'),
          ),
        ],
      ),
    );
  }
}
```

#### Example 4: Help & Support Screen
```dart
import 'package:flutter/material.dart';
import '../utils/cms_helper.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Frequently Asked Questions'),
            subtitle: const Text('Find answers to common questions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CMSHelper.openCMSPage('faq-general'),
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            subtitle: const Text('Learn more about our company'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => CMSHelper.openCMSPage('about-us'),
          ),
        ],
      ),
    );
  }
}
```

### 4. Available CMS Slugs

| Slug | Title | Target |
|------|-------|--------|
| `privacy-customer` | Privacy Policy | Customer App |
| `privacy-washer` | Privacy Policy | Washer App |
| `terms-customer` | Terms & Conditions | Customer App |
| `terms-washer` | Terms & Conditions | Washer App |
| `faq-general` | FAQ | Both Apps |
| `about-us` | About Us | Both Apps |

### 5. Configuration

#### For Development:
```dart
static const String baseUrl = 'http://localhost:5173'; // Vite dev server
// OR
static const String baseUrl = 'http://192.168.1.100:5173'; // Your local IP
```

#### For Production:
```dart
static const String baseUrl = 'https://admin.yourdomain.com';
```

### 6. Error Handling

The `openCMSPage` method returns `false` if the URL cannot be launched. You can handle errors:

```dart
final launched = await CMSHelper.openCMSPage('privacy-customer');
if (!launched) {
  // Show error message to user
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Unable to open page. Please check your internet connection.'),
    ),
  );
}
```

### 7. Testing

1. Make sure your admin panel is running and accessible
2. Publish a CMS page in the admin panel
3. Test the URL in a browser: `http://your-url/view/privacy-customer`
4. Use the Flutter code to open the same URL

### 8. Notes

- The `LaunchMode.externalApplication` opens the URL in the device's default browser
- Use `LaunchMode.inAppWebView` if you want to open in an in-app browser
- The URL must be accessible from the device (not localhost unless using network IP)
- Make sure the CMS page is published (not draft) for it to be accessible
