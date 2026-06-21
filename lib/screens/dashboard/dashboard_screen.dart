import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/device_status.dart';
import 'package:poultri_sense/models/relay_state.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/providers/device_status_provider.dart';
import 'package:poultri_sense/providers/events_provider.dart';
import 'package:poultri_sense/providers/relay_provider.dart';
import 'package:poultri_sense/providers/telemetry_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';
import 'package:poultri_sense/utils/formatters.dart';
import 'package:poultri_sense/widgets/offline_banner.dart';
import 'package:poultri_sense/widgets/sensor_card.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final deviceId = ref.watch(deviceProvider).deviceId;
    final deviceStatus = ref.watch(deviceStatusProvider);
    final reading = ref.watch(telemetryProvider).valueOrNull;
    final lastEvent = ref.watch(lastEventProvider);

    return Scaffold(
      // appBar: AppBar(title: const Text('Dashboard')),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Re-pair device',
            onPressed: () => context.go('/setup'),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Device Status Card ──────────────────────────────
                  _DeviceStatusCard(status: deviceStatus, deviceId: deviceId),
                  SizedBox(height: screenHeight * 0.02),

                  // ── Sensor Summary Row ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SensorCard(
                          label: 'Temperature',
                          value: formatTemperature(reading?.temperature),
                          icon: Icons.thermostat,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: SensorCard(
                          label: 'Humidity',
                          value: formatHumidity(reading?.humidity),
                          icon: Icons.water_drop,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: SensorCard(
                          label: 'Ammonia',
                          value: formatAmmonia(
                            reading?.ammonia,
                            warmupActive: reading?.warmupActive ?? false,
                          ),
                          icon: Icons.air,
                          valueColor: AppTheme.ammoniaColor(
                            reading?.ammonia,
                            warmupActive: reading?.warmupActive ?? false,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // ── Last Event Card ───────────────────────────────────
                  _LastEventCard(event: lastEvent),
                  SizedBox(height: screenHeight * 0.02),

                  // ── Relay Strip ────────────────────────────────────────
                  Text(
                    'Relay Status',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  const Row(
                    children: [
                      Expanded(child: _RelayIndicatorTile(channel: 1)),
                      Expanded(child: _RelayIndicatorTile(channel: 2)),
                      Expanded(child: _RelayIndicatorTile(channel: 3)),
                      Expanded(child: _RelayIndicatorTile(channel: 4)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Status Card ────────────────────────────────────────────────────────

class _DeviceStatusCard extends StatelessWidget {
  final DeviceStatus status;
  final String? deviceId;

  const _DeviceStatusCard({required this.status, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final (icon, color, label) = switch (status) {
      DeviceStatus.online => (Icons.cloud_done, AppTheme.success, 'Online'),
      DeviceStatus.offline => (Icons.cloud_off, AppTheme.alert, 'Offline'),
      DeviceStatus.connecting => (
        Icons.cloud_sync,
        AppTheme.warning,
        'Connecting…',
      ),
    };

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  if (deviceId != null)
                    Text(
                      deviceId!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Last Event Card ─────────────────────────────────────────────────────────

class _LastEventCard extends StatelessWidget {
  final dynamic event; // SystemEvent?

  const _LastEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Row(
          children: [
            Icon(
              Icons.event_note_outlined,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: event == null
                  ? Text(
                      'No events recorded',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${event.sensorId} ${event.eventType}'),
                        Text(
                          formatTimestamp(event.timestamp),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Relay Indicator Tile (read-only) ──────────────────────────────────────────

class _RelayIndicatorTile extends ConsumerWidget {
  final int channel;

  const _RelayIndicatorTile({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relay = ref.watch(relayProvider(channel));
    final screenWidth = MediaQuery.of(context).size.width;

    final modeLabel = switch (relay.mode) {
      RelayMode.auto => 'AUTO',
      RelayMode.manual => 'MANUAL',
      RelayMode.pending => '···',
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                relay.isOn ? Icons.power : Icons.power_off,
                color: AppTheme.relayModeColor(relay.isOn),
                size: screenWidth * 0.06,
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                relay.channelName,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                modeLabel,
                style: TextStyle(
                  fontSize: screenWidth * 0.025,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
