import 'package:flutter/material.dart';
import 'package:poultri_sense/theme/app_theme.dart';
import 'package:poultri_sense/utils/formatters.dart';

class AmmoniaBadge extends StatelessWidget {
  final String? ammonia;
  final bool warmupActive;

  const AmmoniaBadge({
    required this.ammonia,
    required this.warmupActive,
    super.key,
  });

  IconData _iconFor(String? ammonia) {
    switch (ammonia) {
      case 'NORMAL':
        return Icons.check_circle_outline;
      case 'ELEVATED':
        return Icons.warning_amber_outlined;
      case 'ALERT':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final label = formatAmmonia(ammonia, warmupActive: warmupActive);
    final color = AppTheme.ammoniaColor(ammonia, warmupActive: warmupActive);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.025,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            warmupActive ? Icons.hourglass_top : _iconFor(ammonia),
            color: color,
            size: screenWidth * 0.05,
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}