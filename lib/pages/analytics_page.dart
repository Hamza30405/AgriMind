import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../services/format.dart';
import '../state/app_state.dart';
import '../widgets/analytics_chart.dart';
import '../widgets/app_footer.dart';

class AnalyticsPage extends StatelessWidget {
  final AppState state;

  const AnalyticsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final history = state.history;
    final daily = state.daily;
    String dayLabel(DailySummary d) => d.date.length >= 10 ? d.date.substring(5) : d.date;
    final dayLabels = daily.map(dayLabel).toList();
    // light and TDS are optional: only chart the days that have values
    final lightDays = daily.where((d) => d.light != null).toList();
    final tdsDays = daily.where((d) => d.tds != null).toList();

    final charts = <Widget>[
      AnalyticsChart(
        title: 'Soil moisture · last 24 h',
        subtitle: '${history.length} readings',
        values: history.map((r) => r.soilMoisture).toList(),
        labels: history.map((r) => clock(r.time).substring(0, 5)).toList(),
        unit: '%',
        minY: 0,
        maxY: 100,
      ),
      AnalyticsChart(
        title: 'Soil moisture · daily average',
        subtitle: 'Last 7 days',
        values: daily.map((d) => d.soilMoisture.avg).toList(),
        labels: dayLabels,
        unit: '%',
        minY: 0,
        maxY: 100,
      ),
      AnalyticsChart(
        title: 'Temperature · daily average',
        subtitle: 'Last 7 days',
        values: daily.map((d) => d.temperature.avg).toList(),
        labels: dayLabels,
        unit: '°C',
      ),
      AnalyticsChart(
        title: 'Air humidity · daily average',
        subtitle: 'Last 7 days',
        values: daily.map((d) => d.humidity.avg).toList(),
        labels: dayLabels,
        unit: '%',
        minY: 0,
        maxY: 100,
      ),
      AnalyticsChart(
        title: 'Light · daily average',
        subtitle: lightDays.isEmpty ? 'No light data yet' : 'Last 7 days',
        values: lightDays.map((d) => d.light!.avg).toList(),
        labels: lightDays.map(dayLabel).toList(),
        unit: '%',
        minY: 0,
        maxY: 100,
      ),
      AnalyticsChart(
        title: 'Soil salinity (TDS) · daily average',
        subtitle: tdsDays.isEmpty ? 'No TDS data yet' : 'Last 7 days',
        values: tdsDays.map((d) => d.tds!.avg).toList(),
        labels: tdsDays.map(dayLabel).toList(),
        unit: ' ppm',
        minY: 0,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analytics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Trends from the data stored on your server.',
          style: TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 850 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [for (final c in charts) SizedBox(width: width, child: c)],
            );
          },
        ),
        const SizedBox(height: 28),
        const AppFooter(),
      ],
    );
  }
}
