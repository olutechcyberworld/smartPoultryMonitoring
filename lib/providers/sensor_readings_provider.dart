import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/telemetry.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/providers/device_status_provider.dart';

/// Most recent N readings, most-recent-first — for the readings table
/// and trend sparklines on the Sensor Readings screen.
final recentReadingsProvider = FutureProvider<List<SensorReading>>((ref) async {
  final deviceId = ref.watch(deviceProvider).deviceId;
  if (deviceId == null) return [];

  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.fetchRecentReadings(deviceId, limit: 50);
});