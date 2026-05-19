import 'package:uuid/uuid.dart';

// ==================== Workout Record (para persistencia) ====================

class WorkoutRecord {
  final String id;
  final String routineName;
  final DateTime date;
  final int durationSeconds;
  final List<ExerciseRecord> exercises;
  final double totalVolume;
  final int totalSets;
  final int completedSets;
  final String? aiEvaluation;
  final Map<String, dynamic> metadata;

  const WorkoutRecord({
    required this.id,
    required this.routineName,
    required this.date,
    required this.durationSeconds,
    required this.exercises,
    required this.totalVolume,
    required this.totalSets,
    required this.completedSets,
    this.aiEvaluation,
    this.metadata = const {},
  });

  factory WorkoutRecord.create({
    required String routineName,
    required int durationSeconds,
    required List<ExerciseRecord> exercises,
    String? aiEvaluation,
  }) {
    return WorkoutRecord(
      id: const Uuid().v4(),
      routineName: routineName,
      date: DateTime.now(),
      durationSeconds: durationSeconds,
      exercises: exercises,
      totalVolume: exercises.fold(0, (sum, e) => sum + e.totalVolume),
      totalSets: exercises.fold(0, (sum, e) => sum + e.totalSets),
      completedSets: exercises.fold(0, (sum, e) => sum + e.completedSets),
      aiEvaluation: aiEvaluation,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineName': routineName,
    'date': date.toIso8601String(),
    'durationSeconds': durationSeconds,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'totalVolume': totalVolume,
    'totalSets': totalSets,
    'completedSets': completedSets,
    'aiEvaluation': aiEvaluation,
    'metadata': metadata,
  };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
    id: json['id'] as String,
    routineName: json['routineName'] as String,
    date: DateTime.parse(json['date'] as String),
    durationSeconds: json['durationSeconds'] as int,
    exercises: (json['exercises'] as List)
        .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalVolume: (json['totalVolume'] as num).toDouble(),
    totalSets: json['totalSets'] as int,
    completedSets: json['completedSets'] as int,
    aiEvaluation: json['aiEvaluation'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
  );

  /// Generate AI context string for daily report
  String toAIContext() {
    final buffer = StringBuffer();
    buffer.writeln('=== ENTRENAMIENTO: $routineName ===');
    buffer.writeln('Fecha: ${date.day}/${date.month}/${date.year}');
    buffer.writeln('Duración: ${durationSeconds ~/ 60} minutos');
    buffer.writeln('Volumen total: ${totalVolume.toStringAsFixed(0)} kg');
    buffer.writeln('Series: $completedSets/$totalSets');
    buffer.writeln('');

    for (final exercise in exercises) {
      buffer.writeln('**${exercise.exerciseName}**');
      for (final set in exercise.sets) {
        if (set.completed) {
          buffer.writeln(
            '  Serie ${set.setNumber}: ${set.weight}kg x ${set.reps} reps (RPE: ${set.rpe ?? '-'})',
          );
        }
      }
      buffer.writeln(
        '  Volumen: ${exercise.totalVolume.toStringAsFixed(0)} kg',
      );
      buffer.writeln('');
    }

    return buffer.toString();
  }
}

class ExerciseRecord {
  final String exerciseId;
  final String exerciseName;
  final String category;
  final List<SetRecord> sets;
  final int restSeconds;

  const ExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.sets,
    this.restSeconds = 90,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'category': category,
    'sets': sets.map((s) => s.toJson()).toList(),
    'restSeconds': restSeconds,
  };

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) => ExerciseRecord(
    exerciseId: json['exerciseId'] as String,
    exerciseName: json['exerciseName'] as String,
    category: json['category'] as String,
    sets: (json['sets'] as List)
        .map((s) => SetRecord.fromJson(s as Map<String, dynamic>))
        .toList(),
    restSeconds: json['restSeconds'] as int? ?? 90,
  );

  double get totalVolume {
    return sets
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + (s.weight * s.reps));
  }

  int get totalSets => sets.length;
  int get completedSets => sets.where((s) => s.completed).length;
}

class SetRecord {
  final int setNumber;
  final int targetReps;
  final int reps;
  final double weight;
  final String type; // normal, dropSet, superset, failure, warmup
  final int? rpe;
  final bool completed;
  final DateTime? completedAt;

  const SetRecord({
    required this.setNumber,
    required this.targetReps,
    this.reps = 0,
    this.weight = 0,
    this.type = 'normal',
    this.rpe,
    this.completed = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'targetReps': targetReps,
    'reps': reps,
    'weight': weight,
    'type': type,
    'rpe': rpe,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory SetRecord.fromJson(Map<String, dynamic> json) => SetRecord(
    setNumber: json['setNumber'] as int,
    targetReps: json['targetReps'] as int,
    reps: json['reps'] as int? ?? 0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0,
    type: json['type'] as String? ?? 'normal',
    rpe: json['rpe'] as int?,
    completed: json['completed'] as bool? ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
  );
}

// ==================== Daily Health Snapshot ====================

class DailyHealthSnapshot {
  final DateTime date;
  final double? weight;
  final int? sleepHours;
  final int? sleepMinutes;
  final int? steps;
  final int? waterGlasses;
  final List<String> completedHabits;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final int? heartRateAvg;
  final String? mood;
  final String? notes;

  const DailyHealthSnapshot({
    required this.date,
    this.weight,
    this.sleepHours,
    this.sleepMinutes,
    this.steps,
    this.waterGlasses,
    this.completedHabits = const [],
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.heartRateAvg,
    this.mood,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'sleepHours': sleepHours,
    'sleepMinutes': sleepMinutes,
    'steps': steps,
    'waterGlasses': waterGlasses,
    'completedHabits': completedHabits,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'heartRateAvg': heartRateAvg,
    'mood': mood,
    'notes': notes,
  };

  factory DailyHealthSnapshot.fromJson(Map<String, dynamic> json) =>
      DailyHealthSnapshot(
        date: DateTime.parse(json['date'] as String),
        weight: (json['weight'] as num?)?.toDouble(),
        sleepHours: json['sleepHours'] as int?,
        sleepMinutes: json['sleepMinutes'] as int?,
        steps: json['steps'] as int?,
        waterGlasses: json['waterGlasses'] as int?,
        completedHabits:
            (json['completedHabits'] as List?)?.cast<String>() ?? [],
        calories: json['calories'] as int?,
        protein: (json['protein'] as num?)?.toDouble(),
        carbs: (json['carbs'] as num?)?.toDouble(),
        fat: (json['fat'] as num?)?.toDouble(),
        heartRateAvg: json['heartRateAvg'] as int?,
        mood: json['mood'] as String?,
        notes: json['notes'] as String?,
      );

  String toAIContext() {
    final buffer = StringBuffer();
    buffer.writeln(
      '=== DATOS DEL DÍA ${date.day}/${date.month}/${date.year} ===',
    );
    if (weight != null) buffer.writeln('Peso: $weight kg');
    if (sleepHours != null) {
      buffer.writeln('Sueño: ${sleepHours}h ${sleepMinutes ?? 0}m');
    }
    if (steps != null) buffer.writeln('Pasos: $steps');
    if (waterGlasses != null) buffer.writeln('Agua: $waterGlasses vasos');
    if (calories != null) buffer.writeln('Calorías: $calories kcal');
    if (protein != null) buffer.writeln('Proteína: $protein g');
    if (carbs != null) buffer.writeln('Carbos: $carbs g');
    if (fat != null) buffer.writeln('Grasas: $fat g');
    if (heartRateAvg != null) buffer.writeln('FC promedio: $heartRateAvg bpm');
    if (mood != null) buffer.writeln('Ánimo: $mood');
    if (completedHabits.isNotEmpty) {
      buffer.writeln('Hábitos completados: ${completedHabits.join(", ")}');
    }
    return buffer.toString();
  }
}
