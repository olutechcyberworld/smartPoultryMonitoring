import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poultri_sense/services/mqtt_service.dart';

// ── Device State ─────────────────────────────────────────────────────────────

class DeviceState {
  final String? deviceId;
  final bool isInitialized; // false until SharedPreferences read completes

  const DeviceState({
    this.deviceId,
    required this.isInitialized,
  });

  bool get isSetupComplete => deviceId != null;
}

class DeviceNotifier extends StateNotifier<DeviceState> {
  DeviceNotifier() : super(const DeviceState(isInitialized: false));

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('device_id');
    state = DeviceState(deviceId: id, isInitialized: true);
  }

  Future<void> setDeviceId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_id', id);
    state = DeviceState(deviceId: id, isInitialized: true);
  }

  Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('device_id');
    state = const DeviceState(isInitialized: true);
  }
}

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  return DeviceNotifier();
});

// ── MQTT Service Provider ─────────────────────────────────────────────────────
// Lives here because it is the first consumer of deviceProvider.
// All other providers that need MqttService import from this file.

final mqttServiceProvider = Provider<MqttService?>((ref) {
  final deviceId = ref.watch(deviceProvider).deviceId;
  if (deviceId == null) return null;

  final service = MqttService(deviceId: deviceId);
  ref.onDispose(() => service.dispose());

  // Connect in background — never block provider creation
  Future.microtask(() => service.connect());

  return service;
});