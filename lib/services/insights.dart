import '../models/models.dart';

enum InsightLevel { good, info, warning, critical }

class Insight {
  final InsightLevel level;
  final String title;
  final String text;
  const Insight(this.level, this.title, this.text);
}

/// Simple rule-based analysis of the live data. Not machine learning.
List<Insight> buildInsights(DeviceStatus? status, List<Reading> history) {
  if (status == null) {
    return const [
      Insight(InsightLevel.info, 'No data yet', 'Connect the app to your AgriMind server to see insights.'),
    ];
  }

  final out = <Insight>[];
  final s = status.settings;

  if (!status.online) {
    out.add(const Insight(
      InsightLevel.critical,
      'Device offline',
      'The ESP32 has stopped reporting. The pump is forced OFF until it reconnects.',
    ));
  }

  final r = status.latest;
  if (r == null) {
    out.add(const Insight(InsightLevel.info, 'Waiting for readings', 'No sensor readings have been received yet.'));
    return out;
  }

  // Soil moisture
  if (r.soilMoisture < s.lowAlertSoil) {
    out.add(Insight(
      InsightLevel.critical,
      'Soil is very dry',
      'Moisture is ${r.soilMoisture.toStringAsFixed(0)}%, below your alert level of '
          '${s.lowAlertSoil.toStringAsFixed(0)}%. Irrigate soon, or enable auto mode.',
    ));
  } else if (r.soilMoisture < s.lowThreshold) {
    out.add(Insight(
      InsightLevel.warning,
      'Soil moisture is low',
      'Moisture is ${r.soilMoisture.toStringAsFixed(0)}%, below the irrigation threshold of '
          '${s.lowThreshold.toStringAsFixed(0)}%.',
    ));
  } else if (r.soilMoisture > s.highThreshold) {
    out.add(Insight(
      InsightLevel.info,
      'Soil is well watered',
      'Moisture is ${r.soilMoisture.toStringAsFixed(0)}%. No irrigation is needed right now.',
    ));
  } else {
    out.add(Insight(
      InsightLevel.good,
      'Soil moisture is in range',
      'Moisture is ${r.soilMoisture.toStringAsFixed(0)}%, between your thresholds.',
    ));
  }

  // Temperature
  if (r.temperature >= s.tempAlertC) {
    out.add(Insight(
      InsightLevel.warning,
      'High temperature',
      '${r.temperature.toStringAsFixed(1)}°C. Water evaporates faster in this heat, so check the soil more often.',
    ));
  }

  // Soil salinity (TDS probe). Only when the device actually has the probe.
  final tds = r.tds;
  if (tds != null && tds >= s.tdsAlertPpm) {
    out.add(Insight(
      InsightLevel.warning,
      'High soil salinity',
      'TDS is ${tds.toStringAsFixed(0)} ppm, above your alert level of '
          '${s.tdsAlertPpm.toStringAsFixed(0)} ppm. Salt stresses the roots: use lower-salinity '
          'water and avoid over-fertilizing.',
    ));
  }

  // Humidity
  if (r.humidity < 25) {
    out.add(Insight(
      InsightLevel.info,
      'Very dry air',
      'Humidity is ${r.humidity.toStringAsFixed(0)}%. Expect faster water loss from leaves and soil.',
    ));
  }

  // Trend: compare the first and last third of the recent history.
  if (history.length >= 12) {
    final n = history.length ~/ 3;
    double avg(Iterable<Reading> xs) =>
        xs.map((e) => e.soilMoisture).reduce((a, b) => a + b) / xs.length;
    final before = avg(history.take(n));
    final after = avg(history.skip(history.length - n));
    final diff = after - before;
    if (diff <= -5) {
      out.add(Insight(
        InsightLevel.info,
        'Moisture is falling',
        'Soil moisture dropped about ${(-diff).toStringAsFixed(0)} points over the recent readings.',
      ));
    } else if (diff >= 5) {
      out.add(Insight(
        InsightLevel.info,
        'Moisture is rising',
        'Soil moisture rose about ${diff.toStringAsFixed(0)} points over the recent readings.',
      ));
    }
  }

  // Pump
  final p = status.pump;
  if (p.enabled) {
    out.add(Insight(
      InsightLevel.info,
      'Pump is running',
      'It will stop automatically in ${_fmt(p.remainingSeconds)} at the latest.',
    ));
  } else if (p.cooldownRemainingSeconds > 0) {
    out.add(Insight(
      InsightLevel.info,
      'Pump is resting',
      'It can start again in ${_fmt(p.cooldownRemainingSeconds)}.',
    ));
  }

  return out;
}

String _fmt(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return m > 0 ? '${m}m ${s.toString().padLeft(2, '0')}s' : '${s}s';
}

String formatDuration(int seconds) => _fmt(seconds);
