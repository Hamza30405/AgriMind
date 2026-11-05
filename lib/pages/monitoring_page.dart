import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/format.dart';
import '../state/app_state.dart';
import '../widgets/app_footer.dart';
import '../widgets/info_card.dart';
import '../widgets/sensor_grid.dart';

class MonitoringPage extends StatelessWidget {
  final AppState state;

  const MonitoringPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final r = status?.latest;
    final settings = status?.settings;
    final online = status?.online ?? false;
    final recent = state.history.reversed.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monitoring', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Live sensor data from your ESP32.',
          style: TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        InfoCard(
          title: 'Device status',
          value: status == null ? 'Unknown' : (online ? 'Online' : 'Offline'),
          description: status?.lastSeen == null
              ? 'No report received yet.'
              : 'Last report ${timeAgo(status!.lastSeen!)}. '
                  'Pump relay reported ${status.pump.reported == null ? 'unknown' : (status.pump.reported! ? 'ON' : 'OFF')}.',
          icon: online ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          accent: status == null ? muted : (online ? green : warning),
        ),
        const SizedBox(height: 18),
        SensorGrid(reading: r, settings: settings),
        const SizedBox(height: 26),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recent readings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              if (recent.isEmpty)
                const Text('No readings yet.', style: TextStyle(color: muted, fontSize: 13))
              else ...[
                const _Row(
                  cells: ['TIME', 'SOIL', 'TEMP', 'HUM', 'LIGHT', 'TDS'],
                  header: true,
                ),
                const Divider(color: borderColor, height: 18),
                for (final x in recent)
                  _Row(
                    cells: [
                      clock(x.time),
                      '${x.soilMoisture.toStringAsFixed(0)}%',
                      '${x.temperature.toStringAsFixed(1)}°',
                      '${x.humidity.toStringAsFixed(0)}%',
                      x.light == null ? '--' : '${x.light!.toStringAsFixed(0)}%',
                      x.tds == null ? '--' : x.tds!.toStringAsFixed(0),
                    ],
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        const AppFooter(),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.cells, this.header = false});

  /// time, soil, temp, humidity, light, tds (in this order)
  final List<String> cells;
  final bool header;

  // time column is wider; the other five share the rest equally
  static const _flex = [3, 2, 2, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: header ? muted : Colors.white,
      fontSize: header ? 10 : 12,
      letterSpacing: header ? 1 : 0,
      fontWeight: header ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              // six columns on a phone are tight: shrink the text instead of wrapping it
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(cells[i], maxLines: 1, softWrap: false, style: style),
              ),
            ),
        ],
      ),
    );
  }
}
