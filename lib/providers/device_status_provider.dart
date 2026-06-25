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
    required String? deviceId, // public name in constructor
    required MqttService? mqttService,
  }) : _supabase = supabase,
       _deviceId = deviceId, // assigned in initializer list
       super(DeviceStatus.connecting) {
    _initialize(mqttService);
  }

  Future<void> _initialize(MqttService? mqttService) async {
    final deviceId = _deviceId;
    if (deviceId == null) {
      state = DeviceStatus.offline;
      return;
    }

    // Always start as connecting — Supabase seed is historical,
    // not a live confirmation of current connection state.
    state = DeviceStatus.connecting;

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

    // Supabase seed now only used for initial display while MQTT hasn't
    // delivered a status message yet — shown as a fallback, not authority.
    try {
      final seeded = await _supabase.fetchLatestDeviceStatus(deviceId);
      // Only apply seed if MQTT hasn't already delivered a live update.
      // If state has moved off 'connecting', MQTT has already spoken — don't overwrite.
      if (state == DeviceStatus.connecting) {
        state = seeded;
      }
    } catch (_) {
      if (state == DeviceStatus.connecting) {
        state = DeviceStatus.offline;
      }
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
