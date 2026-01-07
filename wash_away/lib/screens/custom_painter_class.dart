import 'dart:ui';

import 'package:flutter/cupertino.dart';

class TopCurvedGradientPainter extends CustomPainter {
  final List<Color> gradientColors;

  TopCurvedGradientPainter(this.gradientColors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from slightly below top-left corner to cover border
    path.moveTo(0, 16); // Start at border radius point

    // Left curve - matching 16px border radius
    path.quadraticBezierTo(
      0,
      0,
      16,
      0,
    );

    // Straight top section
    path.lineTo(size.width - 16, 0);

    // Right curve - matching 16px border radius
    path.quadraticBezierTo(
      size.width,
      0,
      size.width,
      16,
    );

    // Close the path to create a filled shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
