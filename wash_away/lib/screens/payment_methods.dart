import 'package:flutter/material.dart';
import '../themes/dark_theme.dart';
import '../themes/light_theme.dart';

class PaymentMethods extends StatefulWidget {
  const PaymentMethods({super.key});

  @override
  State<PaymentMethods> createState() => _PaymentMethodsState();
}

class _PaymentMethodsState extends State<PaymentMethods> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? DarkTheme.background 
            : LightTheme.background,
        appBar: AppBar(
          title: const Text('Payment Methods'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Payment Methods Screen'),
        ),
      ),
    );
  }
}
