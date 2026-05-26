import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/datasources/huawei_healthkit_bridge.dart';

final wearableMetricsProvider = StateNotifierProvider<WearableMetricsNotifier, WearableMetricsState>(
  (ref) => WearableMetricsNotifier(),
);

class WearableMetricsState {
  final bool isSyncing;
  final int steps;
  final double sleepHours;
  final int restingHeartRate;
  final int averageHeartRate;
  final int activeMinutes;
  final double caloriesBurned;
  final double distanceKm;
  final int floorsClimbed;
  final int workoutsToday;
  final double bloodOxygen;
  final int respiratoryRate;
  final double heartRateVariabilityMs;
  final double deepSleepHours;
  final double lightSleepHours;
  final double remSleepHours;
  final DateTime? lastSyncedAt;
  final List<String> connectedDevices;
  final List<String> availableMetricKeys;
  final List<String> healthSourceLabels;
  final String syncCoverageNote;

  const WearableMetricsState({
    this.isSyncing = false,
    this.steps = 0,
    this.sleepHours = 0,
    this.restingHeartRate = 0,
    this.averageHeartRate = 0,
    this.activeMinutes = 0,
    this.caloriesBurned = 0,
    this.distanceKm = 0,
    this.floorsClimbed = 0,
    this.workoutsToday = 0,
    this.bloodOxygen = 0,
    this.respiratoryRate = 0,
    this.heartRateVariabilityMs = 0,
    this.deepSleepHours = 0,
    this.lightSleepHours = 0,
    this.remSleepHours = 0,
    this.lastSyncedAt,
    this.connectedDevices = const [],
    this.availableMetricKeys = const [],
    this.healthSourceLabels = const [],
    this.syncCoverageNote = '',
  });

  WearableMetricsState copyWith({
    bool? isSyncing,
    int? steps,
    double? sleepHours,
    int? restingHeartRate,
    int? averageHeartRate,
    int? activeMinutes,
    double? caloriesBurned,
    double? distanceKm,
    int? floorsClimbed,
    int? workoutsToday,
    double? bloodOxygen,
    int? respiratoryRate,
    double? heartRateVariabilityMs,
    double? deepSleepHours,
    double? lightSleepHours,
    double? remSleepHours,
    DateTime? lastSyncedAt,
    List<String>? connectedDevices,
    List<String>? availableMetricKeys,
    List<String>? healthSourceLabels,
    String? syncCoverageNote,
  }) {
    return WearableMetricsState(
      isSyncing: isSyncing ?? this.isSyncing,
      steps: steps ?? this.steps,
      sleepHours: sleepHours ?? this.sleepHours,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      distanceKm: distanceKm ?? this.distanceKm,
      floorsClimbed: floorsClimbed ?? this.floorsClimbed,
      workoutsToday: workoutsToday ?? this.workoutsToday,
      bloodOxygen: bloodOxygen ?? this.bloodOxygen,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      heartRateVariabilityMs:
          heartRateVariabilityMs ?? this.heartRateVariabilityMs,
      deepSleepHours: deepSleepHours ?? this.deepSleepHours,
      lightSleepHours: lightSleepHours ?? this.lightSleepHours,
      remSleepHours: remSleepHours ?? this.remSleepHours,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      availableMetricKeys: availableMetricKeys ?? this.availableMetricKeys,
      healthSourceLabels: healthSourceLabels ?? this.healthSourceLabels,
      syncCoverageNote: syncCoverageNote ?? this.syncCoverageNote,
    );
  }

  bool hasMetric(String metricKey) => availableMetricKeys.contains(metricKey);
}

class WearableMetricsNotifier extends StateNotifier<WearableMetricsState> {
  WearableMetricsNotifier() : super(const WearableMetricsState());

  final Health _health = Health();
  final HuaweiHealthKitBridge _huaweiHealthKitBridge =
      HuaweiHealthKitBridge.instance;
  static const List<String> _summaryMetricOrder = [
    'steps',
    'sleep',
    'restingHeartRate',
    'averageHeartRate',
    'activeMinutes',
    'distanceKm',
    'workoutsToday',
    'bloodOxygen',
    'respiratoryRate',
    'heartRateVariabilityMs',
  ];
  static const List<String> _huaweiSourceKeywords = [
    'huawei',
    'huawei health',
    'watch gt',
    'watchgt',
    'gt 6',
    'gt6',
    'com.huawei.health',
    'com.huawei.bone',
    'com.huawei.healthcloud',
    'health sync',
    'healthsync',
    'nl.appyhapps.healthsync',
  ];
  static const List<String> _bridgeSourceKeywords = [
    'com.sec.android.app.shealth',
    'samsung health',
    'health sync',
    'healthsync',
    'nl.appyhapps.healthsync',
  ];

  void updateMetrics({
    int? steps,
    double? sleepHours,
    int? restingHeartRate,
    int? averageHeartRate,
    int? activeMinutes,
    double? caloriesBurned,
    double? distanceKm,
    int? floorsClimbed,
    int? workoutsToday,
    double? bloodOxygen,
    int? respiratoryRate,
    double? heartRateVariabilityMs,
    double? deepSleepHours,
    double? lightSleepHours,
    double? remSleepHours,
  }) {
    state = state.copyWith(
      steps: steps,
      sleepHours: sleepHours,
      restingHeartRate: restingHeartRate,
      averageHeartRate: averageHeartRate,
      activeMinutes: activeMinutes,
      caloriesBurned: caloriesBurned,
      distanceKm: distanceKm,
      floorsClimbed: floorsClimbed,
      workoutsToday: workoutsToday,
      bloodOxygen: bloodOxygen,
      respiratoryRate: respiratoryRate,
      heartRateVariabilityMs: heartRateVariabilityMs,
      deepSleepHours: deepSleepHours,
      lightSleepHours: lightSleepHours,
      remSleepHours: remSleepHours,
    );
  }

  void setConnectedDevices(List<String> devices) {
    state = state.copyWith(
      connectedDevices: devices,
    );
  }

  List<HealthDataType> get _healthTypes {
    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.RESPIRATORY_RATE,
      HealthDataType.FLIGHTS_CLIMBED,
      HealthDataType.WORKOUT,
    ];

    if (Platform.isAndroid) {
      types.addAll([
        HealthDataType.SLEEP_SESSION,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      ]);
    } else if (Platform.isIOS) {
      types.addAll([
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.EXERCISE_TIME,
      ]);
    }

    return types;
  }

  List<HealthDataAccess> get _healthPermissions =>
      _healthTypes.map((e) => HealthDataAccess.READ).toList();

  Future<void> _configureHealth() async {
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('Error configuring Health: $e');
    }
  }

  Future<void> _ensureHealthPermissions() async {
    if (Platform.isAndroid) {
      final activityRecognitionStatus = await Permission.activityRecognition.request();
      if (!activityRecognitionStatus.isGranted) {
        throw StateError(
          'Permiso de actividad fisica denegado. Android lo requiere para leer pasos y actividad desde Health Connect.',
        );
      }
    }

    final hasPermissions = await _health.hasPermissions(
          _healthTypes,
          permissions: _healthPermissions,
        ) ??
        false;

    if (!hasPermissions) {
      final authorized = await _health.requestAuthorization(
        _healthTypes,
        permissions: _healthPermissions,
      );

      if (!authorized) {
        throw StateError(
          'Permisos denegados para Apple Health / Health Connect. Activa el acceso para que Dead Porky pueda leer los datos que sincroniza Huawei Health.',
        );
      }
    }

    if (Platform.isAndroid) {
      try {
        await _health.requestHealthDataHistoryAuthorization();
      } catch (e) {
        debugPrint('History authorization not available: $e');
      }
      try {
        await _health.requestHealthDataInBackgroundAuthorization();
      } catch (e) {
        debugPrint('Background authorization not available: $e');
      }
    }
  }

  Future<List<HealthDataPoint>> _readHuaweiPoints({
    required HealthDataType type,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final rawPoints = await _readRawPoints(
      type: type,
      startTime: startTime,
      endTime: endTime,
    );

    final huaweiPoints = rawPoints.where(_isHuaweiPoint).toList();
    if (huaweiPoints.isNotEmpty) {
      return huaweiPoints;
    }

    final bridgePoints = rawPoints.where(_isBridgePoint).toList();
    if (bridgePoints.isNotEmpty) {
      debugPrint(
        'Using bridge source for ${type.name}: ${bridgePoints.map(_sourceLabel).toSet().join(', ')}',
      );
    }
    return bridgePoints;
  }

  Future<List<HealthDataPoint>> _readRawPoints({
    required HealthDataType type,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final points = await _health.getHealthDataFromTypes(
      types: [type],
      startTime: startTime,
      endTime: endTime,
    );

    return _health
        .removeDuplicates(points)
        .where((point) => point.type == type)
        .toList();
  }

  Future<List<HealthDataPoint>> _safeReadHuaweiPoints({
    required HealthDataType type,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      return await _readHuaweiPoints(
        type: type,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      debugPrint('Skipping ${type.name}: $e');
      return const [];
    }
  }

  Future<List<HealthDataPoint>> _safeReadRawPoints({
    required HealthDataType type,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      return await _readRawPoints(
        type: type,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      debugPrint('Skipping raw ${type.name}: $e');
      return const [];
    }
  }

  Future<int?> _safeReadTotalSteps({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!Platform.isAndroid) {
      return null;
    }

    try {
      return await _health.getTotalStepsInInterval(startTime, endTime);
    } catch (e) {
      debugPrint('Skipping aggregate steps: $e');
      return null;
    }
  }

  bool _isHuaweiPoint(HealthDataPoint point) {
    final sourceText = _sourceText(point);

    return _huaweiSourceKeywords.any((keyword) => sourceText.contains(keyword));
  }

  bool _isBridgePoint(HealthDataPoint point) {
    final sourceText = _sourceText(point);

    return _bridgeSourceKeywords.any((keyword) => sourceText.contains(keyword));
  }

  String _sourceText(HealthDataPoint point) {
    final metadataText = point.metadata?.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .join(' ') ??
        '';

    return [
      point.sourceName,
      point.sourceId,
      point.deviceModel ?? '',
      metadataText,
    ].join(' ').toLowerCase();
  }

  String _sourceLabel(HealthDataPoint point) {
    final name = point.sourceName.trim();
    final sourceId = point.sourceId.trim();
    final deviceModel = (point.deviceModel ?? '').trim();

    if (name.isNotEmpty && sourceId.isNotEmpty) {
      if (name.toLowerCase() == sourceId.toLowerCase()) {
        return name;
      }
      return '$name ($sourceId)';
    }
    if (name.isNotEmpty) {
      return name;
    }
    if (sourceId.isNotEmpty) {
      return sourceId;
    }
    if (deviceModel.isNotEmpty) {
      return deviceModel;
    }
    return 'origen desconocido';
  }

  String _metricLabel(String metricKey) {
    switch (metricKey) {
      case 'steps':
        return 'pasos';
      case 'sleep':
        return 'sueno';
      case 'restingHeartRate':
        return 'FC reposo';
      case 'averageHeartRate':
        return 'FC media';
      case 'activeMinutes':
        return 'minutos activos';
      case 'distanceKm':
        return 'distancia';
      case 'workoutsToday':
        return 'entrenamientos';
      case 'bloodOxygen':
        return 'SpO2';
      case 'respiratoryRate':
        return 'respiracion';
      case 'heartRateVariabilityMs':
        return 'HRV';
      default:
        return metricKey;
    }
  }

  String _compactSourceSummary(List<String> sourceLabels) {
    if (sourceLabels.isEmpty) {
      return 'origen desconocido';
    }

    final visibleSources = sourceLabels.take(2).join(', ');
    final hiddenCount = sourceLabels.length - 2;
    if (hiddenCount <= 0) {
      return visibleSources;
    }

    return '$visibleSources +$hiddenCount';
  }

  String _buildSyncCoverageNote({
    required List<String> sourceLabels,
    required List<String> availableMetricKeys,
    int? rawSteps,
    int? finalSteps,
  }) {
    final visibleMetricLabels = availableMetricKeys.map(_metricLabel).toList();
    final missingMetricLabels = _summaryMetricOrder
        .where((metricKey) => !availableMetricKeys.contains(metricKey))
        .map(_metricLabel)
        .take(4)
        .toList();

    final buffer = StringBuffer(
      'Fuente actual: ${_compactSourceSummary(sourceLabels)}. '
      'Metricas visibles en esta sync: ${visibleMetricLabels.join(', ')}.',
    );

    if (missingMetricLabels.isNotEmpty) {
      buffer.write(
        ' Aun no aparecen en Health Connect: ${missingMetricLabels.join(', ')}.',
      );
    }

    if (rawSteps != null && finalSteps != null && rawSteps != finalSteps) {
      buffer.write(
        ' Pasos ajustados con el total diario agregado de Health Connect: $finalSteps '
        '(muestras crudas: $rawSteps).',
      );
    }

    return buffer.toString();
  }

  Future<String> _buildHealthConnectDiagnostics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final diagnosticTypes = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.WORKOUT,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
      if (Platform.isAndroid) ...[
        HealthDataType.SLEEP_SESSION,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      ] else ...[
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      ],
    ];

    final stats = <String, _HealthSourceDiagnostic>{};

    for (final type in diagnosticTypes) {
      final points = await _safeReadRawPoints(
        type: type,
        startTime: startTime,
        endTime: endTime,
      );

      for (final point in points) {
        final key = _sourceText(point).trim();
        final normalizedKey = key.isEmpty ? '__unknown__' : key;
        final label = _sourceLabel(point);
        final entry = stats.putIfAbsent(
          normalizedKey,
          () => _HealthSourceDiagnostic(label: label),
        );
        entry.totalPoints += 1;
        entry.types.add(type.name);
        if (_isHuaweiPoint(point)) {
          entry.looksHuawei = true;
        }
      }
    }

    if (stats.isEmpty) {
      return 'Health Connect no devolvio muestras recientes de ningun origen en los ultimos 3 dias.';
    }

    final ordered = stats.values.toList()
      ..sort((left, right) {
        final typeCount = right.types.length.compareTo(left.types.length);
        if (typeCount != 0) {
          return typeCount;
        }
        return right.totalPoints.compareTo(left.totalPoints);
      });

    final visibleSources = ordered.take(4).map((entry) {
      final sampleTypes = entry.types.take(3).join('/');
      final huaweiTag = entry.looksHuawei ? 'Huawei' : 'otro origen';
      return '${entry.label} [$huaweiTag, $sampleTypes]';
    }).join('; ');

    return 'Fuentes visibles en Health Connect durante los ultimos 3 dias: $visibleSources.';
  }

  double _numericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }

    final parsed = double.tryParse(
      value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
    );
    return parsed ?? 0;
  }

  double _sumDurationHours(List<HealthDataPoint> points) {
    if (points.isEmpty) {
      return 0;
    }

    final totalMinutes = points.fold<double>(0, (sum, point) {
      return sum + point.dateTo.difference(point.dateFrom).inMinutes;
    });
    return totalMinutes / 60;
  }

  int _sumDurationMinutes(List<HealthDataPoint> points) {
    if (points.isEmpty) {
      return 0;
    }

    final totalMinutes = points.fold<int>(0, (sum, point) {
      return sum + point.dateTo.difference(point.dateFrom).inMinutes;
    });
    return totalMinutes;
  }

  double _sumSleepHours(List<HealthDataPoint> sleepPoints) {
    final totalMinutes = sleepPoints.fold<double>(0, (sum, point) {
      return sum + point.dateTo.difference(point.dateFrom).inMinutes;
    });
    return totalMinutes / 60;
  }

  int _averageHeartRate(List<HealthDataPoint> heartRatePoints) {
    final rates = heartRatePoints
        .map(_numericValue)
        .where((value) => value >= 40 && value <= 220)
        .toList();

    if (rates.isEmpty) {
      return 0;
    }

    return (rates.reduce((a, b) => a + b) / rates.length).round();
  }

  double _averageValue(
    List<HealthDataPoint> points, {
    double? min,
    double? max,
    bool normalizeFractionPercent = false,
  }) {
    final values = points
        .map((point) {
          var value = _numericValue(point);
          if (normalizeFractionPercent && value > 0 && value <= 1) {
            value *= 100;
          }
          return value;
        })
        .where((value) {
          if (min != null && value < min) {
            return false;
          }
          if (max != null && value > max) {
            return false;
          }
          return true;
        })
        .toList();

    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((left, right) => left + right) / values.length;
  }

  double _sumDistanceKm(List<HealthDataPoint> points) {
    return points.fold<double>(0, (sum, point) {
      final value = _numericValue(point);
      switch (point.unit) {
        case HealthDataUnit.METER:
          return sum + (value / 1000);
        case HealthDataUnit.CENTIMETER:
          return sum + (value / 100000);
        case HealthDataUnit.FOOT:
          return sum + (value * 0.0003048);
        case HealthDataUnit.YARD:
          return sum + (value * 0.0009144);
        case HealthDataUnit.MILE:
          return sum + (value * 1.60934);
        default:
          return sum + (value / 1000);
      }
    });
  }

  int _sumCounts(List<HealthDataPoint> points) {
    return points.fold<int>(0, (sum, point) => sum + _numericValue(point).round());
  }

  int _countDistinctPoints(List<HealthDataPoint> points) {
    final uuids = points
        .map((point) => point.uuid)
        .where((uuid) => uuid.trim().isNotEmpty)
        .toSet();
    return uuids.isNotEmpty ? uuids.length : points.length;
  }

  double _sumCalories(List<HealthDataPoint> energyPoints) {
    return energyPoints.fold<double>(0, (sum, point) {
      final value = _numericValue(point);
      switch (point.unit) {
        case HealthDataUnit.JOULE:
          return sum + (value / 4184);
        case HealthDataUnit.SMALL_CALORIE:
          return sum + (value / 1000);
        case HealthDataUnit.KILOCALORIE:
        case HealthDataUnit.LARGE_CALORIE:
        default:
          return sum + value;
      }
    });
  }

  void _applyHuaweiHealthKitMetrics(HuaweiHealthKitSyncResult result) {
    state = state.copyWith(
      steps: result.steps,
      sleepHours: result.sleepHours,
      restingHeartRate: result.restingHeartRate,
      averageHeartRate: result.averageHeartRate,
      activeMinutes: 0,
      caloriesBurned: 0,
      distanceKm: 0,
      floorsClimbed: 0,
      workoutsToday: 0,
      bloodOxygen: 0,
      respiratoryRate: 0,
      heartRateVariabilityMs: 0,
      deepSleepHours: result.deepSleepHours,
      lightSleepHours: result.lightSleepHours,
      remSleepHours: result.remSleepHours,
      lastSyncedAt: DateTime.now(),
      availableMetricKeys: result.availableMetricKeys,
      healthSourceLabels: [result.sourceLabel],
      syncCoverageNote: result.coverageNote,
    );
  }

  String? _buildHuaweiHealthKitFallbackNote(String? error) {
    if (error == null || error.trim().isEmpty) {
      return null;
    }

    if (error.contains('HUAWEI_HEALTH_APP_ID')) {
      return 'Huawei Health Kit todavia no esta configurado en esta build, asi que la app uso Health Connect como respaldo.';
    }

    if (error.contains('auth_cancelled') || error.contains('auth_failed')) {
      return 'Huawei Health Kit no quedo autorizado en esta sync, asi que la app uso Health Connect como respaldo.';
    }

    if (error.contains('HMS Core no esta disponible')) {
      return 'HMS Core no estuvo disponible en esta sync, asi que la app uso Health Connect como respaldo.';
    }

    if (error.contains('Huawei Health no esta instalado')) {
      return 'Huawei Health no estuvo disponible en esta sync, asi que la app uso Health Connect como respaldo.';
    }

    return 'Huawei Health Kit no estuvo disponible en esta sync, asi que la app uso Health Connect como respaldo.';
  }

  Future<void> syncWithHealthPlatform() async {
    state = state.copyWith(isSyncing: true);

    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw UnsupportedError('Health solo está disponible en Android e iOS.');
      }

      String? huaweiHealthKitError;
      if (Platform.isAndroid) {
        try {
          final huaweiHealthKitResult =
              await _huaweiHealthKitBridge.syncTodayMetrics();
          if (huaweiHealthKitResult.hasAnyMetric) {
            _applyHuaweiHealthKitMetrics(huaweiHealthKitResult);
            debugPrint(
              'Huawei Health Kit sync: steps=${huaweiHealthKitResult.steps}, sleep=${huaweiHealthKitResult.sleepHours}, restingHr=${huaweiHealthKitResult.restingHeartRate}, avgHr=${huaweiHealthKitResult.averageHeartRate}, note=${huaweiHealthKitResult.coverageNote}',
            );
            return;
          }
          huaweiHealthKitError =
              'Huawei Health Kit no devolvio pasos, sueno ni frecuencia cardiaca hoy.';
        } catch (error) {
          huaweiHealthKitError = '$error';
          debugPrint('Huawei Health Kit sync failed: $error');
        }
      }

      await _configureHealth();
      await _ensureHealthPermissions();

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final sleepStartDate = startDate.subtract(const Duration(hours: 18));

      final stepsData = await _safeReadHuaweiPoints(
        type: HealthDataType.STEPS,
        startTime: startDate,
        endTime: now,
      );
      final totalStepsInInterval = await _safeReadTotalSteps(
        startTime: startDate,
        endTime: now,
      );
      final sleepSessionType = Platform.isAndroid
          ? HealthDataType.SLEEP_SESSION
          : HealthDataType.SLEEP_ASLEEP;
      final sleepData = await _safeReadHuaweiPoints(
        type: sleepSessionType,
        startTime: sleepStartDate,
        endTime: now,
      );
      final deepSleepData = await _safeReadHuaweiPoints(
        type: HealthDataType.SLEEP_DEEP,
        startTime: sleepStartDate,
        endTime: now,
      );
      final lightSleepData = await _safeReadHuaweiPoints(
        type: HealthDataType.SLEEP_LIGHT,
        startTime: sleepStartDate,
        endTime: now,
      );
      final remSleepData = await _safeReadHuaweiPoints(
        type: HealthDataType.SLEEP_REM,
        startTime: sleepStartDate,
        endTime: now,
      );
      final heartRateData = await _safeReadHuaweiPoints(
        type: HealthDataType.HEART_RATE,
        startTime: startDate,
        endTime: now,
      );
      final restingHeartRateData = await _safeReadHuaweiPoints(
        type: HealthDataType.RESTING_HEART_RATE,
        startTime: startDate,
        endTime: now,
      );
      final energyData = await _safeReadHuaweiPoints(
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        startTime: startDate,
        endTime: now,
      );
      final distanceType = Platform.isAndroid
          ? HealthDataType.DISTANCE_DELTA
          : HealthDataType.DISTANCE_WALKING_RUNNING;
      final distanceData = await _safeReadHuaweiPoints(
        type: distanceType,
        startTime: startDate,
        endTime: now,
      );
      final floorsData = await _safeReadHuaweiPoints(
        type: HealthDataType.FLIGHTS_CLIMBED,
        startTime: startDate,
        endTime: now,
      );
      final bloodOxygenData = await _safeReadHuaweiPoints(
        type: HealthDataType.BLOOD_OXYGEN,
        startTime: startDate,
        endTime: now,
      );
      final respiratoryRateData = await _safeReadHuaweiPoints(
        type: HealthDataType.RESPIRATORY_RATE,
        startTime: startDate,
        endTime: now,
      );
      final heartRateVariabilityType = Platform.isAndroid
          ? HealthDataType.HEART_RATE_VARIABILITY_RMSSD
          : HealthDataType.HEART_RATE_VARIABILITY_SDNN;
      final heartRateVariabilityData = await _safeReadHuaweiPoints(
        type: heartRateVariabilityType,
        startTime: startDate,
        endTime: now,
      );
      final workoutData = await _safeReadHuaweiPoints(
        type: HealthDataType.WORKOUT,
        startTime: startDate,
        endTime: now,
      );

      final rawSteps = stepsData.fold<int>(0, (sum, point) {
        return sum + _numericValue(point).round();
      });
      final steps = stepsData.isNotEmpty &&
              totalStepsInInterval != null &&
              totalStepsInInterval > rawSteps
          ? totalStepsInInterval
          : rawSteps;
      final deepSleepHours = _sumDurationHours(deepSleepData);
      final lightSleepHours = _sumDurationHours(lightSleepData);
      final remSleepHours = _sumDurationHours(remSleepData);
      final stagedSleepHours = deepSleepHours + lightSleepHours + remSleepHours;
      final sleepHours = sleepData.isNotEmpty ? _sumSleepHours(sleepData) : stagedSleepHours;
      final averageHeartRate = _averageHeartRate(heartRateData);
      final restingHeartRate = _averageValue(
        restingHeartRateData,
        min: 30,
        max: 140,
      ).round();
      final caloriesBurned = _sumCalories(energyData);
      final distanceKm = _sumDistanceKm(distanceData);
      final floorsClimbed = _sumCounts(floorsData);
      final bloodOxygen = _averageValue(
        bloodOxygenData,
        min: 70,
        max: 100,
        normalizeFractionPercent: true,
      );
      final respiratoryRate = _averageValue(
        respiratoryRateData,
        min: 5,
        max: 60,
      ).round();
      final heartRateVariabilityMs = _averageValue(
        heartRateVariabilityData,
        min: 1,
        max: 500,
      );
      final workoutsToday = _countDistinctPoints(workoutData);
      final activeMinutes = _sumDurationMinutes(workoutData) > 0
          ? _sumDurationMinutes(workoutData)
          : (caloriesBurned / 5).round();

      final availableMetricKeys = <String>{
        if (stepsData.isNotEmpty) 'steps',
        if (sleepData.isNotEmpty ||
            deepSleepData.isNotEmpty ||
            lightSleepData.isNotEmpty ||
            remSleepData.isNotEmpty)
          'sleep',
        if (restingHeartRateData.isNotEmpty) 'restingHeartRate',
        if (heartRateData.isNotEmpty) 'averageHeartRate',
        if (workoutData.isNotEmpty || energyData.isNotEmpty) 'activeMinutes',
        if (distanceData.isNotEmpty) 'distanceKm',
        if (workoutData.isNotEmpty) 'workoutsToday',
        if (bloodOxygenData.isNotEmpty) 'bloodOxygen',
        if (respiratoryRateData.isNotEmpty) 'respiratoryRate',
        if (heartRateVariabilityData.isNotEmpty) 'heartRateVariabilityMs',
      }.toList();
      final allUsedPoints = <HealthDataPoint>[
        ...stepsData,
        ...sleepData,
        ...deepSleepData,
        ...lightSleepData,
        ...remSleepData,
        ...heartRateData,
        ...restingHeartRateData,
        ...energyData,
        ...distanceData,
        ...floorsData,
        ...bloodOxygenData,
        ...respiratoryRateData,
        ...heartRateVariabilityData,
        ...workoutData,
      ];
      final sourceLabels = allUsedPoints
          .map(_sourceLabel)
          .where((source) => source.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      final healthConnectCoverageNote = _buildSyncCoverageNote(
        sourceLabels: sourceLabels,
        availableMetricKeys: availableMetricKeys,
        rawSteps: stepsData.isNotEmpty ? rawSteps : null,
        finalSteps: stepsData.isNotEmpty ? steps : null,
      );
      final huaweiHealthKitFallbackNote =
          _buildHuaweiHealthKitFallbackNote(huaweiHealthKitError);
      final syncCoverageParts = <String>[healthConnectCoverageNote];
      if (huaweiHealthKitFallbackNote != null) {
        syncCoverageParts.insert(0, huaweiHealthKitFallbackNote);
      }
      final syncCoverageNote = syncCoverageParts.join(' ');

      final hasAnyMetric = steps > 0 ||
          sleepHours > 0 ||
          restingHeartRate > 0 ||
          averageHeartRate > 0 ||
          caloriesBurned > 0 ||
          distanceKm > 0 ||
          floorsClimbed > 0 ||
          bloodOxygen > 0 ||
          respiratoryRate > 0 ||
          heartRateVariabilityMs > 0 ||
          workoutsToday > 0;

      if (!hasAnyMetric) {
        final diagnostics = await _buildHealthConnectDiagnostics(
          startTime: now.subtract(const Duration(days: 3)),
          endTime: now,
        );
        debugPrint('Health Connect diagnostics: $diagnostics');
        final huaweiHealthKitHint = huaweiHealthKitError == null
            ? ''
            : ' Intento Huawei Health Kit: $huaweiHealthKitError';
        throw StateError(
          'No se encontraron datos de Huawei Health en Apple Health / Health Connect. $diagnostics$huaweiHealthKitHint Abre Huawei Health y activa la sincronización con la plataforma de salud del sistema.',
        );
      }

      state = state.copyWith(
        steps: steps,
        sleepHours: sleepHours,
        restingHeartRate: restingHeartRate,
        averageHeartRate: averageHeartRate,
        activeMinutes: activeMinutes,
        caloriesBurned: caloriesBurned,
        distanceKm: distanceKm,
        floorsClimbed: floorsClimbed,
        workoutsToday: workoutsToday,
        bloodOxygen: bloodOxygen,
        respiratoryRate: respiratoryRate,
        heartRateVariabilityMs: heartRateVariabilityMs,
        deepSleepHours: deepSleepHours,
        lightSleepHours: lightSleepHours,
        remSleepHours: remSleepHours,
        lastSyncedAt: DateTime.now(),
        availableMetricKeys: availableMetricKeys,
        healthSourceLabels: sourceLabels,
        syncCoverageNote: syncCoverageNote,
      );

      debugPrint(
        'Huawei health sync: steps=$steps, rawSteps=$rawSteps, aggregatedSteps=${totalStepsInInterval ?? 'n/a'}, sleep=$sleepHours, restingHr=$restingHeartRate, avgHr=$averageHeartRate, cal=$caloriesBurned, spo2=${bloodOxygen.toStringAsFixed(1)}, hrv=${heartRateVariabilityMs.toStringAsFixed(1)}, dist=${distanceKm.toStringAsFixed(2)}, workouts=$workoutsToday, sources=${sourceLabels.join(', ')}, note=$syncCoverageNote',
      );
    } catch (error) {
      debugPrint('Health sync failed: $error');
      rethrow;
    } finally {
      state = state.copyWith(isSyncing: false);
    }
  }
}

class _HealthSourceDiagnostic {
  _HealthSourceDiagnostic({required this.label});

  final String label;
  final Set<String> types = <String>{};
  int totalPoints = 0;
  bool looksHuawei = false;
}
