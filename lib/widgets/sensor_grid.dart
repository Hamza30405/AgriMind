import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/metric_status.dart';
import 'metric_card.dart';

/// The five live sensor cards (soil moisture, temperature, air humidity, light and
/// soil salinity). Shared by the Overview and Monitoring pages so they always match.
class SensorGrid extends StatelessWidget {
  final Reading? reading;
  final Settings? settings;

  const SensorGrid({super.key, required this.reading, required this.settings});

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final s = settings;
    // Light and TDS are optional: null means "no such sensor / no value yet".
    final light = r?.light;
    final tds = r?.tds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850
            ? 3
            : constraints.maxWidth >= 500
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;

        final cards = <Widget>[
          MetricCard(
            title: 'Soil moisture',
            value: r == null ? '--' : r.soilMoisture.toStringAsFixed(0),
            unit: '%',
            icon: Icons.water_drop_rounded,
            status: r == null || s == null ? 'No data' : soilStatus(r.soilMoisture, s),
            color: const Color(0xFF6CB8FF),
            progress: r == null ? 0 : r.soilMoisture / 100,
          ),
          MetricCard(
            title: 'Temperature',
            value: r == null ? '--' : r.temperature.toStringAsFixed(1),
            unit: '°C',
            icon: Icons.thermostat_rounded,
            status: r == null || s == null ? 'No data' : temperatureStatus(r.temperature, s),
            color: const Color(0xFFFFB86C),
            progress: r == null ? 0 : r.temperature / 50,
          ),
          MetricCard(
            title: 'Air humidity',
            value: r == null ? '--' : r.humidity.toStringAsFixed(0),
            unit: '%',
            icon: Icons.cloud_outlined,
            status: r == null ? 'No data' : humidityStatus(r.humidity),
            color: const Color(0xFFB9A0FF),
            progress: r == null ? 0 : r.humidity / 100,
          ),
          MetricCard(
            title: 'Light intensity',
            value: light == null ? '--' : light.toStringAsFixed(0),
            unit: '%',
            icon: Icons.wb_sunny_rounded,
            status: r == null ? 'No data' : lightStatus(light),
            color: const Color(0xFFFFD866),
            progress: light == null ? 0 : light / 100,
          ),
          MetricCard(
            title: 'Soil salinity (TDS)',
            value: tds == null ? '--' : tds.toStringAsFixed(0),
            unit: 'ppm',
            icon: Icons.science_rounded,
            status: r == null || s == null ? 'No data' : tdsStatus(tds, s),
            color: const Color(0xFF5EEAD4),
            progress: tds == null || s == null ? 0 : tds / s.tdsAlertPpm,
          ),
        ];

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [for (final c in cards) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}
