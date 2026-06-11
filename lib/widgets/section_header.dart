// lib/widgets/section_header.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(actionLabel!, style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primaryGreen),
          ]),
        ),
    ],
  );
}
