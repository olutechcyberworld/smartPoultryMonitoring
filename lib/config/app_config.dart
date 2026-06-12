/// Application-wide configuration.
/// Values are injected at compile time via `--dart-define-from-file=.env`.
class AppConfig {
  // MQTT Configuration
  static const String mqttPrefix = "poultryMonitoring";
  static const String mqttBroker = String.fromEnvironment('MQTT_BROKER');
  static const int mqttPort = int.fromEnvironment('MQTT_PORT', defaultValue: 8883);
  static const String mqttUser = String.fromEnvironment('MQTT_USER');
  static const String mqttPass = String.fromEnvironment('MQTT_PASS');

  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}