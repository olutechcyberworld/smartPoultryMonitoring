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
            Image.asset(
              'assets/icon/icon_foreground.png',
              width: screenWidth * 0.18,
            ),
            SizedBox(height: screenHeight * 0.012),
            Text(
              'PoultriSense',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'by OLUTECH Engineering',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: screenHeight * 0.03),

            // ── Project Owner ───────────────────────────────────────────
            const _OwnerCard(),
            SizedBox(height: screenHeight * 0.02),

            // ── Developed By ────────────────────────────────────────────
            const _DeveloperCard(),
            SizedBox(height: screenHeight * 0.03),

            // ── Paired Device ───────────────────────────────────────────
            Card(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  children: [
                    Text(
                      'Paired Device',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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

            // ── Project Info ─────────────────────────────────────────────
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
                    const _InfoRow(
                      label: 'Temperature & Humidity',
                      value: 'AHT21',
                    ),
                    const _InfoRow(
                      label: 'Ammonia Monitoring',
                      value: 'MQ-135',
                    ),
                    const _InfoRow(
                      label: 'Edge Controller',
                      value: 'ESP32 (FreeRTOS)',
                    ),
                    const _InfoRow(
                      label: 'Telemetry',
                      value: 'MQTT (EMQX Cloud)',
                    ),
                    const _InfoRow(
                      label: 'Data Storage',
                      value: 'Supabase (PostgreSQL)',
                    ),
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

// ── Project Owner Card ────────────────────────────────────────────────────

class _OwnerCard extends StatelessWidget {
  const _OwnerCard();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: AppTheme.primary,
                  size: screenWidth * 0.05,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Project Owner',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.035),
            const _InfoRow(label: 'Name', value: 'OLUSI MICHAEL OLUWADAMILARE'),
            const _InfoRow(label: 'Matric No.', value: 'CPE/HND/F24/034'),
            const _InfoRow(label: 'Department', value: 'Computer Engineering'),
            const _InfoRow(
              label: 'School',
              value: 'Federal Polytechnic, Ile-Oluji',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Developer Card ─────────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          children: [
            Text('Developed By', style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: screenWidth * 0.04),
            Image.asset(
              'assets/images/brand_logo.png',
              width: screenWidth * 0.55,
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              'Olutech Cyberworld',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: screenWidth * 0.025),
            _ContactRow(
              icon: Icons.email_outlined,
              text: 'olutechcyberworld@gmail.com',
            ),
            SizedBox(height: screenWidth * 0.012),
            _ContactRow(icon: Icons.phone_outlined, text: '07015594518'),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        SelectableText(text, style: Theme.of(context).textTheme.bodyMedium),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
