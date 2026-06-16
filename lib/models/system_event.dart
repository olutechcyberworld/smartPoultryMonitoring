class SystemEvent {
  final String deviceId;
  final DateTime timestamp;
  final String sensorId;   // "AHT21" | "MQ135"
  final String eventType;  // "FAILURE" | "RECOVERY"

  const SystemEvent({
    required this.deviceId,
    required this.timestamp,
    required this.sensorId,
    required this.eventType,
  });

  factory SystemEvent.fromMap(Map<String, dynamic> map) {
    return SystemEvent(
      deviceId: map['device_id'] as String,
      timestamp: DateTime.parse(map['timestamp_utc'] as String),
      sensorId: map['sensor_id'] as String,
      eventType: map['event_type'] as String,
    );
  }

  @override
  String toString() =>
      'SystemEvent(deviceId: $deviceId, sensorId: $sensorId, '
      'eventType: $eventType, timestamp: $timestamp)';
}