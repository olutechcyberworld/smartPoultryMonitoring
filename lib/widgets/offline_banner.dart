import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/device_status.dart';
import 'package:poultri_sense/providers/device_status_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(deviceStatusProvider);

    if (status != DeviceStatus.offline) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: AppTheme.alert,
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.025,
        horizontal: screenWidth * 0.04,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.black, size: 18),
          SizedBox(width: screenWidth * 0.02),
          const Expanded(
            child: Text(
              'Device offline — showing last known values',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}