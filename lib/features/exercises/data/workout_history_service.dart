import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/exercises/domain/entities/workout_record.dart';
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_real.dart';

// ==================== Workout History Service ====================

class WorkoutHistoryService {
  final List<WorkoutRecord> _records = [];
  final List<DailyHealthSnapshot> _snapshots = [];

  // In production, these would be persisted to Drift/Firestore
  List<WorkoutRecord> get records => List.unmodifiable(_records);
  List<DailyHealthSnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// Save a completed workout
  void saveWorkout(WorkoutRecord record) {
    _records.add(record);
    // TODO: Save to Drift DB and sync to Firestore
  }

  /// Save daily health snapshot
  void saveDailySnapshot(DailyHealthSnapshot snapshot) {
    _snapshots.add(snapshot);
    // TODO: Save to Drift DB
  }

  /// Get workouts for a specific date range
  List<WorkoutRecord> getWorkoutsInRange(DateTime start, DateTime end) {
    return _records
        .where((r) => r.date.isAfter(start) && r.date.isBefore(end))
        .toList();
  }

  /// Get this week's workouts
  List<WorkoutRecord> getThisWeekWorkouts() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return getWorkoutsInRange(startOfWeek, now);
  }

  /// Get total volume for this week
  double getWeeklyVolume() {
    return getThisWeekWorkouts().fold(0, (sum, w) => sum + w.totalVolume);
  }

  /// Get workouts count for this week
  int getWeeklyWorkoutCount() {
    return getThisWeekWorkouts().length;
  }

  /// Generate daily report for AI
  Future<String> generateDailyReport() async {
    final today = DateTime.now();
    final todayWorkouts = _records
        .where(
          (r) =>
              r.date.year == today.year &&
              r.date.month == today.month &&
              r.date.day == today.day,
        )
        .toList();

    final todaySnapshot = _snapshots
        .where(
          (s) =>
              s.date.year == today.year &&
              s.date.month == today.month &&
              s.date.day == today.day,
        )
        .firstOrNull;

    final buffer = StringBuffer();
    buffer.writeln(
      '=== REPORTE DIARIO - ${today.day}/${today.month}/${today.year} ===\n',
    );

    // Health snapshot
    if (todaySnapshot != null) {
      buffer.writeln(todaySnapshot.toAIContext());
      buffer.writeln('');
    }

    // Workouts
    if (todayWorkouts.isNotEmpty) {
      buffer.writeln('=== ENTRENAMIENTOS ===\n');
      for (final workout in todayWorkouts) {
        buffer.writeln(workout.toAIContext());
      }
    } else {
      buffer.writeln('No se registraron entrenamientos hoy.\n');
    }

    // Weekly summary
    buffer.writeln('=== RESUMEN SEMANAL ===');
    buffer.writeln('Entrenamientos esta semana: ${getWeeklyWorkoutCount()}');
    buffer.writeln(
      'Volumen semanal: ${getWeeklyVolume().toStringAsFixed(0)} kg\n',
    );

    // Try real AI evaluation
    try {
      final gateway = KiloGatewayReal();
      const systemPrompt = '''Eres un coach de salud y fitness experto. 
Analiza los datos del día y proporciona:
1. Resumen del rendimiento
2. Identifica patrones y tendencias
3. Recomendaciones específicas para mañana
4. Advertencias si hay algo preocupante
5. Motivación personalizada

Responde en español, usa emojis, sé conciso (máximo 8 líneas).''';

      final evaluation = await gateway.chat(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': buffer.toString()},
        ],
        maxTokens: 500,
      );

      return evaluation;
    } catch (e) {
      return _generateFallbackReport(todayWorkouts, todaySnapshot);
    }
  }

  String _generateFallbackReport(
    List<WorkoutRecord> workouts,
    DailyHealthSnapshot? snapshot,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('📊 **Reporte del día**\n');

    if (snapshot != null) {
      if (snapshot.weight != null) {
        buffer.writeln('⚖️ Peso: ${snapshot.weight} kg');
      }
      if (snapshot.sleepHours != null) {
        buffer.writeln(
          '😴 Sueño: ${snapshot.sleepHours}h ${snapshot.sleepMinutes ?? 0}m',
        );
      }
      if (snapshot.steps != null) buffer.writeln('🚶 Pasos: ${snapshot.steps}');
      if (snapshot.calories != null) {
        buffer.writeln('🔥 Calorías: ${snapshot.calories} kcal');
      }
    }

    if (workouts.isNotEmpty) {
      buffer.writeln('\n💪 **Entrenamientos:**');
      for (final w in workouts) {
        buffer.writeln(
          '• ${w.routineName}: ${w.totalVolume.toStringAsFixed(0)} kg',
        );
      }
    }

    buffer.writeln('\n¡Sigue así! 🔥');
    return buffer.toString();
  }

  /// Get exercise progression for a specific exercise
  List<Map<String, dynamic>> getExerciseProgression(String exerciseId) {
    final progression = <Map<String, dynamic>>[];

    for (final workout in _records) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId == exerciseId) {
          final bestSet = exercise.sets
              .where((s) => s.completed)
              .fold<SetRecord?>(null, (best, current) {
                if (best == null) return current;
                return (current.weight * current.reps) >
                        (best.weight * best.reps)
                    ? current
                    : best;
              });

          if (bestSet != null) {
            progression.add({
              'date': workout.date,
              'weight': bestSet.weight,
              'reps': bestSet.reps,
              'volume': bestSet.weight * bestSet.reps,
              'estimated1RM': bestSet.weight * (1 + bestSet.reps / 30),
            });
          }
        }
      }
    }

    return progression;
  }
}

// ==================== Providers ====================

final workoutHistoryServiceProvider = Provider<WorkoutHistoryService>(
  (ref) => WorkoutHistoryService(),
);
