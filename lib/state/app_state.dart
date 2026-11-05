import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/models.dart';
import '../services/api.dart';

/// Everything the screens show: the account, the linked devices and the live data of the
/// selected device. Screens listen to it (ChangeNotifier) and call its methods.
///
/// Methods that the user triggers return `null` on success or a message to show.
class AppState extends ChangeNotifier {
  AppState._(this._prefs);

  static const _kServer = 'serverUrl';
  static const _kToken = 'token';
  static const _kUser = 'user';
  static const _kDevice = 'deviceId';

  static const _pollEvery = Duration(seconds: 4);
  static const _seriesEveryNPolls = 4; // history / alerts refresh less often than status

  final SharedPreferences _prefs;
  ApiClient _api = ApiClient(baseUrl: kDefaultServerUrl);

  // ---- session ----
  String serverUrl = kDefaultServerUrl;
  String? _token;
  AppUser? user;

  // ---- devices ----
  List<DeviceInfo> devices = const [];
  String? deviceId;

  // ---- data of the selected device ----
  DeviceStatus? status;
  List<Reading> history = const []; // oldest -> newest
  List<DailySummary> daily = const [];
  List<PumpEvent> events = const []; // newest first
  List<AlertItem> alerts = const []; // newest first
  DateTime? lastUpdate;

  /// A request is in flight (pump / settings / device actions).
  bool busy = false;

  /// Set while the server cannot be reached; cleared by the next successful refresh.
  String? connectionError;

  bool ready = false;
  bool get signedIn => _token != null && user != null;
  bool get hasDevices => devices.isNotEmpty;

  DeviceInfo? get device {
    for (final d in devices) {
      if (d.id == deviceId) return d;
    }
    return null;
  }

  Timer? _timer;
  int _polls = 0;
  bool _polling = false;
  bool _disposed = false;

  static Future<AppState> create() async {
    final state = AppState._(await SharedPreferences.getInstance());
    await state._init();
    return state;
  }

  // ------------------------------------------------------------------ setup

  Future<void> _init() async {
    serverUrl = _prefs.getString(_kServer) ?? kDefaultServerUrl;
    _token = _prefs.getString(_kToken);
    deviceId = _prefs.getString(_kDevice);
    final savedUser = _prefs.getString(_kUser);
    if (savedUser != null) {
      try {
        user = AppUser.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
      } catch (_) {
        user = null;
      }
    }
    _buildApi();

    if (signedIn) {
      // Check the saved session. If the server is simply unreachable, stay signed in:
      // the data screens will show the connection problem.
      try {
        final me = await _api.get('/api/auth/me') as Map<String, dynamic>;
        _setUser(AppUser.fromJson(me['user'] as Map<String, dynamic>));
        await _loadDevices();
      } on ApiException catch (e) {
        if (e.status == 401) {
          await _clearSession();
        } else {
          connectionError = e.message;
        }
      } catch (_) {
        connectionError = 'Unexpected answer from the server.';
      }
    }
    ready = true;
    if (signedIn) _startPolling();
  }

  void _buildApi() {
    _api.close();
    _api = ApiClient(baseUrl: serverUrl, token: _token)..onUnauthorized = _onUnauthorized;
  }

  void _onUnauthorized() {
    if (!signedIn) return;
    _clearSession().then((_) => _notify());
  }

  // ----------------------------------------------------------- server address

  /// Returns a message when the address is not valid.
  Future<String?> setServerUrl(String url) async {
    final problem = ApiClient.validateUrl(url);
    if (problem != null) return problem;
    serverUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await _prefs.setString(_kServer, serverUrl);
    _buildApi();
    _notify();
    return null;
  }

  // ---------------------------------------------------------------- account

  Future<String?> login(String email, String password) =>
      _authenticate('/api/auth/login', {'email': email.trim(), 'password': password});

  Future<String?> signup(String email, String password, String name) => _authenticate(
        '/api/auth/signup',
        {'email': email.trim(), 'password': password, if (name.trim().isNotEmpty) 'name': name.trim()},
      );

  Future<String?> _authenticate(String path, Map<String, dynamic> body) async {
    busy = true;
    _notify();
    try {
      final res = await _api.post(path, body) as Map<String, dynamic>;
      _token = res['token'] as String;
      await _prefs.setString(_kToken, _token!);
      _setUser(AppUser.fromJson(res['user'] as Map<String, dynamic>));
      _buildApi();
      await _loadDevices();
      _startPolling();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Unexpected answer from the server.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // signing out locally is enough
    }
    await _clearSession();
    _notify();
  }

  void _setUser(AppUser u) {
    user = u;
    _prefs.setString(_kUser, jsonEncode({'id': u.id, 'email': u.email, 'name': u.name}));
  }

  Future<void> _clearSession() async {
    _timer?.cancel();
    _token = null;
    user = null;
    devices = const [];
    deviceId = null;
    _clearData();
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kDevice);
    _buildApi();
  }

  void _clearData() {
    status = null;
    history = const [];
    daily = const [];
    events = const [];
    alerts = const [];
    lastUpdate = null;
    connectionError = null;
  }

  // ---------------------------------------------------------------- devices

  Future<void> _loadDevices() async {
    final res = await _api.get('/api/devices') as Map<String, dynamic>;
    devices = [for (final d in res['items'] as List) DeviceInfo.fromJson(d as Map<String, dynamic>)];
    if (devices.isEmpty) {
      deviceId = null;
      _clearData();
      await _prefs.remove(_kDevice);
    } else if (device == null) {
      await _select(devices.first.id);
    }
  }

  Future<void> _select(String id) async {
    deviceId = id;
    await _prefs.setString(_kDevice, id);
    _clearData();
  }

  Future<void> selectDevice(String id) async {
    if (id == deviceId) return;
    await _select(id);
    _notify();
    await refreshAll();
  }

  /// Links a device using the 6-character code shown on its screen.
  Future<String?> claimDevice(String code, String name) async {
    busy = true;
    _notify();
    try {
      final res = await _api.post('/api/devices/claim', {
        'code': code.trim(),
        if (name.trim().isNotEmpty) 'name': name.trim(),
      }) as Map<String, dynamic>;
      final id = res['id'] as String;
      await _loadDevices();
      await _select(id);
      _notify();
      await refreshAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<String?> renameDevice(String name) async {
    final id = deviceId;
    if (id == null) return 'No device selected.';
    return _action(() async {
      await _api.patch('/api/devices/$id', {'name': name.trim()});
      await _loadDevices();
    });
  }

  /// Unlinks the selected device (its stored data is deleted; the hardware shows a new code).
  Future<String?> unlinkDevice() async {
    final id = deviceId;
    if (id == null) return 'No device selected.';
    final err = await _action(() async {
      await _api.delete('/api/devices/$id');
      deviceId = null;
      await _loadDevices();
    });
    if (err == null) await refreshAll();
    return err;
  }

  // ------------------------------------------------------------- live data

  String _d(String path) => '/api/devices/$deviceId$path';

  void _startPolling() {
    _timer?.cancel();
    _polls = 0;
    _timer = Timer.periodic(_pollEvery, (_) => _poll());
    refreshAll();
  }

  /// Stop polling while the app is in the background.
  void pausePolling() => _timer?.cancel();

  void resumePolling() {
    if (signedIn && !_disposed) _startPolling();
  }

  Future<void> _poll() async {
    if (_polling || deviceId == null) return;
    _polling = true;
    try {
      _polls++;
      await refreshStatus();
      if (_polls % _seriesEveryNPolls == 0) await _refreshSeries();
    } finally {
      _polling = false;
    }
  }

  Future<void> refreshStatus() async {
    if (deviceId == null) return;
    final id = deviceId;
    try {
      final res = await _api.get(_d('/status')) as Map<String, dynamic>;
      if (id != deviceId) return; // the user switched device meanwhile
      status = DeviceStatus.fromJson(res);
      lastUpdate = DateTime.now();
      connectionError = null;
    } on ApiException catch (e) {
      connectionError = e.message;
      if (e.status == 404) {
        // the device was unlinked somewhere else
        await _loadDevices();
      }
    } catch (_) {
      connectionError = 'Unexpected answer from the server.';
    }
    _notify();
  }

  Future<void> _refreshSeries() async {
    if (deviceId == null) return;
    final id = deviceId;

    Future<T?> safe<T>(Future<T> Function() run) async {
      try {
        return await run();
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      safe(() => _api.get(_d('/history'), query: {'hours': '24', 'limit': '300'})),
      safe(() => _api.get(_d('/history/daily'), query: {'days': '7'})),
      safe(() => _api.get(_d('/pump/events'), query: {'limit': '30'})),
      safe(() => _api.get(_d('/alerts'), query: {'limit': '50'})),
    ]);
    if (id != deviceId) return;

    List<T> items<T>(dynamic res, T Function(Map<String, dynamic>) parse) {
      if (res is! Map || res['items'] is! List) return const [];
      return [for (final x in res['items'] as List) parse(x as Map<String, dynamic>)];
    }

    if (results[0] != null) history = items(results[0], Reading.fromJson);
    if (results[1] != null) daily = items(results[1], DailySummary.fromJson);
    if (results[2] != null) events = items(results[2], PumpEvent.fromJson);
    if (results[3] != null) alerts = items(results[3], AlertItem.fromJson);
    _notify();
  }

  /// Pull-to-refresh and device switches.
  Future<void> refreshAll() async {
    await refreshStatus();
    await _refreshSeries();
  }

  // --------------------------------------------------------------- actions

  Future<String?> setPump(bool on) {
    return _action(() async {
      await _api.post(_d('/pump'), {'enabled': on});
      await refreshStatus();
      await _refreshSeries();
    });
  }

  Future<String?> saveSettings(Map<String, dynamic> settings) {
    return _action(() async {
      await _api.put(_d('/settings'), settings);
      await refreshStatus();
    });
  }

  Future<String?> ackAlerts({List<int>? ids}) {
    return _action(() async {
      await _api.post(_d('/alerts/ack'), ids == null ? {'all': true} : {'ids': ids});
      await refreshStatus();
      await _refreshSeries();
    });
  }

  Future<String?> _action(Future<void> Function() run) async {
    busy = true;
    _notify();
    try {
      await run();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      busy = false;
      _notify();
    }
  }

  // ---------------------------------------------------------------- plumbing

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _api.close();
    super.dispose();
  }
}
