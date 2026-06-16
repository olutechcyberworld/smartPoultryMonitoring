enum DeviceStatus { connecting, online, offline }

/// A single connectivity transition from device_status history.
class DeviceStatusEvent {
  final DateTime timestamp;
  final bool isOnline;

  const DeviceStatusEvent({required this.timestamp, required this.isOnline});

  factory DeviceStatusEvent.fromMap(Map<String, dynamic> map) {
    return DeviceStatusEvent(
      timestamp: DateTime.parse(map['timestamp_utc'] as String),
      isOnline: map['is_online'] as bool,
    );
  }
}