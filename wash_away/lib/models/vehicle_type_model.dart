import 'package:flutter/material.dart';

class VehicleType {
  final String id;
  final String name;
  final String displayName;
  final String? imageUrl;
  final String? iconPath;
  final int displayOrder;
  final bool isActive;

  VehicleType({
    required this.id,
    required this.name,
    required this.displayName,
    this.imageUrl,
    this.iconPath,
    required this.displayOrder,
    required this.isActive,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? json['displayName'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      iconPath: json['icon_path'] ?? json['iconPath'],
      displayOrder: json['display_order'] ?? json['displayOrder'] ?? 0,
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'display_name': displayName,
      'image_url': imageUrl,
      'icon_path': iconPath,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }

  // Convert to Vehicle class for compatibility with existing code
  Vehicle toVehicle({Color? color}) {
    // Use image_url if available, otherwise fall back to icon_path
    String imagePath = imageUrl ?? iconPath ?? 'assets/images/car6.png';
    return Vehicle(
      type: displayName,
      imagePath: imagePath,
      color: color ?? Colors.blue,
    );
  }
}

// Vehicle class for backward compatibility
class Vehicle {
  final String type;
  final String imagePath;
  final Color color;
  
  Vehicle({
    required this.type,
    required this.imagePath,
    required this.color,
  });
}

