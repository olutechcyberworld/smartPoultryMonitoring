import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/config/app_config.dart';
import 'package:poultri_sense/models/telemetry.dart';
import 'package:poultri_sense/providers/device_provider.dart';

final telemetryProvider = StreamProvider<SensorReading>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  if (mqtt == null) return const Stream.empty();

  final deviceId = ref.read(deviceProvider).deviceId!;
  final topic = '${AppConfig.mqttPrefix}/$deviceId/telemetry/sensors';

  return mqtt.messages
      .where((msg) => msg.topic == topic)
      .map((msg) {
        final json = jsonDecode(msg.payload) as Map<String, dynamic>;
        return SensorReading.fromJson(json);
      });
});