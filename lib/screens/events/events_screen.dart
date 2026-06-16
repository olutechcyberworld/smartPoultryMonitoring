import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/providers/events_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';
import 'package:poultri_sense/utils/formatters.dart';
import 'package:poultri_sense/widgets/offline_banner.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(eventTimelineProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'No events recorded',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(eventTimelineProvider),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.02,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _TimelineRow(entry: entries[index]),
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

class _TimelineRow extends StatelessWidget {
  final TimelineEntry entry;

  const _TimelineRow({required this.entry});

  (IconData, Color) _iconAndColor(TimelineEntryType type) {
    switch (type) {
      case TimelineEntryType.sensorFailure:
        return (Icons.error_outline, AppTheme.alert);
      case TimelineEntryType.sensorRecovery:
        return (Icons.check_circle_outline, AppTheme.success);
      case TimelineEntryType.deviceOnline:
        return (Icons.cloud_done, AppTheme.success);
      case TimelineEntryType.deviceOffline:
        return (Icons.cloud_off, AppTheme.alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor(entry.type);
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.025),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  formatTimestamp(entry.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}