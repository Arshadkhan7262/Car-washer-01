// lib/models/service_model.dart

import 'package:flutter/material.dart';

class Service {
  final String? id;
  final String name; // Maps to 'name' from backend
  final String? description;
  final String? shortDescription; // Maps to 'short_description' from backend
  final int durationMinutes; // Maps to 'duration_minutes' from backend
  final double basePrice; // Maps to 'base_price' from backend
  final Map<String, double>? pricing;
  final List<String> includes; // Maps to 'includes' from backend
  final bool isPopular; // Maps to 'is_popular' from backend
  final bool isActive; // Maps to 'is_active' from backend
  final int displayOrder; // Maps to 'display_order' from backend

  // UI-specific fields (for backward compatibility)
  final String title; // Alias for name
  final String subtitle; // Alias for shortDescription or description
  final String price; // Formatted price string
  final Color iconColor; // Default color based on service
  final int durationMin; // Alias for durationMinutes
  final List<String> features; // Alias for includes
  final String imagePath; // Default image path

  Service({
    this.id,
    String? name,
    this.description,
    this.shortDescription,
    int? durationMinutes,
    double? basePrice,
    this.pricing,
    List<String>? includes,
    bool? isPopular,
    bool? isActive,
    int? displayOrder,
    // UI fields (for backward compatibility with old code)
    String? title,
    String? subtitle,
    String? price,
    Color? iconColor,
    int? durationMin,
    List<String>? features,
    String? imagePath,
  })  : name = name ?? title ?? 'Service',
        durationMinutes = durationMinutes ?? durationMin ?? 60,
        basePrice = basePrice ?? _parsePrice(price) ?? 0.0,
        includes = includes ?? features ?? [],
        isPopular = isPopular ?? false,
        isActive = isActive ?? true,
        displayOrder = displayOrder ?? 0,
        title = title ?? name ?? 'Service',
        subtitle = subtitle ?? shortDescription ?? description ?? '',
        price = price ?? '\$${(basePrice ?? _parsePrice(price) ?? 0.0).toStringAsFixed(0)}',
        iconColor = iconColor ?? _getDefaultColor(name ?? title ?? 'Service'),
        durationMin = durationMin ?? durationMinutes ?? 60,
        features = features ?? includes ?? [],
        imagePath = imagePath ?? _getDefaultImagePath(name ?? title ?? 'Service');

  // Factory constructor from JSON (backend response)
  factory Service.fromJson(Map<String, dynamic> json) {
    // Convert pricing Map if it exists
    Map<String, double>? pricingMap;
    if (json['pricing'] != null) {
      if (json['pricing'] is Map) {
        pricingMap = Map<String, double>.from(
          (json['pricing'] as Map).map((key, value) => MapEntry(
                key.toString(),
                (value is num) ? value.toDouble() : 0.0,
              )),
        );
      }
    }

    // Convert includes array
    List<String> includesList = [];
    if (json['includes'] != null && json['includes'] is List) {
      includesList = List<String>.from(json['includes']);
    }

    return Service(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      shortDescription: json['short_description'],
      durationMinutes: json['duration_minutes'] ?? 60,
      basePrice: (json['base_price'] is num) ? json['base_price'].toDouble() : 0.0,
      pricing: pricingMap,
      includes: includesList,
      isPopular: json['is_popular'] ?? false,
      isActive: json['is_active'] ?? true,
      displayOrder: json['display_order'] ?? 0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'short_description': shortDescription,
      'duration_minutes': durationMinutes,
      'base_price': basePrice,
      'pricing': pricing,
      'includes': includes,
      'is_popular': isPopular,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  // Helper method to get default color based on service name
  static Color _getDefaultColor(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('express')) {
      return const Color(0xFF42A5F5);
    } else if (nameLower.contains('premium') || nameLower.contains('full')) {
      return const Color(0xFF11B189);
    } else if (nameLower.contains('interior')) {
      return const Color(0xFF9958D9);
    } else {
      return const Color(0xFF42A5F5);
    }
  }

  // Helper method to get default image path based on service name
  static String _getDefaultImagePath(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('express')) {
      return 'assets/images/drop.png';
    } else if (nameLower.contains('premium') || nameLower.contains('full')) {
      return 'assets/images/stream.png';
    } else if (nameLower.contains('interior')) {
      return 'assets/images/interior.png';
    } else {
      return 'assets/images/drop.png';
    }
  }

  // Helper method to parse price string to double
  static double? _parsePrice(String? priceStr) {
    if (priceStr == null) return null;
    // Remove $ and parse
    final cleaned = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }
}

class Vehicle {
  final String type;
  final String imagePath;
  final Color color;
  Vehicle({required this.type, required this.imagePath, required this.color});
}