import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/format.dart';
import '../services/insights.dart';
import '../state/app_state.dart';
import '../widgets/app_footer.dart';
import '../widgets/info_card.dart';
import '../widgets/insight_style.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/pump_card.dart';

class OverviewPage extends StatelessWidget {
  final AppState state;
  final ValueChanged<int> onNavigate;

  const OverviewPage({super.key, required this.state, required this.onNavigate});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _togglePump(BuildContext context, bool on) async {
    final err = await state.setPump(on);
    if (context.mounted && err != null) showMessage(context, err, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final r = status?.latest;
    final settings = status?.settings;

    final insights = buildInsights(status, state.history);
    final top = insights.reduce((a, b) => a.level.index >= b.level.index ? a : b);

    final subtitle = state.lastUpdate == null
        ? 'Waiting for data…'
        : 'Live readings · updated ${timeAgo(state.lastUpdate!)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${_greeting()} 👋',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Here is your farm performance right now.',
          style: TextStyle(color: muted, fontSize: 14),
        ),
        const SizedBox(height: 28),
        _HeroCard(onNavigate: onNavigate),
        const SizedBox(height: 30),
        const Text(
          'Live environment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 18),
        SensorGrid(reading: r, settings: settings),
        const SizedBox(height: 30),
        InfoCard(
          title: 'Farm insight · ${insightLabel(top.level)}',
          value: top.title,
          description: top.text,
          icon: insightIcon(top.level),
          accent: insightColor(top.level),
        ),
        const SizedBox(height: 18),
        PumpCard(
          pump: status?.pump,
          online: status?.online ?? false,
          busy: state.busy,
          onChanged: (on) => _togglePump(context, on),
        ),
        const SizedBox(height: 28),
        const AppFooter(),
      ],
    );
  }
}

// ---------------- Hero Card ----------------

class _HeroCard extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _HeroCard({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 500;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(small ? 20 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF253D2B), Color(0xFF14231A), Color(0xFF101713)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A573B)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'SMART FARMING PLATFORM',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: green,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'Cultivate a\nsmarter future.',
                  style: TextStyle(
                    fontSize: compact ? 30 : 32,
                    height: 1.15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Monitor your crops, understand your environment, '
                'and make better farming decisions.',
                style: TextStyle(color: Color(0xFFB5C5B8), fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onNavigate(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: background,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    icon: const Icon(Icons.sensors_rounded, size: 18),
                    label: const Text('View Monitoring'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(3),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF506652)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Insights'),
                  ),
                ],
              ),
            ],
          );

          if (compact) return content;

          return Row(
            children: [
              Expanded(flex: 3, child: content),
              const SizedBox(width: 24),
              const Expanded(
                flex: 2,
                child: Center(child: Icon(Icons.eco_rounded, size: 150, color: green)),
              ),
            ],
          );
        },
      ),
    );
  }
}
