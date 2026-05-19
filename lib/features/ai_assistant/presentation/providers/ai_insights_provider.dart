import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_service.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/features/daily_checkin/presentation/providers/daily_checkin_provider.dart';
import 'package:dead_porky/features/wearable/presentation/providers/wearable_metrics_provider.dart';
import 'package:dead_porky/features/wearable/presentation/screens/device_scanner_screen.dart';

final aiInsightsProvider =
    StateNotifierProvider<AiInsightsNotifier, AiInsightsState>(
  (ref) => AiInsightsNotifier(ref),
);

class AiInsightsState {
  final bool isLoading;
  final String? insight;
  final String? error;

  const AiInsightsState({
    this.isLoading = false,
    this.insight,
    this.error,
  });

  AiInsightsState copyWith({
    bool? isLoading,
    String? insight,
    String? error,
  }) {
    return AiInsightsState(
      isLoading: isLoading ?? this.isLoading,
      insight: insight ?? this.insight,
      error: error ?? this.error,
    );
  }
}

class AiInsightsNotifier extends StateNotifier<AiInsightsState> {
  final Ref _ref;
  final KiloGatewayService _gateway;

  AiInsightsNotifier(this._ref)
      : _gateway = KiloGatewayService(),
        super(const AiInsightsState());

  Future<void> refreshInsights() async {
    state = state.copyWith(isLoading: true, error: null);

    final currentUser = _ref.read(currentUserProvider);
    final dailyCheckin = _ref.read(dailyCheckinProvider);
    final wearableMetrics = _ref.read(wearableMetricsProvider);
    final connectedDevices = _ref
        .read(connectedDevicesProvider)
        .map((device) => device.name)
        .toList();

    final userData = {
      'displayName': currentUser?.displayName,
      'profile': currentUser?.profile.toJson(),
      'settings': currentUser?.settings.toJson(),
      'dailyCheckin': {
        'waterMl': dailyCheckin.waterMl,
        'sleepHours': dailyCheckin.sleepHours,
        'mood': dailyCheckin.mood,
        'energyLevel': dailyCheckin.energyLevel,
        'workoutCompleted': dailyCheckin.workoutCompleted,
        'foodLogged': dailyCheckin.foodLogged,
        'notes': dailyCheckin.notes,
      },
      'wearableMetrics': {
        'steps': wearableMetrics.steps,
        'sleepHours': wearableMetrics.sleepHours,
        'restingHeartRate': wearableMetrics.restingHeartRate,
        'activeMinutes': wearableMetrics.activeMinutes,
        'caloriesBurned': wearableMetrics.caloriesBurned,
        'lastSyncedAt': wearableMetrics.lastSyncedAt?.toIso8601String(),
        'connectedDevices': connectedDevices,
      },
    };

    try {
      final insight = await _gateway.analyzeHealthData(
        userData: userData,
        question:
            'Genera un resumen breve y accionable con recomendaciones de entrenamiento, recuperación y nutrición según los datos del usuario. Sé claro y enfocado en lo que debe ajustar hoy.',
      );
      state = state.copyWith(isLoading: false, insight: insight, error: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        insight: null,
        error: 'No se pudo actualizar los insights. Intenta de nuevo.',
      );
    }
  }
}
