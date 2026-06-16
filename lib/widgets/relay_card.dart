import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultri_sense/models/device_status.dart';
import 'package:poultri_sense/models/relay_state.dart';
import 'package:poultri_sense/providers/device_status_provider.dart';
import 'package:poultri_sense/providers/relay_provider.dart';
import 'package:poultri_sense/theme/app_theme.dart';

class RelayCard extends ConsumerWidget {
  final int channel;

  const RelayCard({required this.channel, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relay = ref.watch(relayProvider(channel));
    final isOffline = ref.watch(deviceStatusProvider) == DeviceStatus.offline;
    final screenWidth = MediaQuery.of(context).size.width;

    // Fires once when a pending override times out — shows the failure
    // SnackBar described in Section 8.5. Edge-triggered: only fires on the
    // false→true transition, not on every rebuild while timedOut is true.
    ref.listen(relayProvider(channel), (previous, next) {
      final justTimedOut = next.timedOut && !(previous?.timedOut ?? false);
      if (justTimedOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${next.channelName}: override failed — no response from device',
            ),
          ),
        );
      }
    });

    final switchDisabled = isOffline || relay.mode == RelayMode.pending;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  relay.channelName,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _ModeChip(mode: relay.mode),
              ],
            ),
            SizedBox(height: screenWidth * 0.035),

            // ── State / Control Row ───────────────────────────────────
            _buildStateRow(context, ref, relay, isOffline, screenWidth),

            SizedBox(height: screenWidth * 0.035),

            // ── Mode Toggle ────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'AUTO',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: relay.mode == RelayMode.auto
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
                Switch(
                  value: relay.mode != RelayMode.auto,
                  onChanged: switchDisabled
                      ? null
                      : (toManual) {
                          final notifier =
                              ref.read(relayProvider(channel).notifier);
                          if (toManual) {
                            notifier.requestManualOverride();
                          } else {
                            notifier.releaseToAuto();
                          }
                        },
                ),
                Text(
                  'MANUAL',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: relay.mode == RelayMode.manual
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(
    BuildContext context,
    WidgetRef ref,
    RelayChannelState relay,
    bool isOffline,
    double screenWidth,
  ) {
    if (relay.mode == RelayMode.pending) {
      return Row(
        children: [
          SizedBox(
            width: screenWidth * 0.04,
            height: screenWidth * 0.04,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: screenWidth * 0.03),
          Text(
            'Waiting for device confirmation…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    final stateLabel = relay.isOn ? 'ON' : 'OFF';
    final stateColor = AppTheme.relayModeColor(relay.isOn);
    final stateIcon = relay.isOn ? Icons.power : Icons.power_off;

    if (relay.mode == RelayMode.auto) {
      // AUTO: read-only, driven by telemetry.relayStates
      return Row(
        children: [
          Icon(stateIcon, color: stateColor),
          SizedBox(width: screenWidth * 0.02),
          Text(
            stateLabel,
            style: TextStyle(color: stateColor, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    // MANUAL: interactive ON/OFF toggle
    return Row(
      children: [
        Icon(stateIcon, color: stateColor),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            stateLabel,
            style: TextStyle(color: stateColor, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: isOffline
              ? null
              : () => ref
                  .read(relayProvider(channel).notifier)
                  .setRelayOn(!relay.isOn),
          child: Text(relay.isOn ? 'Turn OFF' : 'Turn ON'),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final RelayMode mode;

  const _ModeChip({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mode) {
      RelayMode.auto => ('AUTO', AppTheme.textSecondary),
      RelayMode.manual => ('MANUAL', AppTheme.primary),
      RelayMode.pending => ('···', AppTheme.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}