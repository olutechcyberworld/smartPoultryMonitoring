class AppConfig {
  // MQTT
  static const String mqttBroker = String.fromEnvironment('MQTT_BROKER');
  static const int mqttPort = 8883;
  static const String mqttUser = String.fromEnvironment('MQTT_USER');
  static const String mqttPass = String.fromEnvironment('MQTT_PASS');
  static const String mqttPrefix = 'poultryMonitoring';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // Validation — call once at app start, crashes loudly if .env is missing
  static void validate() {
    const required = {
      'MQTT_BROKER': mqttBroker,
      'MQTT_USER': mqttUser,
      'MQTT_PASS': mqttPass,
      'SUPABASE_URL': supabaseUrl,
      'SUPABASE_ANON_KEY': supabaseAnonKey,
    };

    final missing =
        required.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();

    if (missing.isNotEmpty) {
      throw StateError(
        'AppConfig: missing required environment variables: ${missing.join(', ')}.\n'
        'Run with: flutter run --dart-define-from-file=.env',
      );
    }
  }
}