import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId = ref.watch(deviceProvider).deviceId;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            const Icon(Icons.eco, size: 56, color: AppTheme.primary),
            SizedBox(height: screenHeight * 0.012),
            Text(
              'PoultriSense',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'by OLUTECH Engineering',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: screenHeight * 0.03),

            // ── Paired Device ─────────────────────────────────────────
            Card(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  children: [
                    Text('Paired Device',
                        style: Theme.of(context).textTheme.bodySmall),
                    SizedBox(height: screenHeight * 0.015),
                    if (deviceId != null) ...[
                      QrImageView(
                        data: deviceId,
                        size: screenWidth * 0.45,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        deviceId,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        'Scan or copy this ID for the enclosure label',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ] else
                      Text(
                        'No device paired',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            OutlinedButton.icon(
              onPressed: () => context.go('/setup'),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Re-pair Device'),
            ),
            SizedBox(height: screenHeight * 0.03),

            // ── Project Info ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This Project',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Smart Poultry Environmental Monitoring & Control System — '
                      'a final-year engineering prototype demonstrating real-time '
                      'environmental sensing, automated climate control, and remote '
                      'monitoring for poultry housing.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    const _InfoRow(label: 'Temperature & Humidity', value: 'AHT21'),
                    const _InfoRow(label: 'Ammonia Monitoring', value: 'MQ-135'),
                    const _InfoRow(label: 'Edge Controller', value: 'ESP32 (FreeRTOS)'),
                    const _InfoRow(label: 'Telemetry', value: 'MQTT (EMQX Cloud)'),
                    const _InfoRow(label: 'Data Storage', value: 'Supabase (PostgreSQL)'),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text('Version 1.0.0', style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}