import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/models.dart';
import '../services/format.dart';
import '../state/app_state.dart';
import '../widgets/app_footer.dart';
import '../widgets/pump_card.dart';

class IrrigationPage extends StatefulWidget {
  final AppState state;

  const IrrigationPage({super.key, required this.state});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
  String _mode = 'manual';
  double _low = 30;
  double _high = 60;
  double _maxMin = 10;
  double _cool = 5;
  double _lowAlert = 20;
  double _temp = 40;
  double _tds = 1000;
  bool _dirty = false;

  void _load(Settings s) {
    _mode = s.mode;
    _low = s.lowThreshold;
    _high = s.highThreshold;
    _maxMin = s.maxPumpMinutes;
    _cool = s.cooldownMinutes;
    _lowAlert = s.lowAlertSoil;
    _temp = s.tempAlertC;
    _tds = s.tdsAlertPpm;
  }

  void _edit(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  Future<void> _togglePump(bool on) async {
    final err = await widget.state.setPump(on);
    if (mounted && err != null) showMessage(context, err, error: true);
  }

  Future<void> _save() async {
    final err = await widget.state.saveSettings({
      'mode': _mode,
      'lowThreshold': _low,
      'highThreshold': _high,
      'maxPumpMinutes': _maxMin,
      'cooldownMinutes': _cool,
      'lowAlertSoil': _lowAlert,
      'tempAlertC': _temp,
      'tdsAlertPpm': _tds,
    });
    if (!mounted) return;
    if (err != null) {
      showMessage(context, err, error: true);
    } else {
      setState(() => _dirty = false);
      showMessage(context, 'Settings saved');
    }
  }

  void _reset() {
    final s = widget.state.status?.settings;
    setState(() {
      if (s != null) _load(s);
      _dirty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final status = state.status;
        if (status != null && !_dirty) _load(status.settings);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Irrigation', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Control the pump and set the safety rules.',
              style: TextStyle(color: muted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            PumpCard(
              pump: status?.pump,
              online: status?.online ?? false,
              busy: state.busy,
              onChanged: _togglePump,
            ),
            const SizedBox(height: 18),
            _card(
              title: 'Mode',
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'manual', label: Text('Manual'), icon: Icon(Icons.touch_app_outlined)),
                    ButtonSegment(value: 'auto', label: Text('Auto'), icon: Icon(Icons.autorenew_rounded)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: status == null ? null : (s) => _edit(() => _mode = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: green.withValues(alpha: 0.15),
                    selectedForegroundColor: green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _mode == 'auto'
                      ? 'The pump starts when soil moisture drops below the low threshold and stops at the high threshold.'
                      : 'You start and stop the pump yourself.',
                  style: const TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Changing the mode switches the pump off.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              title: 'Auto irrigation range',
              children: [
                _valueLine('Start below ${_low.round()}%  ·  Stop at ${_high.round()}%'),
                RangeSlider(
                  values: RangeValues(_low, _high),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: green,
                  labels: RangeLabels('${_low.round()}%', '${_high.round()}%'),
                  onChanged: status == null
                      ? null
                      : (v) {
                          if (v.end - v.start < 5) return; // keep a gap so the pump does not flip constantly
                          _edit(() {
                            _low = v.start.roundToDouble();
                            _high = v.end.roundToDouble();
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              title: 'Pump safety',
              children: [
                _slider(
                  label: 'Maximum run time',
                  value: _maxMin,
                  min: 1,
                  max: 60,
                  divisions: 59,
                  unit: ' min',
                  onChanged: (v) => _edit(() => _maxMin = v),
                ),
                _slider(
                  label: 'Rest after a limit stop or auto cycle',
                  value: _cool,
                  min: 0,
                  max: 60,
                  divisions: 60,
                  unit: ' min',
                  onChanged: (v) => _edit(() => _cool = v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _card(
              title: 'Alert levels',
              children: [
                _slider(
                  label: 'Alert when soil moisture is below',
                  value: _lowAlert,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  unit: '%',
                  onChanged: (v) => _edit(() => _lowAlert = v),
                ),
                _slider(
                  label: 'Alert when temperature reaches',
                  value: _temp,
                  min: 25,
                  max: 60,
                  divisions: 35,
                  unit: '°C',
                  onChanged: (v) => _edit(() => _temp = v),
                ),
                _slider(
                  label: 'Alert when soil salinity (TDS) reaches',
                  value: _tds,
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  unit: ' ppm',
                  onChanged: (v) => _edit(() => _tds = v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _dirty && !state.busy ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save settings'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _dirty ? _reset : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _card(
              title: 'Pump history',
              children: [
                if (state.events.isEmpty)
                  const Text('No pump activity yet.', style: TextStyle(color: muted, fontSize: 13))
                else
                  for (final e in state.events.take(10)) _eventRow(e),
              ],
            ),
            const SizedBox(height: 28),
            const AppFooter(),
          ],
        );
      },
    );
  }

  // ---- small UI helpers ----

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _valueLine(String text) =>
      Text(text, style: const TextStyle(color: green, fontSize: 13, fontWeight: FontWeight.bold));

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    final enabled = widget.state.status != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 13))),
            Text('${value.round()}$unit',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: green,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  static const _sourceLabels = {
    'manual': 'Manual',
    'auto': 'Auto',
    'limit': 'Max run time reached',
    'offline': 'Device went offline',
    'system': 'System',
  };

  Widget _eventRow(PumpEvent e) {
    final on = e.action == 'on';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(on ? Icons.play_circle_outline_rounded : Icons.stop_circle_outlined,
              color: on ? green : muted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pump ${on ? 'ON' : 'OFF'} · ${_sourceLabels[e.source] ?? e.source}',
                    style: const TextStyle(fontSize: 13)),
                if (e.note != null)
                  Text(e.note!, style: const TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          Text(timeAgo(e.time), style: const TextStyle(color: muted, fontSize: 11)),
        ],
      ),
    );
  }
}
