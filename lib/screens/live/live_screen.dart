import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/providers/telemetry_provider.dart';
import 'package:poultri_sense/utils/formatters.dart';
import 'package:poultri_sense/widgets/ammonia_badge.dart';
import 'package:poultri_sense/widgets/offline_banner.dart';
import 'package:poultri_sense/widgets/relay_card.dart';
import 'package:poultri_sense/widgets/sensor_card.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(telemetryProvider).valueOrNull;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Full Sensor Readings ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SensorCard(
                          label: 'Temperature',
                          value: formatTemperature(reading?.temperature),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: SensorCard(
                          label: 'Humidity',
                          value: formatHumidity(reading?.humidity),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Center(
                    child: AmmoniaBadge(
                      ammonia: reading?.ammonia,
                      warmupActive: reading?.warmupActive ?? false,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.035),

                  // ── Relay Controls ──────────────────────────────────────
                  Text(
                    'Relay Controls',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  const RelayCard(channel: 1),
                  SizedBox(height: screenHeight * 0.015),
                  const RelayCard(channel: 2),
                  SizedBox(height: screenHeight * 0.015),
                  const RelayCard(channel: 3),
                  SizedBox(height: screenHeight * 0.015),
                  const RelayCard(channel: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}