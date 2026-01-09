import 'package:car_wash_app/util/images.dart';
import 'package:flutter/material.dart';

class HomeActionMenu extends StatelessWidget {
  const HomeActionMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionItem(
          label: "View Jobs",
          icon: AppImages.jobs,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _ActionItem(
          label: "Wallet",
          icon: AppImages.wallet,
          color: Theme.of(context).colorScheme.primary,
        ),
        _ActionItem(
          label: "Profile",
          icon: AppImages.profile,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label, icon;
  final Color color;
  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(child: Image.asset(icon, height: 30, color: color)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
