import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:poultri_sense/models/device_status.dart';
import 'package:poultri_sense/models/system_event.dart';
import 'package:poultri_sense/models/telemetry.dart';
// import 'package:poultri_sense/models/device_status.dart';

class SupabaseService {
  SupabaseClient get _db => Supabase.instance.client;

  // ── Device Status ──────────────────────────────────────────────────────────

  /// Seeds the initial device status on app open.
  /// MQTT subscription takes over for live updates after this.
  Future<DeviceStatus> fetchLatestDeviceStatus(String deviceId) async {
    final response = await _db
        .from('device_status')
        .select('is_online')
        .eq('device_id', deviceId)
        .order('timestamp_utc', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return DeviceStatus.offline;
    return (response['is_online'] as bool)
        ? DeviceStatus.online
        : DeviceStatus.offline;
  }

  // ── System Events ──────────────────────────────────────────────────────────

  /// Returns all system events for the device, most recent first.
  Future<List<SystemEvent>> fetchSystemEvents(String deviceId) async {
    final response = await _db
        .from('system_events')
        .select()
        .eq('device_id', deviceId)
        .order('timestamp_utc', ascending: false);

    return (response as List)
        .map((row) => SystemEvent.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ── Sensor Readings ────────────────────────────────────────────────────────

  /// Recent raw readings for the Sensor Readings screen.
  Future<List<SensorReading>> fetchRecentReadings(
    String deviceId, {
    int limit = 50,
  }) async {
    final response = await _db
        .from('sensor_readings')
        .select()
        .eq('device_id', deviceId)
        .order('timestamp_utc', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => SensorReading.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ── History ────────────────────────────────────────────────────────────────

  /// Raw readings for ranges ≤ 1 hour.
  Future<List<SensorReading>> fetchRawReadings({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _db
        .from('sensor_readings')
        .select()
        .eq('device_id', deviceId)
        .gte('timestamp_utc', from.toUtc().toIso8601String())
        .lte('timestamp_utc', to.toUtc().toIso8601String())
        .order('timestamp_utc', ascending: true);

    return (response as List)
        .map((row) => SensorReading.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Bucketed readings for ranges > 1 hour.
  /// Requires the get_bucketed_sensor_readings RPC function in Supabase.
  /// Bucket intervals: '5 minutes', '30 minutes', '2 hours'
  Future<List<SensorReading>> fetchBucketedReadings({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    required String bucketInterval,
  }) async {
    final response = await _db.rpc('get_bucketed_sensor_readings', params: {
      'p_device_id': deviceId,
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
      'p_bucket': bucketInterval,
    });

    return (response as List)
        .map((row) => SensorReading.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  /// Connectivity history — ONLINE/OFFLINE transitions, most recent first.
  Future<List<DeviceStatusEvent>> fetchDeviceStatusHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    final response = await _db
        .from('device_status')
        .select()
        .eq('device_id', deviceId)
        .order('timestamp_utc', ascending: false)
        .limit(limit);

    return (response as List)
        .map((row) => DeviceStatusEvent.fromMap(row as Map<String, dynamic>))
        .toList();
  }



}