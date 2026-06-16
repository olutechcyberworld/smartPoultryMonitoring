import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/telemetry.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/providers/device_status_provider.dart';

// ── History Query ─────────────────────────────────────────────────────────────

class HistoryQuery {
  final DateTime from;
  final DateTime to;

  const HistoryQuery({required this.from, required this.to});

  Duration get _range => to.difference(from);

  /// Returns null for raw query (≤ 1hr), interval string for bucketed query.
  String? get bucketInterval {
    if (_range <= const Duration(hours: 1)) return null;
    if (_range <= const Duration(hours: 24)) return '5 minutes';
    if (_range <= const Duration(days: 7)) return '30 minutes';
    return '2 hours';
  }

  @override
  bool operator ==(Object other) =>
      other is HistoryQuery && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

// ── History Provider ──────────────────────────────────────────────────────────

final historyProvider =
    FutureProvider.family<List<SensorReading>, HistoryQuery>(
  (ref, query) async {
    final deviceId = ref.watch(deviceProvider).deviceId;
    if (deviceId == null) return [];

    final supabase = ref.watch(supabaseServiceProvider);
    final bucket = query.bucketInterval;

    if (bucket == null) {
      return supabase.fetchRawReadings(
        deviceId: deviceId,
        from: query.from,
        to: query.to,
      );
    }

    return supabase.fetchBucketedReadings(
      deviceId: deviceId,
      from: query.from,
      to: query.to,
      bucketInterval: bucket,
    );
  },
);