import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ==================== Entities ====================

class Habit {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final HabitType type;
  final double? targetValue;
  final String? targetUnit;
  final HabitFrequency frequency;
  final List<int>? customDays;
  final String? reminderTime;
  final bool reminderEnabled;
  final String category;
  final int currentStreak;
  final int longestStreak;
  final bool archived;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.targetValue,
    this.targetUnit,
    required this.frequency,
    this.customDays,
    this.reminderTime,
    this.reminderEnabled = false,
    required this.category,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.archived = false,
    required this.createdAt,
  });

  factory Habit.create({
    required String name,
    required String icon,
    required Color color,
    required HabitType type,
    double? targetValue,
    String? targetUnit,
    required HabitFrequency frequency,
    required String category,
  }) {
    return Habit(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      color: color,
      type: type,
      targetValue: targetValue,
      targetUnit: targetUnit,
      frequency: frequency,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  Habit copyWith({
    String? name,
    String? icon,
    Color? color,
    HabitType? type,
    double? targetValue,
    String? targetUnit,
    HabitFrequency? frequency,
    int? currentStreak,
    int? longestStreak,
    bool? archived,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      frequency: frequency ?? this.frequency,
      customDays: customDays,
      reminderTime: reminderTime,
      reminderEnabled: reminderEnabled,
      category: category,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      archived: archived ?? this.archived,
      createdAt: createdAt,
    );
  }
}

enum HabitType { boolean, quantity, duration, timer }

enum HabitFrequency { daily, weekly, weekdays, custom }

extension HabitTypeX on HabitType {
  String get label {
    switch (this) {
      case HabitType.boolean:
        return 'Sí/No';
      case HabitType.quantity:
        return 'Cantidad';
      case HabitType.duration:
        return 'Duración';
      case HabitType.timer:
        return 'Temporizador';
    }
  }
}

extension HabitFrequencyX on HabitFrequency {
  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Diario';
      case HabitFrequency.weekly:
        return 'Semanal';
      case HabitFrequency.weekdays:
        return 'Días laborales';
      case HabitFrequency.custom:
        return 'Personalizado';
    }
  }
}

// ==================== Preset Habits ====================

class PresetHabits {
  static final List<Map<String, dynamic>> habits = [
    {
      'name': 'Hidratación',
      'icon': '💧',
      'color': const Color(0xFF06B6D4),
      'type': HabitType.quantity,
      'targetValue': 8.0,
      'targetUnit': 'vasos',
      'category': 'health',
    },
    {
      'name': 'Ejercicio',
      'icon': '🏃',
      'color': const Color(0xFF10B981),
      'type': HabitType.duration,
      'targetValue': 30.0,
      'targetUnit': 'min',
      'category': 'fitness',
    },
    {
      'name': 'Meditación',
      'icon': '🧘',
      'color': const Color(0xFF8B5CF6),
      'type': HabitType.duration,
      'targetValue': 10.0,
      'targetUnit': 'min',
      'category': 'mindfulness',
    },
    {
      'name': 'Lectura',
      'icon': '📚',
      'color': const Color(0xFFF59E0B),
      'type': HabitType.duration,
      'targetValue': 20.0,
      'targetUnit': 'min',
      'category': 'personal',
    },
    {
      'name': 'Dormir 8 horas',
      'icon': '😴',
      'color': const Color(0xFF6366F1),
      'type': HabitType.boolean,
      'category': 'sleep',
    },
    {
      'name': 'Sin alcohol',
      'icon': '🚫',
      'color': const Color(0xFFEF4444),
      'type': HabitType.boolean,
      'category': 'health',
    },
    {
      'name': 'Frutas y verduras',
      'icon': '🥗',
      'color': const Color(0xFF22C55E),
      'type': HabitType.quantity,
      'targetValue': 5.0,
      'targetUnit': 'porciones',
      'category': 'nutrition',
    },
    {
      'name': 'Caminar',
      'icon': '🚶',
      'color': const Color(0xFF3B82F6),
      'type': HabitType.quantity,
      'targetValue': 10000.0,
      'targetUnit': 'pasos',
      'category': 'fitness',
    },
    {
      'name': 'Estiramientos',
      'icon': '🤸',
      'color': const Color(0xFFEC4899),
      'type': HabitType.duration,
      'targetValue': 10.0,
      'targetUnit': 'min',
      'category': 'fitness',
    },
    {
      'name': 'Diario de gratitud',
      'icon': '🙏',
      'color': const Color(0xFFF97316),
      'type': HabitType.boolean,
      'category': 'mindfulness',
    },
  ];
}
