import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/config/app_config.dart';
import 'package:poultri_sense/models/relay_state.dart';
import 'package:poultri_sense/models/telemetry.dart';
import 'package:poultri_sense/providers/device_provider.dart';
import 'package:poultri_sense/providers/telemetry_provider.dart';
import 'package:poultri_sense/services/mqtt_service.dart';

class RelayNotifier extends StateNotifier<RelayChannelState> {
  final int channel;
  final MqttService? _mqtt;
  final String _deviceId;
  final Ref _ref;

  Timer? _pendingTimer;
  StreamSubscription? _overrideSubscription;
  ProviderSubscription? _telemetrySubscription;

  RelayNotifier({
    required this.channel,
    required MqttService? mqtt,
    required String deviceId,
    required Ref ref,
  })  : _mqtt = mqtt,
        _deviceId = deviceId,
        _ref = ref,
        super(RelayChannelState.initial(channel)) {
    if (mqtt != null) _listenToOverrideTopic(mqtt);
    _listenToTelemetry();
  }

  void _listenToOverrideTopic(MqttService mqtt) {
    final topic =
        '${AppConfig.mqttPrefix}/$_deviceId/override/relay$channel';
    _overrideSubscription = mqtt.messages
        .where((msg) => msg.topic == topic)
        .listen(_onOverrideConfirmed);
  }

  /// In AUTO mode, the physical relay state is system-driven and arrives
  /// via telemetry.relayStates — the app cannot determine it any other way.
  /// In MANUAL/PENDING, telemetry updates are ignored — the user's last
  /// command is the source of truth until released back to AUTO.
  void _listenToTelemetry() {
    _telemetrySubscription =
        _ref.listen<AsyncValue<SensorReading>>(telemetryProvider, (prev, next) {
      if (state.mode != RelayMode.auto) return;

      final states = next.valueOrNull?.relayStates;
      if (states == null || states.length < 4) return;

      state = state.copyWith(isOn: states[channel - 1]);
    });
  }

  void _onOverrideConfirmed(MqttTopicMessage msg) {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    final mode =
        msg.payload == 'MANUAL' ? RelayMode.manual : RelayMode.auto;
    state = state.copyWith(mode: mode);
  }

  void requestManualOverride() {
    if (_mqtt == null || state.mode == RelayMode.manual) return;

    _mqtt.publishRelayOverride(channel, 'MANUAL');
    state = state.copyWith(mode: RelayMode.pending);

    _pendingTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(mode: RelayMode.auto, timedOut: true);
      _pendingTimer = null;
    });
  }

  void releaseToAuto() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _mqtt?.publishRelayOverride(channel, 'AUTO');
    state = state.copyWith(mode: RelayMode.auto);
  }

  void setRelayOn(bool on) {
    if (_mqtt == null || state.mode != RelayMode.manual) return;
    _mqtt.publishRelayControl(channel, on ? 'ON' : 'OFF');
    state = state.copyWith(isOn: on);
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _overrideSubscription?.cancel();
    _telemetrySubscription?.close();
    super.dispose();
  }
}

final relayProvider = StateNotifierProvider.family<RelayNotifier,
    RelayChannelState, int>((ref, channel) {
  final mqtt = ref.watch(mqttServiceProvider);
  final deviceId = ref.watch(deviceProvider).deviceId ?? '';

  return RelayNotifier(
    channel: channel,
    mqtt: mqtt,
    deviceId: deviceId,
    ref: ref,
  );
});