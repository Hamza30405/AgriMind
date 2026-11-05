import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../services/format.dart';
import '../state/app_state.dart';
import '../widgets/app_footer.dart';

class AlertsPage extends StatelessWidget {
  final AppState state;

  const AlertsPage({super.key, required this.state});

  Color _color(String severity) {
    switch (severity) {
      case 'critical':
        return danger;
      case 'warning':
        return warning;
      default:
        return infoBlue;
    }
  }

  IconData _icon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _ack(BuildContext context, {List<int>? ids}) async {
    final err = await state.ackAlerts(ids: ids);
    if (context.mounted && err != null) showMessage(context, err, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final alerts = state.alerts;
    final unacked = alerts.where((a) => !a.acked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alerts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Problems found by the server, such as dry soil, heat, salinity or an offline device.',
          style: TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (unacked > 0)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              onPressed: state.busy ? null : () => _ack(context),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all as read'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: borderColor),
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (alerts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: green, size: 40),
                SizedBox(height: 12),
                Text('No alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Everything looks fine.', style: TextStyle(color: muted, fontSize: 13)),
              ],
            ),
          )
        else
          for (final a in alerts) Padding(padding: const EdgeInsets.only(bottom: 10), child: _tile(context, a)),
        const SizedBox(height: 18),
        const AppFooter(),
      ],
    );
  }

  Widget _tile(BuildContext context, AlertItem a) {
    final c = _color(a.severity);
    return Opacity(
      opacity: a.acked ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: a.acked ? borderColor : c.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon(a.severity), color: c, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.message, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 6),
                  Text(
                    '${timeAgo(a.time)} · ${dateTime(a.time)}',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!a.acked)
              IconButton(
                tooltip: 'Mark as read',
                onPressed: state.busy ? null : () => _ack(context, ids: [a.id]),
                icon: const Icon(Icons.check_rounded, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}
