import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/telemetry.dart';
import 'package:poultri_sense/providers/sensor_readings_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';
import 'package:poultri_sense/utils/formatters.dart';
import 'package:poultri_sense/widgets/offline_banner.dart';

class SensorReadingsScreen extends ConsumerWidget {
  const SensorReadingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(recentReadingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Readings')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: readingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load readings',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              data: (readings) {
                if (readings.isEmpty) {
                  return Center(
                    child: Text(
                      'No readings yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }

                // Supabase returns most-recent-first; sparklines read
                // left-to-right chronologically, so reverse for charting.
                final chronological = readings.reversed.toList();
                final temps =
                    chronological.map((r) => r.temperature).toList();
                final hums =
                    chronological.map((r) => r.humidity).toList();

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(recentReadingsProvider),
                  child: ListView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    children: [
                      Text('Temperature trend',
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: screenHeight * 0.01),
                      SizedBox(
                        height: screenHeight * 0.12,
                        child: _Sparkline(
                          values: temps,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Text('Humidity trend',
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: screenHeight * 0.01),
                      SizedBox(
                        height: screenHeight * 0.12,
                        child: _Sparkline(
                          values: hums,
                          color: AppTheme.warning,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        'Recent Readings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      const _TableHeader(),
                      const Divider(height: 1),
                      ...readings.map((r) => _ReadingRow(reading: r)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkline ──────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  final List<double?> values; // chronological order — oldest to newest
  final Color color;

  const _Sparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }

    if (spots.length < 2) {
      return Center(
        child: Text(
          'Not enough data for a trend yet',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table Header & Rows ────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Time', style: style)),
          Expanded(flex: 2, child: Text('Temp', style: style)),
          Expanded(flex: 2, child: Text('Hum.', style: style)),
          Expanded(flex: 2, child: Text('NH₃', style: style)),
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final SensorReading reading;

  const _ReadingRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              formatTimestamp(reading.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(flex: 2, child: Text(formatTemperature(reading.temperature))),
          Expanded(flex: 2, child: Text(formatHumidity(reading.humidity))),
          Expanded(
            flex: 2,
            child: Text(
              formatAmmonia(reading.ammonia, warmupActive: reading.warmupActive),
              style: TextStyle(
                color: AppTheme.ammoniaColor(
                  reading.ammonia,
                  warmupActive: reading.warmupActive,
                ),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}