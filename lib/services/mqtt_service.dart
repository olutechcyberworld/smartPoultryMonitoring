import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:poultri_sense/config/app_config.dart';

/// A single decoded message from the broker.
class MqttTopicMessage {
  final String topic;
  final String payload;

  const MqttTopicMessage({required this.topic, required this.payload});
}

class MqttService {
  final String deviceId;

  late final MqttServerClient _client;
  final _messageController = StreamController<MqttTopicMessage>.broadcast();

  bool _intentionalDisconnect = false;
  bool _reconnecting = false;
  bool _messageListenerRegistered = false;
  int _reconnectAttempts = 0;

  MqttService({required this.deviceId}) {
    _client = MqttServerClient.withPort(
      AppConfig.mqttBroker,
      // Unique client ID per session — avoids broker rejection on rapid restarts
      'poultriSense_${deviceId}_${DateTime.now().millisecondsSinceEpoch}',
      AppConfig.mqttPort,
    );
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;
    _client.keepAlivePeriod = 30;
    _client.logging(on: false);
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_client.clientIdentifier)
        .startClean()
        .withWillTopic('${AppConfig.mqttPrefix}/$deviceId/status')
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain()
        .authenticateAs(AppConfig.mqttUser, AppConfig.mqttPass);
  }

  /// All incoming messages from the broker.
  /// Providers filter this stream by topic.
  Stream<MqttTopicMessage> get messages => _messageController.stream;

  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    if (isConnected) return;
    try {
      await _client.connect();
    } catch (_) {
      _client.disconnect();
    }
  }

  void _onConnected() {
    _reconnectAttempts = 0;
    _reconnecting = false;

    // Register the message listener once for the lifetime of this service.
    // Guard prevents double-registration across reconnects.
    if (!_messageListenerRegistered) {
      _client.updates!.listen(_onMessageArrived);
      _messageListenerRegistered = true;
    }

    // Override topics subscribed FIRST — broker delivers retained messages
    // immediately on subscribe, pre-populating relay state before any
    // user interaction is possible.
    for (int ch = 1; ch <= 4; ch++) {
      _client.subscribe(
        '${AppConfig.mqttPrefix}/$deviceId/override/relay$ch',
        MqttQos.atLeastOnce,
      );
    }

    // Remaining subscriptions
    _client.subscribe(
      '${AppConfig.mqttPrefix}/$deviceId/telemetry/sensors',
      MqttQos.atMostOnce,
    );
    _client.subscribe(
      '${AppConfig.mqttPrefix}/$deviceId/status',
      MqttQos.atLeastOnce,
    );
    _client.subscribe(
      '${AppConfig.mqttPrefix}/$deviceId/events',
      MqttQos.atLeastOnce,
    );
  }

  void _onDisconnected() {
    if (_intentionalDisconnect || _reconnecting) return;
    _startReconnectLoop();
  }

  Future<void> _startReconnectLoop() async {
    _reconnecting = true;
    const delays = [0, 2, 4]; // seconds; 8s thereafter

    while (!_intentionalDisconnect) {
      final delay = _reconnectAttempts < delays.length
          ? delays[_reconnectAttempts]
          : 8;
      _reconnectAttempts++;

      if (delay > 0) await Future.delayed(Duration(seconds: delay));
      if (_intentionalDisconnect) break;

      try {
        await _client.connect();
        break; // _onConnected fires inside connect() — exit loop on success
      } on Exception {
        // Connection failed — loop continues with next delay
      }
    }
    _reconnecting = false;
  }

  void _onMessageArrived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final published = msg.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        published.payload.message,
      );
      _messageController.add(
        MqttTopicMessage(topic: msg.topic, payload: payload),
      );
    }
  }

  void publishRelayControl(int channel, String value) {
    assert(
      channel >= 1 && channel <= 4,
      'Relay channel must be between 1 and 4',
    );
    _publishRaw(
      topic: '${AppConfig.mqttPrefix}/$deviceId/control/relay$channel',
      payload: value,
      qos: MqttQos.atLeastOnce,
      retain: false,
    );
  }

  void publishRelayOverride(int channel, String value) {
    assert(
      channel >= 1 && channel <= 4,
      'Relay channel must be between 1 and 4',
    );
    _publishRaw(
      topic: '${AppConfig.mqttPrefix}/$deviceId/override/relay$channel',
      payload: value,
      qos: MqttQos.atLeastOnce,
      retain: true, // retained — reconnecting clients recover state immediately
    );
  }

  void _publishRaw({
    required String topic,
    required String payload,
    required MqttQos qos,
    required bool retain,
  }) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  void dispose() {
    _intentionalDisconnect = true;
    _client.disconnect();
    _messageController.close();
  }
}
