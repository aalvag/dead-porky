import 'dart:ui';
import 'package:uuid/uuid.dart';

// ==================== Set Types ====================

enum SetType { normal, dropSet, superset, failure, warmup }

extension SetTypeX on SetType {
  String get label {
    switch (this) {
      case SetType.normal:
        return 'Normal';
      case SetType.dropSet:
        return 'Drop Set';
      case SetType.superset:
        return 'Superset';
      case SetType.failure:
        return 'Al fallo';
      case SetType.warmup:
        return 'Calentamiento';
    }
  }

  String get abbreviation {
    switch (this) {
      case SetType.normal:
        return '';
      case SetType.dropSet:
        return 'DS';
      case SetType.superset:
        return 'SS';
      case SetType.failure:
        return 'F';
      case SetType.warmup:
        return 'W';
    }
  }

  Color get color {
    switch (this) {
      case SetType.normal:
        return const Color(0xFF6366F1);
      case SetType.dropSet:
        return const Color(0xFFF59E0B);
      case SetType.superset:
        return const Color(0xFF10B981);
      case SetType.failure:
        return const Color(0xFFEF4444);
      case SetType.warmup:
        return const Color(0xFF94A3B8);
    }
  }
}

// ==================== Workout Set ====================

class WorkoutSet {
  final String id;
  final int setNumber;
  final int reps;
  final double weight; // kg
  final SetType type;
  final int? rpe; // 1-10
  final String? tempo; // e.g., "3-1-2-0"
  final bool completed;
  final DateTime? completedAt;
  final String? notes;

  WorkoutSet({
    String? id,
    required this.setNumber,
    this.reps = 0,
    this.weight = 0,
    this.type = SetType.normal,
    this.rpe,
    this.tempo,
    this.completed = false,
    this.completedAt,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  WorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    SetType? type,
    int? rpe,
    String? tempo,
    bool? completed,
    DateTime? completedAt,
    String? notes,
  }) {
    return WorkoutSet(
      id: id,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      type: type ?? this.type,
      rpe: rpe ?? this.rpe,
      tempo: tempo ?? this.tempo,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }

  WorkoutSet complete() {
    return copyWith(completed: true, completedAt: DateTime.now());
  }

  WorkoutSet uncomplete() {
    return copyWith(completed: false, completedAt: null);
  }

  /// Volume for this set (weight * reps)
  double get volume => weight * reps;

  /// Estimated 1RM using Epley formula
  double? get estimatedOneRepMax {
    if (reps == 0 || weight == 0) return null;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }
}

// ==================== Workout Exercise ====================

class WorkoutExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String category; // chest, back, legs, etc.
  final List<WorkoutSet> sets;
  final int defaultRestSeconds;
  final String? notes;
  final int order;

  WorkoutExercise({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    List<WorkoutSet>? sets,
    this.defaultRestSeconds = 90,
    this.notes,
    this.order = 0,
  }) : id = id ?? const Uuid().v4(),
       sets = sets ?? [];

  WorkoutExercise copyWith({
    List<WorkoutSet>? sets,
    int? defaultRestSeconds,
    String? notes,
    int? order,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      category: category,
      sets: sets ?? this.sets,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }

  /// Add a new set
  WorkoutExercise addSet({SetType type = SetType.normal}) {
    final newSets = List<WorkoutSet>.from(sets);

    // Copy last set values if exists
    int lastReps = 0;
    double lastWeight = 0;
    if (newSets.isNotEmpty) {
      lastReps = newSets.last.reps;
      lastWeight = newSets.last.weight;
    }

    newSets.add(
      WorkoutSet(
        setNumber: newSets.length + 1,
        reps: lastReps,
        weight: lastWeight,
        type: type,
      ),
    );
    return copyWith(sets: newSets);
  }

  /// Add a drop set based on last completed set
  WorkoutExercise addDropSet({double weightReduction = 0.2}) {
    final completedSets = sets.where((s) => s.completed).toList();
    if (completedSets.isEmpty) return this;

    final lastSet = completedSets.last;
    final newWeight = lastSet.weight * (1 - weightReduction);

    final newSets = List<WorkoutSet>.from(sets);
    newSets.add(
      WorkoutSet(
        setNumber: newSets.length + 1,
        reps: lastSet.reps,
        weight: newWeight,
        type: SetType.dropSet,
      ),
    );

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

  /// Remove a set
  WorkoutExercise removeSet(int index) {
    final newSets = List<WorkoutSet>.from(sets);
    if (index >= 0 && index < newSets.length) {
      newSets.removeAt(index);
      // Renumber
      for (int i = 0; i < newSets.length; i++) {
        newSets[i] = newSets[i].copyWith(setNumber: i + 1);
      }
    }
    return copyWith(sets: newSets);
  }

  /// Total volume for this exercise
  double get totalVolume {
    return sets.where((s) => s.completed).fold(0, (sum, s) => sum + s.volume);
  }

  /// Number of completed sets
  int get completedSetsCount {
    return sets.where((s) => s.completed).length;
  }

  /// Best set (highest volume)
  WorkoutSet? get bestSet {
    final completed = sets.where((s) => s.completed).toList();
    if (completed.isEmpty) return null;
    return completed.reduce((a, b) => a.volume > b.volume ? a : b);
  }

  /// Estimated 1RM for the exercise
  double? get estimatedOneRepMax {
    final completed = sets.where((s) => s.completed).toList();
    if (completed.isEmpty) return null;
    final best = completed.reduce((a, b) => a.volume > b.volume ? a : b);
    return best.estimatedOneRepMax;
  }
}

// ==================== Workout Session ====================

class WorkoutSession {
  final String id;
  final String name;
  final String? templateId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<WorkoutExercise> exercises;
  final String? notes;
  final WorkoutStatus status;

  WorkoutSession({
    String? id,
    this.name = 'Entrenamiento',
    this.templateId,
    DateTime? startedAt,
    this.finishedAt,
    List<WorkoutExercise>? exercises,
    this.notes,
    this.status = WorkoutStatus.inProgress,
  }) : id = id ?? const Uuid().v4(),
       startedAt = startedAt ?? DateTime.now(),
       exercises = exercises ?? [];

  WorkoutSession copyWith({
    String? name,
    DateTime? finishedAt,
    List<WorkoutExercise>? exercises,
    String? notes,
    WorkoutStatus? status,
  }) {
    return WorkoutSession(
      id: id,
      name: name ?? this.name,
      templateId: templateId,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  /// Add exercise to session
  WorkoutSession addExercise(WorkoutExercise exercise) {
    final newExercises = List<WorkoutExercise>.from(exercises);
    newExercises.add(exercise.copyWith(order: newExercises.length));
    return copyWith(exercises: newExercises);
  }

  /// Remove exercise from session
  WorkoutSession removeExercise(int index) {
    final newExercises = List<WorkoutExercise>.from(exercises);
    if (index >= 0 && index < newExercises.length) {
      newExercises.removeAt(index);
      // Reorder
      for (int i = 0; i < newExercises.length; i++) {
        newExercises[i] = newExercises[i].copyWith(order: i);
      }
    }
    return copyWith(exercises: newExercises);
  }

  /// Update exercise
  WorkoutSession updateExercise(int index, WorkoutExercise exercise) {
    final newExercises = List<WorkoutExercise>.from(exercises);
    if (index >= 0 && index < newExercises.length) {
      newExercises[index] = exercise;
    }
    return copyWith(exercises: newExercises);
  }

  /// Finish the session
  WorkoutSession finish() {
    return copyWith(
      finishedAt: DateTime.now(),
      status: WorkoutStatus.completed,
    );
  }

  /// Cancel the session
  WorkoutSession cancel() {
    return copyWith(status: WorkoutStatus.cancelled);
  }

  /// Duration of the workout
  Duration get duration {
    final end = finishedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Formatted duration string
  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  /// Total volume for the session
  double get totalVolume {
    return exercises.fold(0, (sum, e) => sum + e.totalVolume);
  }

  /// Total completed sets
  int get totalCompletedSets {
    return exercises.fold(0, (sum, e) => sum + e.completedSetsCount);
  }

  /// Total exercises
  int get totalExercises => exercises.length;

  /// Generate AI evaluation context
  Map<String, dynamic> toAIContext() {
    return {
      'workout_name': name,
      'duration_minutes': duration.inMinutes,
      'total_volume': totalVolume,
      'total_sets': totalCompletedSets,
      'exercises': exercises
          .map(
            (e) => {
              'name': e.exerciseName,
              'sets': e.completedSetsCount,
              'volume': e.totalVolume,
              'best_set': e.bestSet != null
                  ? '${e.bestSet!.weight}kg x ${e.bestSet!.reps}'
                  : null,
              'estimated_1rm': e.estimatedOneRepMax?.toStringAsFixed(1),
            },
          )
          .toList(),
    };
  }
}

enum WorkoutStatus { inProgress, completed, cancelled }

// ==================== RPE Scale ====================

class RPEScale {
  static const Map<int, RPEDescription> descriptions = {
    1: RPEDescription(
      'Muy fácil',
      'Podrías hacer muchas más reps',
      Color(0xFF10B981),
    ),
    2: RPEDescription(
      'Fácil',
      'Podrías hacer bastantes más',
      Color(0xFF10B981),
    ),
    3: RPEDescription(
      'Moderado-',
      'Podrías hacer bastantes más',
      Color(0xFF10B981),
    ),
    4: RPEDescription(
      'Moderado',
      'Podrías hacer algunas más',
      Color(0xFF22C55E),
    ),
    5: RPEDescription('Moderado+', 'Podrías hacer 4-5 más', Color(0xFF22C55E)),
    6: RPEDescription('Algo duro', 'Podrías hacer 3-4 más', Color(0xFFF59E0B)),
    7: RPEDescription('Difícil', 'Podrías hacer 2-3 más', Color(0xFFF59E0B)),
    8: RPEDescription(
      'Muy difícil',
      'Podrías hacer 1-2 más',
      Color(0xFFF97316),
    ),
    9: RPEDescription('Casi máximo', 'Podrías hacer 1 más', Color(0xFFEF4444)),
    10: RPEDescription(
      'Máximo',
      'No podrías hacer ninguna más',
      Color(0xFFDC2626),
    ),
  };

  static String getLabel(int rpe) => descriptions[rpe]?.label ?? '';
  static String getDescription(int rpe) => descriptions[rpe]?.description ?? '';
  static Color getColor(int rpe) =>
      descriptions[rpe]?.color ?? const Color(0xFF6366F1);
}

class RPEDescription {
  final String label;
  final String description;
  final Color color;

  const RPEDescription(this.label, this.description, this.color);
}
