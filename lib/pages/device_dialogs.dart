import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/format.dart';
import '../state/app_state.dart';

/// "Add a device": the owner types the 6-character code shown on the device's LCD.
Future<void> showAddDeviceDialog(BuildContext context, AppState state) async {
  final code = TextEditingController();
  final name = TextEditingController();
  String? error;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Add a device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Power on your AgriMind device. Its screen shows "Link in the app" and a '
                '6-character code. Type that code here.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: code,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Code', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  hintText: 'Tomato field',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: danger, fontSize: 13)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: state.busy
                ? null
                : () async {
                    final err = await state.claimDevice(code.text, name.text);
                    if (err != null) {
                      setLocal(() => error = err);
                    } else if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
            child: const Text('Link device'),
          ),
        ],
      ),
    ),
  );
  code.dispose();
  name.dispose();
}

Future<void> showRenameDeviceDialog(BuildContext context, AppState state) async {
  final controller = TextEditingController(text: state.device?.name ?? '');
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: surface,
      title: const Text('Rename device'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            final err = await state.renameDevice(controller.text);
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            if (err != null && context.mounted) showMessage(context, err, error: true);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
}

Future<void> showUnlinkDeviceDialog(BuildContext context, AppState state) async {
  final name = state.device?.name ?? 'this device';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: surface,
      title: const Text('Unlink device?'),
      content: Text(
        '"$name" will be removed from your account and all of its stored readings, alerts and '
        'history will be deleted. The device will show a new code so you can link it again.',
        style: const TextStyle(color: muted, height: 1.5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: danger),
          child: const Text('Unlink'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final err = await state.unlinkDevice();
  if (context.mounted) {
    showMessage(context, err ?? 'Device unlinked', error: err != null);
  }
}
