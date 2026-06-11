// lib/widgets/booking_status_chip.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class BookingStatusChip extends StatelessWidget {
  final String status;
  const BookingStatusChip({super.key, required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending':   return AppTheme.warningOrange;
      case 'confirmed': return AppTheme.skyBlue;
      case 'active':    return AppTheme.primaryGreen;
      case 'completed': return AppTheme.greyText;
      case 'cancelled':
      case 'rejected':  return AppTheme.errorRed;
      default:          return AppTheme.greyText;
    }
  }

  IconData get _icon {
    switch (status.toLowerCase()) {
      case 'pending':   return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'active':    return Icons.play_circle_outline;
      case 'completed': return Icons.done_all;
      default:          return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _color),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icon, size: 14, color: _color),
      const SizedBox(width: 4),
      Text(status.toUpperCase(),
          style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}
