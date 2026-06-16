import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:poultri_sense/models/telemetry.dart';
import 'package:poultri_sense/providers/history_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';
import 'package:poultri_sense/utils/formatters.dart';
import 'package:poultri_sense/widgets/offline_banner.dart';

enum _ChartType { temperature, humidity }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _presets = {
    '30 min': Duration(minutes: 30),
    '1 hr': Duration(hours: 1),
    '6 hr': Duration(hours: 6),
    '24 hr': Duration(hours: 24),
    '7 days': Duration(days: 7),
    '30 days': Duration(days: 30),
  };

  late DateTime _from;
  late DateTime _to;
  String _selectedPreset = '24 hr';

  @override
  void initState() {
    super.initState();
    _to = DateTime.now();
    _from = _to.subtract(_presets[_selectedPreset]!);
  }

  void _selectPreset(String label) {
    setState(() {
      _selectedPreset = label;
      _to = DateTime.now();
      _from = _to.subtract(_presets[label]!);
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked == null) return;

    setState(() {
      _selectedPreset = 'custom';
      _from = picked.start;
      // Include the entire end day, not just its midnight.
      _to = picked.end.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = HistoryQuery(from: _from, to: _to);
    final historyAsync = ref.watch(historyProvider(query));
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          const OfflineBanner(),

          // ── Range Presets ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenWidth * 0.02,
            ),
            child: Wrap(
              spacing: screenWidth * 0.02,
              runSpacing: screenWidth * 0.02,
              children: [
                for (final label in _presets.keys)
                  ChoiceChip(
                    label: Text(label),
                    selected: _selectedPreset == label,
                    onSelected: (_) => _selectPreset(label),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _selectedPreset == 'custom' ? 'Custom range ✓' : 'Custom range',
                  ),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
          ),

          // ── Selected Range Label ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatTimestamp(_from)}  →  ${formatTimestamp(_to)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.02),

          // ── Charts ────────────────────────────────────────────────────
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load history',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              data: (readings) {
                if (readings.isEmpty) {
                  return Center(
                    child: Text(
                      'No data in this range',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(historyProvider(query)),
                  child: ListView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    children: [
                      Text('Temperature (°C)',
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: screenHeight * 0.01),
                      SizedBox(
                        height: screenHeight * 0.22,
                        child: _HistoryChart(
                          readings: readings,
                          type: _ChartType.temperature,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text('Humidity (%)',
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: screenHeight * 0.01),
                      SizedBox(
                        height: screenHeight * 0.22,
                        child: _HistoryChart(
                          readings: readings,
                          type: _ChartType.humidity,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      Text('Ammonia Tier',
                          style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: screenHeight * 0.01),
                      _AmmoniaTimeline(readings: readings),
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

// ── Line Chart ──────────────────────────────────────────────────────────────

class _HistoryChart extends StatelessWidget {
  final List<SensorReading> readings;
  final _ChartType type;

  const _HistoryChart({required this.readings, required this.type});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (final r in readings) {
      final value = type == _ChartType.temperature ? r.temperature : r.humidity;
      if (value != null) {
        spots.add(FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), value));
      }
    }

    if (spots.length < 2) {
      return Center(
        child: Text(
          'Not enough data to plot',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final color = type == _ChartType.temperature ? AppTheme.primary : AppTheme.warning;
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final span = maxX - minX;
    final xInterval = span > 0 ? span / 4 : 1.0;
    final useDateFormat = span > const Duration(days: 2).inMilliseconds;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final label = useDateFormat
                    ? DateFormat('dd/MM').format(dt)
                    : DateFormat('HH:mm').format(dt);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final dt = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)}\n${DateFormat('dd MMM HH:mm').format(dt)}',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            }).toList(),
          ),
        ),
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

// ── Ammonia Tier Timeline ──────────────────────────────────────────────────

class _AmmoniaTimeline extends StatelessWidget {
  final List<SensorReading> readings;

  const _AmmoniaTimeline({required this.readings});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: screenHeight * 0.035,
          child: Row(
            children: readings.map((r) {
              final color = AppTheme.ammoniaColor(
                r.ammonia,
                warmupActive: r.warmupActive,
              );
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: screenHeight * 0.012),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: const [
            _LegendItem(color: AppTheme.success, label: 'Normal'),
            _LegendItem(color: AppTheme.warning, label: 'Elevated'),
            _LegendItem(color: AppTheme.alert, label: 'Alert'),
            _LegendItem(color: AppTheme.textSecondary, label: 'No data'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}