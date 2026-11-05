double _d(dynamic v) => (v as num).toDouble();
DateTime? _t(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

class Reading {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final double? light; // % (0 dark .. 100 very bright), null = no sensor / no value
  final double? tds; // ppm, null = no sensor / no value
  final DateTime time;

  const Reading({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    this.light,
    this.tds,
    required this.time,
  });

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
        soilMoisture: _d(j['soilMoisture']),
        temperature: _d(j['temperature']),
        humidity: _d(j['humidity']),
        light: j['light'] == null ? null : _d(j['light']),
        tds: j['tds'] == null ? null : _d(j['tds']),
        time: _t(j['time'])!,
      );
}

class PumpState {
  final bool enabled;
  final bool? reported;
  final String mode;
  final String? source;
  final int runningSeconds;
  final int remainingSeconds;
  final int cooldownRemainingSeconds;
  final int maxMinutes;

  const PumpState({
    required this.enabled,
    required this.reported,
    required this.mode,
    required this.source,
    required this.runningSeconds,
    required this.remainingSeconds,
    required this.cooldownRemainingSeconds,
    required this.maxMinutes,
  });

  bool get isAuto => mode == 'auto';

  factory PumpState.fromJson(Map<String, dynamic> j) => PumpState(
        enabled: j['enabled'] as bool,
        reported: j['reported'] as bool?,
        mode: j['mode'] as String,
        source: j['source'] as String?,
        runningSeconds: (j['runningSeconds'] as num).toInt(),
        remainingSeconds: (j['remainingSeconds'] as num).toInt(),
        cooldownRemainingSeconds: (j['cooldownRemainingSeconds'] as num).toInt(),
        maxMinutes: (j['maxMinutes'] as num).toInt(),
      );
}

class Settings {
  final String mode;
  final double lowThreshold;
  final double highThreshold;
  final double maxPumpMinutes;
  final double cooldownMinutes;
  final double lowAlertSoil;
  final double tempAlertC;
  final double tdsAlertPpm;

  const Settings({
    required this.mode,
    required this.lowThreshold,
    required this.highThreshold,
    required this.maxPumpMinutes,
    required this.cooldownMinutes,
    required this.lowAlertSoil,
    required this.tempAlertC,
    required this.tdsAlertPpm,
  });

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        mode: j['mode'] as String,
        lowThreshold: _d(j['lowThreshold']),
        highThreshold: _d(j['highThreshold']),
        maxPumpMinutes: _d(j['maxPumpMinutes']),
        cooldownMinutes: _d(j['cooldownMinutes']),
        lowAlertSoil: _d(j['lowAlertSoil']),
        tempAlertC: _d(j['tempAlertC']),
        tdsAlertPpm: _d(j['tdsAlertPpm'] ?? 1000),
      );

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'lowThreshold': lowThreshold,
        'highThreshold': highThreshold,
        'maxPumpMinutes': maxPumpMinutes,
        'cooldownMinutes': cooldownMinutes,
        'lowAlertSoil': lowAlertSoil,
        'tempAlertC': tempAlertC,
        'tdsAlertPpm': tdsAlertPpm,
      };
}

class DeviceStatus {
  final bool online;
  final DateTime? lastSeen;
  final Reading? latest;
  final PumpState pump;
  final Settings settings;
  final int unackedAlerts;

  const DeviceStatus({
    required this.online,
    required this.lastSeen,
    required this.latest,
    required this.pump,
    required this.settings,
    required this.unackedAlerts,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> j) => DeviceStatus(
        online: j['online'] as bool,
        lastSeen: _t(j['lastSeen']),
        latest: j['latest'] == null
            ? null
            : Reading.fromJson(j['latest'] as Map<String, dynamic>),
        pump: PumpState.fromJson(j['pump'] as Map<String, dynamic>),
        settings: Settings.fromJson(j['settings'] as Map<String, dynamic>),
        unackedAlerts: (j['unackedAlerts'] as num).toInt(),
      );
}

class Stat {
  final double avg;
  final double min;
  final double max;
  const Stat(this.avg, this.min, this.max);

  factory Stat.fromJson(Map<String, dynamic> j) =>
      Stat(_d(j['avg']), _d(j['min']), _d(j['max']));
}

class DailySummary {
  final String date; // yyyy-MM-dd
  final int count;
  final Stat soilMoisture;
  final Stat temperature;
  final Stat humidity;
  final Stat? light; // null on days without light readings
  final Stat? tds; // null on days without TDS readings

  const DailySummary({
    required this.date,
    required this.count,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    this.light,
    this.tds,
  });

  factory DailySummary.fromJson(Map<String, dynamic> j) => DailySummary(
        date: j['date'] as String,
        count: (j['count'] as num).toInt(),
        soilMoisture: Stat.fromJson(j['soilMoisture'] as Map<String, dynamic>),
        temperature: Stat.fromJson(j['temperature'] as Map<String, dynamic>),
        humidity: Stat.fromJson(j['humidity'] as Map<String, dynamic>),
        light: j['light'] == null ? null : Stat.fromJson(j['light'] as Map<String, dynamic>),
        tds: j['tds'] == null ? null : Stat.fromJson(j['tds'] as Map<String, dynamic>),
      );
}

class AlertItem {
  final int id;
  final String type;
  final String severity; // info | warning | critical
  final String message;
  final bool acked;
  final DateTime time;

  const AlertItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.acked,
    required this.time,
  });

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        id: (j['id'] as num).toInt(),
        type: j['type'] as String,
        severity: j['severity'] as String,
        message: j['message'] as String,
        acked: j['acked'] as bool,
        time: _t(j['time'])!,
      );
}

class PumpEvent {
  final String action; // on | off
  final String source; // manual | auto | limit | offline | system
  final String? note;
  final DateTime time;

  const PumpEvent({
    required this.action,
    required this.source,
    required this.note,
    required this.time,
  });

  factory PumpEvent.fromJson(Map<String, dynamic> j) => PumpEvent(
        action: j['action'] as String,
        source: j['source'] as String,
        note: j['note'] as String?,
        time: _t(j['time'])!,
      );
}

class AppUser {
  final int id;
  final String email;
  final String? name;

  const AppUser({required this.id, required this.email, required this.name});

  String get displayName =>
      (name != null && name!.trim().isNotEmpty) ? name! : email.split('@').first;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['id'] as num).toInt(),
        email: j['email'] as String,
        name: j['name'] as String?,
      );
}

class DeviceInfo {
  final String id;
  final String name;
  final bool online;
  final DateTime? lastSeen;

  const DeviceInfo({
    required this.id,
    required this.name,
    required this.online,
    required this.lastSeen,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        online: j['online'] as bool? ?? false,
        lastSeen: _t(j['lastSeen']),
      );
}
