import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ==================== Entities ====================

class WorkoutTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateExercise> exercises;
  final int estimatedDuration; // minutes
  final String category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    this.estimatedDuration = 60,
    this.category = 'custom',
    this.isFavorite = false,
    required this.createdAt,
    this.lastUsed,
  });

  factory WorkoutTemplate.create({
    required String name,
    String? description,
    required List<TemplateExercise> exercises,
    int estimatedDuration = 60,
    String category = 'custom',
  }) {
    return WorkoutTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      exercises: exercises,
      estimatedDuration: estimatedDuration,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  WorkoutTemplate copyWith({bool? isFavorite, DateTime? lastUsed}) {
    return WorkoutTemplate(
      id: id,
      name: name,
      description: description,
      exercises: exercises,
      estimatedDuration: estimatedDuration,
      category: category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}

class TemplateExercise {
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final String targetReps; // e.g., "8-12"
  final int restSeconds;
  final String? notes;

  const TemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    this.restSeconds = 90,
    this.notes,
  });
}

// ==================== Preset Templates ====================

class PresetTemplates {
  static final List<WorkoutTemplate> templates = [
    WorkoutTemplate.create(
      name: 'Push Day (Pecho/Hombro/Tríceps)',
      description: 'Rutina de empuje completa',
      estimatedDuration: 60,
      category: 'push',
      exercises: [
        const TemplateExercise(
          exerciseId: 'bench_press',
          exerciseName: 'Press de Banca',
          targetSets: 4,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'incline_bench_press',
          exerciseName: 'Press Inclinado',
          targetSets: 3,
          targetReps: '10-12',
        ),
        const TemplateExercise(
          exerciseId: 'dumbbell_fly',
          exerciseName: 'Aperturas',
          targetSets: 3,
          targetReps: '12-15',
        ),
        const TemplateExercise(
          exerciseId: 'overhead_press',
          exerciseName: 'Press Militar',
          targetSets: 4,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'lateral_raise',
          exerciseName: 'Elevaciones Laterales',
          targetSets: 3,
          targetReps: '15-20',
        ),
        const TemplateExercise(
          exerciseId: 'tricep_pushdown',
          exerciseName: 'Extensión Tríceps',
          targetSets: 3,
          targetReps: '12-15',
        ),
      ],
    ),
    WorkoutTemplate.create(
      name: 'Pull Day (Espalda/Bíceps)',
      description: 'Rutina de tirón completa',
      estimatedDuration: 55,
      category: 'pull',
      exercises: [
        const TemplateExercise(
          exerciseId: 'pull_up',
          exerciseName: 'Dominadas',
          targetSets: 4,
          targetReps: '6-10',
        ),
        const TemplateExercise(
          exerciseId: 'barbell_row',
          exerciseName: 'Remo con Barra',
          targetSets: 4,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'lat_pulldown',
          exerciseName: 'Jalón al Pecho',
          targetSets: 3,
          targetReps: '10-12',
        ),
        const TemplateExercise(
          exerciseId: 'face_pull',
          exerciseName: 'Face Pull',
          targetSets: 3,
          targetReps: '15-20',
        ),
        const TemplateExercise(
          exerciseId: 'barbell_curl',
          exerciseName: 'Curl con Barra',
          targetSets: 3,
          targetReps: '10-12',
        ),
        const TemplateExercise(
          exerciseId: 'hammer_curl',
          exerciseName: 'Curl Martillo',
          targetSets: 3,
          targetReps: '12-15',
        ),
      ],
    ),
    WorkoutTemplate.create(
      name: 'Leg Day (Piernas)',
      description: 'Rutina de piernas completa',
      estimatedDuration: 65,
      category: 'legs',
      exercises: [
        const TemplateExercise(
          exerciseId: 'squat',
          exerciseName: 'Sentadilla',
          targetSets: 4,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'romanian_deadlift',
          exerciseName: 'Peso Muerto Rumano',
          targetSets: 4,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'leg_press',
          exerciseName: 'Prensa',
          targetSets: 3,
          targetReps: '10-12',
        ),
        const TemplateExercise(
          exerciseId: 'leg_curl',
          exerciseName: 'Curl Femoral',
          targetSets: 3,
          targetReps: '12-15',
        ),
        const TemplateExercise(
          exerciseId: 'leg_extension',
          exerciseName: 'Extensión',
          targetSets: 3,
          targetReps: '12-15',
        ),
        const TemplateExercise(
          exerciseId: 'calf_raise',
          exerciseName: 'Pantorrillas',
          targetSets: 4,
          targetReps: '15-20',
        ),
      ],
    ),
    WorkoutTemplate.create(
      name: 'Full Body',
      description: 'Rutina de cuerpo completo',
      estimatedDuration: 75,
      category: 'fullbody',
      exercises: [
        const TemplateExercise(
          exerciseId: 'squat',
          exerciseName: 'Sentadilla',
          targetSets: 3,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'bench_press',
          exerciseName: 'Press de Banca',
          targetSets: 3,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'barbell_row',
          exerciseName: 'Remo con Barra',
          targetSets: 3,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'overhead_press',
          exerciseName: 'Press Militar',
          targetSets: 3,
          targetReps: '8-10',
        ),
        const TemplateExercise(
          exerciseId: 'barbell_curl',
          exerciseName: 'Curl con Barra',
          targetSets: 2,
          targetReps: '10-12',
        ),
        const TemplateExercise(
          exerciseId: 'tricep_pushdown',
          exerciseName: 'Extensión Tríceps',
          targetSets: 2,
          targetReps: '10-12',
        ),
      ],
    ),
    WorkoutTemplate.create(
      name: 'Core & Cardio',
      description: 'Abdominales y cardio',
      estimatedDuration: 30,
      category: 'core',
      exercises: [
        const TemplateExercise(
          exerciseId: 'plank',
          exerciseName: 'Plancha',
          targetSets: 3,
          targetReps: '60s',
        ),
        const TemplateExercise(
          exerciseId: 'hanging_leg_raise',
          exerciseName: 'Elevación Piernas',
          targetSets: 3,
          targetReps: '10-15',
        ),
        const TemplateExercise(
          exerciseId: 'russian_twist',
          exerciseName: 'Giro Ruso',
          targetSets: 3,
          targetReps: '20',
        ),
        const TemplateExercise(
          exerciseId: 'mountain_climber',
          exerciseName: 'Escalador',
          targetSets: 3,
          targetReps: '30s',
        ),
        const TemplateExercise(
          exerciseId: 'burpee',
          exerciseName: 'Burpees',
          targetSets: 3,
          targetReps: '10',
        ),
      ],
    ),
  ];
}

// ==================== Workout History Item ====================

class WorkoutHistoryItem {
  final String id;
  final String name;
  final DateTime date;
  final int durationMinutes;
  final int totalSets;
  final double totalVolume;
  final List<String> exerciseNames;

  const WorkoutHistoryItem({
    required this.id,
    required this.name,
    required this.date,
    required this.durationMinutes,
    required this.totalSets,
    required this.totalVolume,
    required this.exerciseNames,
  });
}

// ==================== Preset History (for demo) ====================

class PresetHistory {
  static final List<WorkoutHistoryItem> items = [
    WorkoutHistoryItem(
      id: '1',
      name: 'Push Day',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      durationMinutes: 52,
      totalSets: 24,
      totalVolume: 12450,
      exerciseNames: [
        'Press Banca',
        'Press Inclinado',
        'Aperturas',
        'Press Militar',
        'Laterales',
        'Tríceps',
      ],
    ),
    WorkoutHistoryItem(
      id: '2',
      name: 'Pull Day',
      date: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 48,
      totalSets: 22,
      totalVolume: 11200,
      exerciseNames: [
        'Dominadas',
        'Remo Barra',
        'Jalón',
        'Face Pull',
        'Curl Barra',
        'Curl Martillo',
      ],
    ),
    WorkoutHistoryItem(
      id: '3',
      name: 'Leg Day',
      date: DateTime.now().subtract(const Duration(days: 2)),
      durationMinutes: 61,
      totalSets: 21,
      totalVolume: 15800,
      exerciseNames: [
        'Sentadilla',
        'Peso Muerto Rumano',
        'Prensa',
        'Curl Femoral',
        'Extensión',
        'Pantorrillas',
      ],
    ),
    WorkoutHistoryItem(
      id: '4',
      name: 'Full Body',
      date: DateTime.now().subtract(const Duration(days: 4)),
      durationMinutes: 55,
      totalSets: 16,
      totalVolume: 9800,
      exerciseNames: [
        'Sentadilla',
        'Press Banca',
        'Remo',
        'Press Militar',
        'Curl',
        'Tríceps',
      ],
    ),
    WorkoutHistoryItem(
      id: '5',
      name: 'Push Day',
      date: DateTime.now().subtract(const Duration(days: 6)),
      durationMinutes: 50,
      totalSets: 24,
      totalVolume: 12100,
      exerciseNames: [
        'Press Banca',
        'Press Inclinado',
        'Aperturas',
        'Press Militar',
        'Laterales',
        'Tríceps',
      ],
    ),
  ];
}
