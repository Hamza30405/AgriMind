import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../services/insights.dart' show formatDuration;

/// Pump on/off switch with the reason it may be disabled.
class PumpCard extends StatelessWidget {
  final PumpState? pump;
  final bool online;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const PumpCard({
    super.key,
    required this.pump,
    required this.online,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = pump;
    final on = p?.enabled ?? false;

    // Turning OFF is always allowed. Turning ON needs: device online, manual mode, no rest period.
    String? blocked;
    if (p == null) {
      blocked = 'Waiting for the device status.';
    } else if (!on) {
      if (!online) {
        blocked = 'The device is offline, so the pump cannot be started.';
      } else if (p.isAuto) {
        blocked = 'Auto mode controls the pump. Switch to manual mode to start it yourself.';
      } else if (p.cooldownRemainingSeconds > 0) {
        blocked = 'The pump is resting. It can start again in ${formatDuration(p.cooldownRemainingSeconds)}.';
      }
    }
    final canToggle = p != null && !busy && (on || blocked == null);

    String detail;
    if (p == null) {
      detail = 'No data yet.';
    } else if (on) {
      detail = 'Running for ${formatDuration(p.runningSeconds)}. '
          'It stops by itself in ${formatDuration(p.remainingSeconds)} at the latest.';
    } else {
      detail = blocked ?? 'The pump is off.';
    }

    final accent = on ? green : muted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on ? green.withValues(alpha: 0.6) : borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.water_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Water pump', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        on ? 'ON' : 'OFF',
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(detail, style: const TextStyle(color: muted, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Switch(
                  value: on,
                  activeThumbColor: green,
                  onChanged: canToggle ? onChanged : null,
                ),
        ],
      ),
    );
  }
}
