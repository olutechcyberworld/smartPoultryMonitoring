import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/system_event.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/providers/device_status_provider.dart';
import 'package:poultri_sense/models/device_status.dart';

/// All system events for the device, most recent first.
/// Reused by the Dashboard (last event card) and Events screen (full log).
final systemEventsProvider = FutureProvider<List<SystemEvent>>((ref) async {
  final deviceId = ref.watch(deviceProvider).deviceId;
  if (deviceId == null) return [];

  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.fetchSystemEvents(deviceId);
});

/// Derived from systemEventsProvider — the single most recent event, if any.
final lastEventProvider = Provider<SystemEvent?>((ref) {
  final events = ref.watch(systemEventsProvider);
  return events.maybeWhen(
    data: (list) => list.isNotEmpty ? list.first : null,
    orElse: () => null,
  );
});

enum TimelineEntryType { sensorFailure, sensorRecovery, deviceOnline, deviceOffline }

class TimelineEntry {
  final DateTime timestamp;
  final String title;
  final TimelineEntryType type;

  const TimelineEntry({
    required this.timestamp,
    required this.title,
    required this.type,
  });
}

/// Merges sensor fault events and device connectivity history into a
/// single chronological feed — "what went wrong and when" (Section 6).
final eventTimelineProvider = FutureProvider<List<TimelineEntry>>((ref) async {
  final deviceId = ref.watch(deviceProvider).deviceId;
  if (deviceId == null) return [];

  final supabase = ref.watch(supabaseServiceProvider);

  final results = await Future.wait([
    supabase.fetchSystemEvents(deviceId),
    supabase.fetchDeviceStatusHistory(deviceId),
  ]);

  final systemEvents = results[0] as List<SystemEvent>;
  final statusEvents = results[1] as List<DeviceStatusEvent>;

  final entries = <TimelineEntry>[
    for (final e in systemEvents)
      TimelineEntry(
        timestamp: e.timestamp,
        title: '${e.sensorId} ${e.eventType}',
        type: e.eventType == 'FAILURE'
            ? TimelineEntryType.sensorFailure
            : TimelineEntryType.sensorRecovery,
      ),
    for (final s in statusEvents)
      TimelineEntry(
        timestamp: s.timestamp,
        title: s.isOnline ? 'Device ONLINE' : 'Device OFFLINE',
        type: s.isOnline
            ? TimelineEntryType.deviceOnline
            : TimelineEntryType.deviceOffline,
      ),
  ];

  entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return entries;
});