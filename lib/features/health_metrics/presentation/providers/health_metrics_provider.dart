import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:dead_porky/database/app_database.dart';

final healthMetricsProvider =
    StateNotifierProvider<HealthMetricsNotifier, HealthMetricsState>((ref) {
  return HealthMetricsNotifier(ref);
});

class HealthMetricsState {
  final bool isLoading;
  final List<HealthMetric> weights;
  final List<HealthMetric> pressures;
  final List<HealthMetric> spo2s;
  final List<HealthMetric> glucoses;
  final HealthMetric? latestWeight;
  final HealthMetric? latestPressure;
  final HealthMetric? latestSpO2;
  final HealthMetric? latestGlucose;

  const HealthMetricsState({
    this.isLoading = false,
    this.weights = const [],
    this.pressures = const [],
    this.spo2s = const [],
    this.glucoses = const [],
    this.latestWeight,
    this.latestPressure,
    this.latestSpO2,
    this.latestGlucose,
  });

  HealthMetricsState copyWith({
    bool? isLoading,
    List<HealthMetric>? weights,
    List<HealthMetric>? pressures,
    List<HealthMetric>? spo2s,
    List<HealthMetric>? glucoses,
    HealthMetric? latestWeight,
    HealthMetric? latestPressure,
    HealthMetric? latestSpO2,
    HealthMetric? latestGlucose,
  }) {
    return HealthMetricsState(
      isLoading: isLoading ?? this.isLoading,
      weights: weights ?? this.weights,
      pressures: pressures ?? this.pressures,
      spo2s: spo2s ?? this.spo2s,
      glucoses: glucoses ?? this.glucoses,
      latestWeight: latestWeight ?? this.latestWeight,
      latestPressure: latestPressure ?? this.latestPressure,
      latestSpO2: latestSpO2 ?? this.latestSpO2,
      latestGlucose: latestGlucose ?? this.latestGlucose,
    );
  }
}

class HealthMetricsNotifier extends StateNotifier<HealthMetricsState> {
  final Ref _ref;

  HealthMetricsNotifier(this._ref) : super(const HealthMetricsState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final db = _ref.read(appDatabaseProvider);

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    try {
      final weightsList = await db.getMetrics('peso', from: thirtyDaysAgo, to: now);
      final pressuresList = await db.getMetrics('presion', from: thirtyDaysAgo, to: now);
      final spo2sList = await db.getMetrics('spo2', from: thirtyDaysAgo, to: now);
      final glucosesList = await db.getMetrics('glucosa', from: thirtyDaysAgo, to: now);

      state = HealthMetricsState(
        isLoading: false,
        weights: weightsList,
        pressures: pressuresList,
        spo2s: spo2sList,
        glucoses: glucosesList,
        latestWeight: weightsList.isNotEmpty ? weightsList.first : null,
        latestPressure: pressuresList.isNotEmpty ? pressuresList.first : null,
        latestSpO2: spo2sList.isNotEmpty ? spo2sList.first : null,
        latestGlucose: glucosesList.isNotEmpty ? glucosesList.first : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logMetric({
    required String type,
    required double value,
    double? valueSecondary,
    required String unit,
    String source = 'manual',
  }) async {
    final db = _ref.read(appDatabaseProvider);
    final id = const Uuid().v4();

    await db.insertMetric(
      HealthMetricsCompanion(
        id: Value(id),
        type: Value(type),
        value: Value(value),
        valueSecondary: Value(valueSecondary),
        unit: Value(unit),
        source: Value(source),
        measuredAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
      ),
    );

    await refresh();
  }
}
