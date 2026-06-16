import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/config/app_config.dart';
import 'package:poultri_sense/models/device_status.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/services/mqtt_service.dart';
import 'package:poultri_sense/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class DeviceStatusNotifier extends StateNotifier<DeviceStatus> {
  final SupabaseService _supabase;
  final String? _deviceId;
  StreamSubscription? _subscription;

  DeviceStatusNotifier({
    required SupabaseService supabase,
    required String? deviceId,        // public name in constructor
    required MqttService? mqttService,
  })  : _supabase = supabase,
        _deviceId = deviceId,         // assigned in initializer list
        super(DeviceStatus.connecting) {
    _initialize(mqttService);
  }

  Future<void> _initialize(MqttService? mqttService) async {
    // Assign field to local variable — Dart flow analysis promotes
    // local variables to non-null after null check, not fields.
    final deviceId = _deviceId;
    if (deviceId == null) {
      state = DeviceStatus.offline;
      return;
    }

    try {
      state = await _supabase.fetchLatestDeviceStatus(deviceId);
    } catch (_) {
      state = DeviceStatus.offline;
    }

    if (mqttService != null) {
      final topic = '${AppConfig.mqttPrefix}/$deviceId/status';
      _subscription = mqttService.messages
          .where((msg) => msg.topic == topic)
          .listen((msg) {
        state = msg.payload == 'online'
            ? DeviceStatus.online
            : DeviceStatus.offline;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final deviceStatusProvider =
    StateNotifierProvider<DeviceStatusNotifier, DeviceStatus>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  final deviceId = ref.watch(deviceProvider).deviceId;
  final supabase = ref.watch(supabaseServiceProvider);

  return DeviceStatusNotifier(
    supabase: supabase,
    deviceId: deviceId,
    mqttService: mqtt,
  );
});