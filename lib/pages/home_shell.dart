import 'package:flutter/material.dart';

import '../constants.dart';
import '../state/app_state.dart';
import 'alerts_page.dart';
import 'analytics_page.dart';
import 'device_dialogs.dart';
import 'irrigation_page.dart';
import 'monitoring_page.dart';
import 'overview_page.dart';

/// The signed-in app: a bottom navigation bar with the five pages, the device switcher
/// and the account menu.
class HomeShell extends StatefulWidget {
  final AppState state;

  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // do not poll the server while the app is in the background
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      state.resumePolling();
    } else if (lifecycle == AppLifecycleState.paused) {
      state.pausePolling();
    }
  }

  void _go(int i) => setState(() => _index = i);

  Widget _page() {
    switch (_index) {
      case 0:
        return OverviewPage(state: state, onNavigate: _go);
      case 1:
        return MonitoringPage(state: state);
      case 2:
        return IrrigationPage(state: state);
      case 3:
        return AnalyticsPage(state: state);
      default:
        return AlertsPage(state: state);
    }
  }

  void _openAccount() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AccountSheet(state: state, parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final unacked = state.status?.unackedAlerts ?? 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: background,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco_rounded, color: green, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        state.device?.name ?? kAppName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: muted),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: state.hasDevices ? state.refreshAll : null,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Account',
                onPressed: _openAccount,
                icon: const Icon(Icons.account_circle_outlined),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: state.hasDevices ? _body(context) : _NoDevice(state: state),
          bottomNavigationBar: state.hasDevices
              ? NavigationBar(
                  backgroundColor: surface,
                  indicatorColor: green.withValues(alpha: 0.18),
                  selectedIndex: _index,
                  onDestinationSelected: _go,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
                    const NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors_rounded), label: 'Monitor'),
                    const NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop_rounded), label: 'Irrigation'),
                    const NavigationDestination(icon: Icon(Icons.show_chart_rounded), selectedIcon: Icon(Icons.stacked_line_chart_rounded), label: 'Analytics'),
                    NavigationDestination(
                      icon: Badge(isLabelVisible: unacked > 0, label: Text('$unacked'), child: const Icon(Icons.notifications_outlined)),
                      selectedIcon: Badge(isLabelVisible: unacked > 0, label: Text('$unacked'), child: const Icon(Icons.notifications_rounded)),
                      label: 'Alerts',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      children: [
        if (state.connectionError != null)
          Container(
            width: double.infinity,
            color: const Color(0xFF4A1D1D),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 16, color: danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(state.connectionError!, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: green,
            onRefresh: state.refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: _page(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Signed in, but no device linked yet.
class _NoDevice extends StatelessWidget {
  final AppState state;

  const _NoDevice({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory_rounded, size: 64, color: green),
              const SizedBox(height: 18),
              Text(
                'Welcome, ${state.user?.displayName ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Link your AgriMind device to start monitoring. Power it on, then type the '
                '6-character code shown on its screen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => showAddDeviceDialog(context, state),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: background,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: state.logout, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}

String _initial(String? name) => (name == null || name.isEmpty) ? '?' : name.substring(0, 1).toUpperCase();

class _AccountSheet extends StatelessWidget {
  final AppState state;
  final BuildContext parentContext;

  const _AccountSheet({required this.state, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final user = state.user;

        // Runs an action after the sheet has closed, so dialogs open on the page.
        void later(Future<void> Function() action) {
          Navigator.pop(context);
          if (parentContext.mounted) action();
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: green.withValues(alpha: 0.18),
                      foregroundColor: green,
                      child: Text(_initial(user?.displayName)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.displayName ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(user?.email ?? '', style: const TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('YOUR DEVICES', style: TextStyle(color: muted, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                for (final d in state.devices)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.memory_rounded, color: d.id == state.deviceId ? green : muted),
                    title: Text(d.name),
                    subtitle: Text(
                      d.online ? 'Online' : 'Offline',
                      style: TextStyle(color: d.online ? green : warning, fontSize: 12),
                    ),
                    trailing: d.id == state.deviceId ? const Icon(Icons.check_rounded, color: green) : null,
                    onTap: () {
                      state.selectDevice(d.id);
                      Navigator.pop(context);
                    },
                  ),
                const Divider(color: borderColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('Add a device'),
                  onTap: () => later(() => showAddDeviceDialog(parentContext, state)),
                ),
                if (state.device != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Rename this device'),
                    onTap: () => later(() => showRenameDeviceDialog(parentContext, state)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_off_rounded, color: danger),
                    title: const Text('Unlink this device', style: TextStyle(color: danger)),
                    onTap: () => later(() => showUnlinkDeviceDialog(parentContext, state)),
                  ),
                ],
                const Divider(color: borderColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Sign out'),
                  onTap: () {
                    Navigator.pop(context);
                    state.logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
