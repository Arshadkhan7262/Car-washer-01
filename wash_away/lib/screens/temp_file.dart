import 'package:flutter/material.dart';
import 'package:wash_away/models/service_model.dart';
import 'package:wash_away/widgets/service_card_widget.dart';

class TempFile extends StatefulWidget {
  const TempFile({super.key});

  @override
  State<TempFile> createState() => _TempFileState();
}

class _TempFileState extends State<TempFile> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            ServiceCardWidget(service: Service(title: 'Express wash ', subtitle: 'Interior wash', price: '\$50', iconColor: Color(0xff6E7DFF), isPopular: true, durationMin: 90, features: ['Exterior wash', 'Tire Shine'], imagePath: 'assets/images/drop.png')),
          ],
        ),
      ),
    );
  }
}