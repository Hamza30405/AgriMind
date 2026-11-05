import 'package:flutter/material.dart';

const String kAppName = 'AgriMind';
const String kAppVersion = '3.2.0';

/// Your server address. Set it once here, or build with
/// `--dart-define=API_URL=https://your-domain.com`. It can also be changed from the
/// "Server settings" button on the sign-in screen (for local testing).
const String kDefaultServerUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://agrimind.example.com',
);

// ---- colors ----
const Color background = Color(0xFF07150E);
const Color surface = Color(0xFF0F1D15);
const Color borderColor = Color(0xFF25392C);
const Color green = Color(0xFF4ADE80);
const Color muted = Color(0xFF8FA597);
const Color warning = Color(0xFFFFB86C);
const Color danger = Color(0xFFFF6B6B);
const Color infoBlue = Color(0xFF6CB8FF);
