import 'dart:ui';
import 'package:uuid/uuid.dart';

/// Workout entity representing a training session
class Workout {
  final String id;
  final String name;
  final String? templateId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int durationSeconds;
  final String? notes;
  final double totalVolume;
  final List<WorkoutExercise> exercises;
  final bool synced;

  const Workout({
    required this.id,
    required this.name,
    this.templateId,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds = 0,
    this.notes,
    this.totalVolume = 0,
    this.exercises = const [],
    this.synced = false,
  });

  factory Workout.create({String name = 'Entrenamiento', String? templateId}) {
    return Workout(
      id: const Uuid().v4(),
      name: name,
      templateId: templateId,
      startedAt: DateTime.now(),
      exercises: [],
    );
  }

  Workout copyWith({
    String? name,
    DateTime? finishedAt,
    int? durationSeconds,
    String? notes,
    double? totalVolume,
    List<WorkoutExercise>? exercises,
  }) {
    return Workout(
      id: id,
      name: name ?? this.name,
      templateId: templateId,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
      totalVolume: totalVolume ?? this.totalVolume,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Calculate total volume from all exercises
  double calculateTotalVolume() {
    double volume = 0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        if (set.completed) {
          volume += set.reps * set.weight;
        }
      }
    }
    return volume;
  }

  /// Get elapsed time as formatted string
  String get elapsedTime {
    final elapsed = DateTime.now().difference(startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'templateId': templateId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'durationSeconds': durationSeconds,
    'notes': notes,
    'totalVolume': totalVolume,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };
}

/// Exercise within a workout
class WorkoutExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;
  final int restSeconds;
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
    this.restSeconds = 90,
    this.notes,
  });

  factory WorkoutExercise.fromExercise({
    required String exerciseId,
    required String exerciseName,
    int restSeconds = 90,
  }) {
    return WorkoutExercise(
      id: const Uuid().v4(),
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: [WorkoutSet(setNumber: 1)],
      restSeconds: restSeconds,
    );
  }

  WorkoutExercise copyWith({
    List<WorkoutSet>? sets,
    int? restSeconds,
    String? notes,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
      restSeconds: restSeconds ?? this.restSeconds,
      notes: notes ?? this.notes,
    );
  }

  /// Add a new set
  WorkoutExercise addSet() {
    final newSets = List<WorkoutSet>.from(sets);
    newSets.add(WorkoutSet(setNumber: newSets.length + 1));
    return copyWith(sets: newSets);
  }

  /// Remove a set
  WorkoutExercise removeSet(int index) {
    final newSets = List<WorkoutSet>.from(sets);
    if (index >= 0 && index < newSets.length) {
      newSets.removeAt(index);
      // Renumber sets
      for (int i = 0; i < newSets.length; i++) {
        newSets[i] = newSets[i].copyWith(setNumber: i + 1);
      }
    }
    return copyWith(sets: newSets);
  }

  /// Update a specific set
  WorkoutExercise updateSet(int index, WorkoutSet set) {
    final newSets = List<WorkoutSet>.from(sets);
    if (index >= 0 && index < newSets.length) {
      newSets[index] = set;
    }
    return copyWith(sets: newSets);
  }

  /// Get best set (highest volume)
  WorkoutSet? get bestSet {
    if (sets.isEmpty) return null;
    return sets.reduce(
      (a, b) => (a.reps * a.weight) > (b.reps * b.weight) ? a : b,
    );
  }

  /// Calculate total volume for this exercise
  double get totalVolume {
    double volume = 0;
    for (final set in sets) {
      if (set.completed) {
        volume += set.reps * set.weight;
      }
    }
    return volume;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    'restSeconds': restSeconds,
    'notes': notes,
  };
}

/// Individual set within an exercise
class WorkoutSet {
  final String id;
  final int setNumber;
  final int reps;
  final double weight;
  final String? tempo; // e.g., "3-1-2-0"
  final int? rpe; // Rate of Perceived Exertion (1-10)
  final bool completed;
  final DateTime? completedAt;

  WorkoutSet({
    String? id,
    required this.setNumber,
    this.reps = 0,
    this.weight = 0,
    this.tempo,
    this.rpe,
    this.completed = false,
    this.completedAt,
  }) : id = id ?? const Uuid().v4();

  WorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    String? tempo,
    int? rpe,
    bool? completed,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      tempo: tempo ?? this.tempo,
      rpe: rpe ?? this.rpe,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Mark set as completed
  WorkoutSet complete() {
    return copyWith(completed: true, completedAt: DateTime.now());
  }

  /// Calculate volume for this set
  double get volume => reps * weight;

  Map<String, dynamic> toJson() => {
    'id': id,
    'setNumber': setNumber,
    'reps': reps,
    'weight': weight,
    'tempo': tempo,
    'rpe': rpe,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
  };
}

/// RPE scale descriptions
class RPEScale {
  static const Map<int, String> descriptions = {
    1: 'Muy fácil',
    2: 'Fácil',
    3: 'Moderado',
    4: 'Algo difícil',
    5: 'Difícil',
    6: 'Difícil+',
    7: 'Muy difícil',
    8: 'Muy difícil+',
    9: 'Casi máximo',
    10: 'Máximo',
  };

  static String getDescription(int rpe) {
    return descriptions[rpe] ?? '';
  }

  static Color getColor(int rpe) {
    if (rpe <= 3) return const Color(0xFF10B981); // Green
    if (rpe <= 6) return const Color(0xFFF59E0B); // Amber
    if (rpe <= 8) return const Color(0xFFEF4444); // Red
    return const Color(0xFF7C3AED); // Purple
  }
}
