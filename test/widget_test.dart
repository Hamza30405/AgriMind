import 'package:flutter_test/flutter_test.dart';

import 'package:agrimind_ai/models/models.dart';
import 'package:agrimind_ai/services/format.dart';
import 'package:agrimind_ai/services/insights.dart';
import 'package:agrimind_ai/services/metric_status.dart';

const _settings = Settings(
  mode: 'manual',
  lowThreshold: 30,
  highThreshold: 60,
  maxPumpMinutes: 10,
  cooldownMinutes: 5,
  lowAlertSoil: 20,
  tempAlertC: 40,
  tdsAlertPpm: 1000,
);

void main() {
  test('timeAgo', () {
    final now = DateTime.now();
    expect(timeAgo(now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5))), '5 min ago');
    expect(timeAgo(now.subtract(const Duration(hours: 3))), '3 h ago');
  });

  test('clock is HH:mm:ss', () {
    expect(clock(DateTime(2026, 1, 1, 7, 5, 9)), '07:05:09');
  });

  test('soil status follows the settings', () {
    expect(soilStatus(10, _settings), 'Critically dry');
    expect(soilStatus(25, _settings), 'Needs attention');
    expect(soilStatus(45, _settings), 'Optimal');
    expect(soilStatus(80, _settings), 'Well watered');
  });

  test('insights without data', () {
    final out = buildInsights(null, const []);
    expect(out.single.level, InsightLevel.info);
  });
}
