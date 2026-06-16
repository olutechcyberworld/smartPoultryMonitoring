/// The three possible states for a relay channel.
/// 'pending' is a transitional state and should always
/// resolve to either 'auto' or 'manual'.
enum RelayMode {
  auto,
  manual,
  pending,
}

/// Represents the state of a single relay channel.
///
/// Channel mappings:
/// 1 -> Fan 1
/// 2 -> Fan 2
/// 3 -> Heater
/// 4 -> Mist Maker
///
/// This is a pure immutable value object.
/// Lifecycle concerns (Timers, retries, MQTT acknowledgements,
/// etc.) should be managed by the notifier/controller layer.
class RelayChannelState {
  final int channel;
  final String channelName;
  final RelayMode mode;
  final bool isOn;
  final bool timedOut;

  const RelayChannelState({
    required this.channel,
    required this.channelName,
    required this.mode,
    required this.isOn,
    this.timedOut = false,
  });

  static String nameForChannel(int channel) {
    switch (channel) {
      case 1:
        return 'Fan 1';
      case 2:
        return 'Fan 2';
      case 3:
        return 'Heater';
      case 4:
        return 'Mist Maker';
      default:
        throw ArgumentError('Invalid relay channel: $channel');
    }
  }

  static RelayChannelState initial(int channel) {
    return RelayChannelState(
      channel: channel,
      channelName: nameForChannel(channel),
      mode: RelayMode.auto,
      isOn: false,
    );
  }

  /// timedOut always resets to false unless explicitly set to true.
  /// This ensures the flag is only true for one state transition.
  RelayChannelState copyWith({
    RelayMode? mode,
    bool? isOn,
    bool timedOut = false,
  }) {
    return RelayChannelState(
      channel: channel,
      channelName: channelName,
      mode: mode ?? this.mode,
      isOn: isOn ?? this.isOn,
      timedOut: timedOut,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayChannelState &&
        other.channel == channel &&
        other.channelName == channelName &&
        other.mode == mode &&
        other.isOn == isOn &&
        other.timedOut == timedOut;
  }

  @override
  int get hashCode =>
      Object.hash(channel, channelName, mode, isOn, timedOut);

  @override
  String toString() {
    return 'RelayChannelState('
        'channel: $channel, '
        'channelName: $channelName, '
        'mode: $mode, '
        'isOn: $isOn, '
        'timedOut: $timedOut'
        ')';
  }
}