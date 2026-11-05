import '../models/models.dart';

String soilStatus(double v, Settings s) {
  if (v < s.lowAlertSoil) return 'Critically dry';
  if (v < s.lowThreshold) return 'Needs attention';
  if (v > s.highThreshold) return 'Well watered';
  return 'Optimal';
}

String temperatureStatus(double v, Settings s) {
  if (v >= s.tempAlertC) return 'Too hot';
  if (v >= 30) return 'Warm conditions';
  if (v < 15) return 'Cool conditions';
  return 'Comfortable';
}

String humidityStatus(double v) {
  if (v < 30) return 'Dry air';
  if (v > 70) return 'Humid air';
  return 'Comfortable';
}

String lightStatus(double? v) {
  if (v == null) return 'No sensor data';
  if (v < 10) return 'Dark';
  if (v < 35) return 'Dim light';
  if (v < 70) return 'Moderate light';
  return 'Bright light';
}

/// TDS of the soil probe, in ppm. Rough guide: under 450 is low, above your alert
/// level (default 1000) is high.
String tdsStatus(double? v, Settings s) {
  if (v == null) return 'No sensor data';
  if (v >= s.tdsAlertPpm) return 'High salinity';
  if (v >= 450) return 'Moderate salinity';
  return 'Low salinity';
}
