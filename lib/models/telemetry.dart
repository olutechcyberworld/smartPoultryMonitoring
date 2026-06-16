class SensorReading {
  final double? temperature;
  final double? humidity;
  final String? ammonia;
  final bool warmupActive;
  final List<bool>? relayStates; // index 0-3 = relay1-4; null if firmware doesn't send it
  final DateTime timestamp;

  const SensorReading({
    this.temperature,
    this.humidity,
    this.ammonia,
    required this.warmupActive,
    this.relayStates,
    required this.timestamp,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      ammonia: json['ammonia'] as String?,
      warmupActive: json['warmupActive'] as bool? ?? false,
      relayStates: (json['relayStates'] as List?)?.cast<bool>(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      temperature: (map['temperature'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
      ammonia: map['ammonia'] as String?,
      warmupActive: map['warmupActive'] as bool? ?? false,
      timestamp: DateTime.parse(map['timestamp_utc'] as String),
      // relayStates intentionally absent — not persisted to Supabase
    );
  }
}