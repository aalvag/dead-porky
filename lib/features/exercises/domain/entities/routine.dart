import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dead_porky/features/exercises/data/exercise_library.dart';
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_real.dart';

// ==================== Entities ====================

class Routine {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final Color color;
  final List<RoutineExercise> exercises;
  final int estimatedMinutes;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int timesUsed;

  Routine({
    String? id,
    required this.name,
    this.description,
    this.icon = '🏋️',
    this.color = const Color(0xFF6366F1),
    required this.exercises,
    this.estimatedMinutes = 60,
    DateTime? createdAt,
    this.lastUsed,
    this.timesUsed = 0,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Routine copyWith({DateTime? lastUsed, int? timesUsed}) {
    return Routine(
      id: id,
      name: name,
      description: description,
      icon: icon,
      color: color,
      exercises: exercises,
      estimatedMinutes: estimatedMinutes,
      createdAt: createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      timesUsed: timesUsed ?? this.timesUsed,
    );
  }
}

class RoutineExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final List<RoutineSet> sets;
  final int restSeconds;
  final int order;

  RoutineExercise({
    String? id,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.sets,
    this.restSeconds = 90,
    this.order = 0,
  }) : id = id ?? const Uuid().v4();

  RoutineExercise copyWith({List<RoutineSet>? sets, int? order}) {
    return RoutineExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      category: category,
      sets: sets ?? this.sets,
      restSeconds: restSeconds,
      order: order ?? this.order,
    );
  }
}

class RoutineSet {
  final int setNumber;
  final int targetReps;
  final int? minReps;
  final int? maxReps;
  final SetType type;

  RoutineSet({
    required this.setNumber,
    required this.targetReps,
    this.minReps,
    this.maxReps,
    this.type = SetType.normal,
  });
}

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

// ==================== Preset Routines ====================

class PresetRoutines {
  static final List<Routine> routines = [
    Routine(
      name: 'Push Day',
      description: 'Pecho, Hombro, Tríceps',
      icon: '💪',
      color: const Color(0xFF6366F1),
      estimatedMinutes: 60,
      exercises: [
        RoutineExercise(
          exerciseId: 'bench_press',
          exerciseName: 'Press de Banca',
          category: 'chest',
          restSeconds: 120,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 12,
              type: SetType.warmup,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 4,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 5,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'incline_bench_press',
          exerciseName: 'Press Inclinado Mancuernas',
          category: 'chest',
          restSeconds: 90,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'dumbbell_fly',
          exerciseName: 'Aperturas con Mancuernas',
          category: 'chest',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'overhead_press',
          exerciseName: 'Press Militar',
          category: 'shoulders',
          restSeconds: 90,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'lateral_raise',
          exerciseName: 'Elevaciones Laterales',
          category: 'shoulders',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 15,
              minReps: 12,
              maxReps: 20,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 15,
              minReps: 12,
              maxReps: 20,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 15,
              minReps: 12,
              maxReps: 20,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'tricep_pushdown',
          exerciseName: 'Extensión de Tríceps',
          category: 'arms',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
          ],
        ),
      ],
    ),
    Routine(
      name: 'Pull Day',
      description: 'Espalda, Bíceps',
      icon: '🔙',
      color: const Color(0xFFEF4444),
      estimatedMinutes: 55,
      exercises: [
        RoutineExercise(
          exerciseId: 'pull_up',
          exerciseName: 'Dominadas',
          category: 'back',
          restSeconds: 120,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 4,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'barbell_row',
          exerciseName: 'Remo con Barra',
          category: 'back',
          restSeconds: 90,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'lat_pulldown',
          exerciseName: 'Jalón al Pecho',
          category: 'back',
          restSeconds: 90,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'face_pull',
          exerciseName: 'Face Pull',
          category: 'back',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 15,
              minReps: 12,
              maxReps: 20,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 15,
              minReps: 12,
              maxReps: 20,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 15,
              minReps: 12,
              maxReps: 20,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'barbell_curl',
          exerciseName: 'Curl con Barra',
          category: 'arms',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'hammer_curl',
          exerciseName: 'Curl Martillo',
          category: 'arms',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
          ],
        ),
      ],
    ),
    Routine(
      name: 'Leg Day',
      description: 'Cuádriceps, Isquios, Glúteos, Pantorrillas',
      icon: '🦵',
      color: const Color(0xFF10B981),
      estimatedMinutes: 65,
      exercises: [
        RoutineExercise(
          exerciseId: 'squat',
          exerciseName: 'Sentadilla',
          category: 'legs',
          restSeconds: 180,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              type: SetType.warmup,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 4,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
            RoutineSet(
              setNumber: 5,
              targetReps: 8,
              minReps: 6,
              maxReps: 10,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'romanian_deadlift',
          exerciseName: 'Peso Muerto Rumano',
          category: 'legs',
          restSeconds: 120,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'leg_press',
          exerciseName: 'Prensa de Piernas',
          category: 'legs',
          restSeconds: 90,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'leg_curl',
          exerciseName: 'Curl Femoral',
          category: 'legs',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 12,
              minReps: 10,
              maxReps: 15,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'calf_raise',
          exerciseName: 'Elevación de Talones',
          category: 'legs',
          restSeconds: 60,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 20,
              minReps: 15,
              maxReps: 25,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 20,
              minReps: 15,
              maxReps: 25,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 20,
              minReps: 15,
              maxReps: 25,
            ),
            RoutineSet(
              setNumber: 4,
              targetReps: 20,
              minReps: 15,
              maxReps: 25,
            ),
          ],
        ),
      ],
    ),
    Routine(
      name: 'Full Body',
      description: 'Cuerpo completo',
      icon: '🔥',
      color: const Color(0xFFF59E0B),
      estimatedMinutes: 75,
      exercises: [
        RoutineExercise(
          exerciseId: 'squat',
          exerciseName: 'Sentadilla',
          category: 'legs',
          restSeconds: 120,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'bench_press',
          exerciseName: 'Press de Banca',
          category: 'chest',
          restSeconds: 120,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'barbell_row',
          exerciseName: 'Remo con Barra',
          category: 'back',
          restSeconds: 120,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 3,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
        RoutineExercise(
          exerciseId: 'overhead_press',
          exerciseName: 'Press Militar',
          category: 'shoulders',
          restSeconds: 90,
          sets: [
            RoutineSet(
              setNumber: 1,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
            RoutineSet(
              setNumber: 2,
              targetReps: 10,
              minReps: 8,
              maxReps: 12,
            ),
          ],
        ),
      ],
    ),
  ];
}
