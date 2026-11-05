import 'package:flutter/material.dart';

import 'constants.dart';
import 'pages/home_shell.dart';
import 'pages/login_page.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgriMindApp());
}

class AgriMindApp extends StatefulWidget {
  const AgriMindApp({super.key});

  @override
  State<AgriMindApp> createState() => _AgriMindAppState();
}

class _AgriMindAppState extends State<AgriMindApp> {
  late final Future<AppState> _state = AppState.create();

  @override
  void dispose() {
    _state.then((s) => s.dispose());
    super.dispose();
  }

  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.dark,
    ).copyWith(primary: green, surface: surface, error: danger);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: borderColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: borderColor), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: green), borderRadius: BorderRadius.circular(12)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: FutureBuilder<AppState>(
        future: _state,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: green)),
            );
          }
          final state = snapshot.data!;
          return ListenableBuilder(
            listenable: state,
            builder: (context, _) =>
                state.signedIn ? HomeShell(state: state) : LoginPage(state: state),
          );
        },
      ),
    );
  }
}
