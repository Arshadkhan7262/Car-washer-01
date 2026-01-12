import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title, trailingText;
  const SectionHeader({
    super.key,
    required this.title,
    required this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: () {}, child: Text(trailingText)),
      ],
    );
  }
}
