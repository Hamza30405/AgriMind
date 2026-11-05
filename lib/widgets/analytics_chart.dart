import 'package:flutter/material.dart';

import '../constants.dart';

/// A small line chart (no extra packages). `labels` are shown under the first, middle and
/// last points. Pass `minY` / `maxY` to fix the vertical range (e.g. 0..100 for percent).
class AnalyticsChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final List<String> labels;
  final String unit;
  final double? minY;
  final double? maxY;

  const AnalyticsChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labels,
    required this.unit,
    this.minY,
    this.maxY,
  });

  static String format(double v, String unit) {
    final digits = (unit == '°C') ? 1 : 0;
    return '${v.toStringAsFixed(digits)}$unit';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = values.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
              if (hasData)
                Text(
                  format(values.last, unit),
                  style: const TextStyle(color: green, fontSize: 18, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: hasData
                ? CustomPaint(
                    size: Size.infinite,
                    painter: _ChartPainter(values: values, minY: minY, maxY: maxY, unit: unit),
                  )
                : const Center(child: Text('No data yet', style: TextStyle(color: muted, fontSize: 13))),
          ),
          if (hasData && labels.length == values.length && labels.length > 1) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(labels.first, style: const TextStyle(color: muted, fontSize: 10)),
                  if (labels.length > 2)
                    Text(labels[labels.length ~/ 2], style: const TextStyle(color: muted, fontSize: 10)),
                  Text(labels.last, style: const TextStyle(color: muted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> values;
  final double? minY;
  final double? maxY;
  final String unit;

  _ChartPainter({required this.values, required this.minY, required this.maxY, required this.unit});

  static const double _leftPad = 44; // room for the y-axis labels

  @override
  void paint(Canvas canvas, Size size) {
    var lo = minY ?? values.reduce((a, b) => a < b ? a : b);
    var hi = maxY ?? values.reduce((a, b) => a > b ? a : b);
    if (minY == null || maxY == null) {
      // a little air above and below when the range is automatic
      final pad = (hi - lo).abs() < 0.001 ? 1.0 : (hi - lo) * 0.15;
      if (minY == null) lo -= pad;
      if (maxY == null) hi += pad;
    }
    if (hi - lo < 0.001) hi = lo + 1;

    final chart = Rect.fromLTWH(_leftPad, 6, size.width - _leftPad, size.height - 12);

    final grid = Paint()
      ..color = borderColor
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final t = i / 2;
      final y = chart.top + chart.height * t;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      final v = hi - (hi - lo) * t;
      _text(canvas, v.toStringAsFixed((hi - lo) < 10 ? 1 : 0), Offset(0, y - 6), _leftPad - 6);
    }

    Offset point(int i) {
      final x = values.length == 1 ? chart.center.dx : chart.left + chart.width * i / (values.length - 1);
      final y = chart.bottom - chart.height * ((values[i] - lo) / (hi - lo)).clamp(0.0, 1.0);
      return Offset(x, y);
    }

    if (values.length == 1) {
      canvas.drawCircle(point(0), 4, Paint()..color = green);
      return;
    }

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(chart.right, chart.bottom)
      ..lineTo(chart.left, chart.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [green.withValues(alpha: 0.28), green.withValues(alpha: 0.0)],
        ).createShader(chart),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(point(values.length - 1), 4, Paint()..color = green);
  }

  void _text(Canvas canvas, String text, Offset at, double width) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: muted, fontSize: 10)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.values != values || old.minY != minY || old.maxY != maxY || old.unit != unit;
}
