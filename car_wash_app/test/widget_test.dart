// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_wash_app/main.dart';
import 'package:car_wash_app/routes.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame with the login route.
    await tester.pumpWidget(const MyApp(initialRoute: AppRoutes.login));

    // Verify that the app builds without errors
    // The app should load the login screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
