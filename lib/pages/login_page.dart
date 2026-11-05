import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/format.dart';
import '../state/app_state.dart';

/// Sign in / create account. The server address can be changed from here (for local tests).
class LoginPage extends StatefulWidget {
  final AppState state;

  const LoginPage({super.key, required this.state});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signup = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    final err = _signup
        ? await widget.state.signup(_email.text, _password.text, _name.text)
        : await widget.state.login(_email.text, _password.text);
    // on success the app switches to the main screen by itself
    if (mounted && err != null) setState(() => _error = err);
  }

  Future<void> _serverSettings() async {
    final controller = TextEditingController(text: widget.state.serverUrl);
    String? problem;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: surface,
          title: const Text('Server settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your AgriMind server address. Normally you never need to change this.',
                style: TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Server address',
                  hintText: 'https://your-domain.com',
                  errorText: problem,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final err = await widget.state.setServerUrl(controller.text);
                if (err != null) {
                  setLocal(() => problem = err);
                } else if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final busy = widget.state.busy;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.eco_rounded, size: 72, color: green),
                      const SizedBox(height: 12),
                      const Text(
                        kAppName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _signup ? 'Create your account' : 'Sign in to your farm',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: muted, fontSize: 14),
                      ),
                      const SizedBox(height: 28),
                      if (_signup) ...[
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Name (optional)',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: _hidePassword,
                        autofillHints: [_signup ? AutofillHints.newPassword : AutofillHints.password],
                        onSubmitted: (_) => busy ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: _signup ? 'At least 8 characters' : null,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(_error!, style: const TextStyle(color: danger, fontSize: 13)),
                      ],
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: busy ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_signup ? 'Create account' : 'Sign in'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: busy ? null : () => setState(() {
                          _signup = !_signup;
                          _error = null;
                        }),
                        child: Text(_signup ? 'I already have an account' : 'Create a new account'),
                      ),
                      TextButton.icon(
                        onPressed: busy ? null : _serverSettings,
                        icon: const Icon(Icons.dns_outlined, size: 18),
                        label: const Text('Server settings'),
                        style: TextButton.styleFrom(foregroundColor: muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.state.serverUrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
