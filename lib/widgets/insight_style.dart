import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/insights.dart';

String insightLabel(InsightLevel level) {
  switch (level) {
    case InsightLevel.good:
      return 'Good';
    case InsightLevel.info:
      return 'Info';
    case InsightLevel.warning:
      return 'Warning';
    case InsightLevel.critical:
      return 'Critical';
  }
}

IconData insightIcon(InsightLevel level) {
  switch (level) {
    case InsightLevel.good:
      return Icons.check_circle_rounded;
    case InsightLevel.info:
      return Icons.info_rounded;
    case InsightLevel.warning:
      return Icons.warning_amber_rounded;
    case InsightLevel.critical:
      return Icons.error_rounded;
  }
}

Color insightColor(InsightLevel level) {
  switch (level) {
    case InsightLevel.good:
      return green;
    case InsightLevel.info:
      return infoBlue;
    case InsightLevel.warning:
      return warning;
    case InsightLevel.critical:
      return danger;
  }
}
