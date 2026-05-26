import 'package:uuid/uuid.dart';

import 'package:dead_porky/features/nutrition/domain/entities/nutrition_entry.dart';

class NutritionRecipe {
  const NutritionRecipe({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.ingredients,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final MealType mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final List<String> ingredients;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NutritionRecipe.create({
    required String name,
    required MealType mealType,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    required List<String> ingredients,
    String? notes,
  }) {
    final now = DateTime.now();
    return NutritionRecipe(
      id: const Uuid().v4(),
      name: name,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      ingredients: ingredients,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  NutritionRecipe copyWith({
    String? id,
    String? name,
    MealType? mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    List<String>? ingredients,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      ingredients: ingredients ?? this.ingredients,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  NutritionEntry toEntry({
    required DateTime consumedAt,
    MealType? mealType,
    double multiplier = 1,
  }) {
    final factor = multiplier.clamp(0.5, 3.0).toDouble();
    return NutritionEntry.create(
      name: factor == 1 ? name : '$name x${_formatFactor(factor)}',
      mealType: mealType ?? this.mealType,
      calories: (calories * factor).round(),
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      confidence: 0.95,
      consumedAt: consumedAt,
    );
  }
}

String _formatFactor(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}
