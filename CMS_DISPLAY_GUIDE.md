# 📱 CMS Content Display Guide

## Where Published CMS Content is Displayed

When you publish a CMS page in the Admin Panel, it becomes available for **Flutter Mobile Apps** (Customer App & Washer App) through a public API endpoint.

---

## 🌐 Public API Endpoint

**Endpoint:** `GET /api/v1/cms/:slug`

**Base URL:** `http://your-backend-url/api/v1/cms/`

**Example URLs:**
- `http://localhost:3000/api/v1/cms/privacy-customer`
- `http://localhost:3000/api/v1/cms/terms-washer`
- `http://localhost:3000/api/v1/cms/faq-general`
- `http://localhost:3000/api/v1/cms/about-us`

**Response Format:**
```json
{
  "success": true,
  "data": {
    "slug": "privacy-customer",
    "title": "Privacy Policy",
    "content": "<p>Your HTML content here...</p><img src=\"...\">",
    "target": "customer",
    "updatedAt": "2024-01-15T10:00:00Z"
  }
}
```

---

## 📱 Flutter Mobile App Integration

### 1. Add Required Package

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_widget_from_html: ^0.14.11
  http: ^1.1.0
```

### 2. Create CMS Service

Create `lib/services/cms_service.dart`:
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CMSService {
  final String baseUrl = 'http://your-backend-url/api/v1';
  
  Future<Map<String, dynamic>> getCMSContent(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cms/$slug'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to load content');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Content not found');
      } else {
        throw Exception('Failed to load content: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching CMS content: $e');
    }
  }
}
```

### 3. Create CMS Display Screen

Create `lib/screens/cms_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/cms_service.dart';

class CMSScreen extends StatefulWidget {
  final String slug;
  final String title;
  
  const CMSScreen({
    Key? key,
    required this.slug,
    required this.title,
  }) : super(key: key);

  @override
  State<CMSScreen> createState() => _CMSScreenState();
}

class _CMSScreenState extends State<CMSScreen> {
  final CMSService _cmsService = CMSService();
  Map<String, dynamic>? _content;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await _cmsService.getCMSContent(widget.slug);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_content?['title'] ?? widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: HtmlWidget(
                    _content!['content'] ?? '',
                    textStyle: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
    );
  }
}
```

### 4. Navigate to CMS Screens

**Example: Privacy Policy (Customer App)**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CMSScreen(
      slug: 'privacy-customer',
      title: 'Privacy Policy',
    ),
  ),
);
```

**Example: Terms & Conditions (Washer App)**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CMSScreen(
      slug: 'terms-washer',
      title: 'Terms & Conditions',
    ),
  ),
);
```

**Example: FAQ (Both Apps)**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CMSScreen(
      slug: 'faq-general',
      title: 'FAQ',
    ),
  ),
);
```

---

## 📍 Where to Display in Your App

### Customer App:
1. **Privacy Policy** → Settings → Privacy Policy
2. **Terms & Conditions** → Settings → Terms & Conditions
3. **FAQ** → Help & Support → FAQ
4. **About Us** → Settings → About Us

### Washer App:
1. **Privacy Policy** → Profile → Privacy Policy
2. **Terms & Conditions** → Profile → Terms & Conditions
3. **FAQ** → Help → FAQ
4. **About Us** → Profile → About Us

---

## ✅ Testing

### Test API Endpoint:
```bash
# Test in browser or Postman
GET http://localhost:3000/api/v1/cms/privacy-customer
```

### Expected Response:
```json
{
  "success": true,
  "data": {
    "slug": "privacy-customer",
    "title": "Privacy Policy",
    "content": "<p>Your published HTML content...</p>",
    "target": "customer",
    "updatedAt": "2024-01-15T10:00:00Z"
  }
}
```

---

## 🔒 Security Notes

- ✅ **Public Endpoint** - No authentication required (read-only)
- ✅ **Only Published Content** - Drafts are not accessible
- ✅ **HTML Sanitized** - All content is sanitized before saving
- ✅ **XSS Protected** - DOMPurify prevents malicious scripts

---

## 📝 CMS Pages Available

| Slug | Title | Target | Usage |
|------|-------|--------|-------|
| `privacy-customer` | Privacy Policy | Customer | Customer App |
| `privacy-washer` | Privacy Policy | Washer | Washer App |
| `terms-customer` | Terms & Conditions | Customer | Customer App |
| `terms-washer` | Terms & Conditions | Washer | Washer App |
| `faq-general` | FAQ | Both | Both Apps |
| `about-us` | About Us | Both | Both Apps |

---

## 🚀 Quick Start

1. **Publish content** in Admin Panel
2. **Test API** endpoint in browser/Postman
3. **Add Flutter package** `flutter_widget_from_html`
4. **Create CMS service** to fetch content
5. **Create CMS screen** to display content
6. **Navigate** to CMS screen from your app

---

## 💡 Tips

- Cache CMS content locally to reduce API calls
- Show loading indicator while fetching
- Handle 404 errors gracefully
- Update content when app starts (optional)
- Use `HtmlWidget` for proper HTML rendering
