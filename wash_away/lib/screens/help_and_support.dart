import 'package:flutter/material.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? DarkTheme.background 
          : LightTheme.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Text('Help & Support Screen'),
        ],
      ),
    );
  }
}
