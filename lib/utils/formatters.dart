import 'package:intl/intl.dart';

String formatTemperature(double? value) =>
    value != null ? '${value.toStringAsFixed(1)}°C' : '—';

String formatHumidity(double? value) =>
    value != null ? '${value.toStringAsFixed(1)}%' : '—';

String formatAmmonia(String? value, {required bool warmupActive}) {
  if (warmupActive) return 'WARMING UP';
  if (value == null) return '— (sensor error)';
  return value;
}

String formatTimestamp(DateTime? value) => value != null
    ? DateFormat('dd MMM yyyy  HH:mm:ss').format(value.toLocal())
    : '—';

String formatRelayMode(String mode) {
  switch (mode) {
    case 'MANUAL':
      return 'MANUAL';
    case 'PENDING':
      return '···';
    default:
      return 'AUTO';
  }
}