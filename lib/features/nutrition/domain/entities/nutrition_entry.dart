import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class NutritionEntry {
  const NutritionEntry({
    required this.id,
    required this.name,
    required this.mealType,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.imageUrl,
    this.confidence = 0,
    required this.consumedAt,
  });

  final String id;
  final String name;
  final MealType mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String? imageUrl;
  final double confidence;
  final DateTime consumedAt;

  factory NutritionEntry.create({
    required String name,
    required MealType mealType,
    int calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    double fiber = 0,
    String? imageUrl,
    double confidence = 0,
    DateTime? consumedAt,
  }) {
    return NutritionEntry(
      id: const Uuid().v4(),
      name: name,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      imageUrl: imageUrl,
      confidence: confidence,
      consumedAt: consumedAt ?? DateTime.now(),
    );
  }
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Desayuno';
      case MealType.lunch:
        return 'Almuerzo';
      case MealType.dinner:
        return 'Cena';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.nightlight;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  int get defaultHour {
    switch (this) {
      case MealType.breakfast:
        return 8;
      case MealType.lunch:
        return 13;
      case MealType.dinner:
        return 20;
      case MealType.snack:
        return 17;
    }
  }

  Color get accentColor {
    switch (this) {
      case MealType.breakfast:
        return const Color(0xFFF59E0B);
      case MealType.lunch:
        return const Color(0xFF10B981);
      case MealType.dinner:
        return const Color(0xFF6366F1);
      case MealType.snack:
        return const Color(0xFFF97316);
    }
  }
}

enum FoodCategory {
  proteins,
  carbs,
  fats,
  vegetables,
  fruits,
  dairy,
  drinks,
  treats,
}

extension FoodCategoryX on FoodCategory {
  String get label {
    switch (this) {
      case FoodCategory.proteins:
        return 'Proteinas';
      case FoodCategory.carbs:
        return 'Carbos';
      case FoodCategory.fats:
        return 'Grasas';
      case FoodCategory.vegetables:
        return 'Verduras';
      case FoodCategory.fruits:
        return 'Frutas';
      case FoodCategory.dairy:
        return 'Lacteos';
      case FoodCategory.drinks:
        return 'Bebidas';
      case FoodCategory.treats:
        return 'Extras';
    }
  }

  IconData get icon {
    switch (this) {
      case FoodCategory.proteins:
        return Icons.fitness_center;
      case FoodCategory.carbs:
        return Icons.rice_bowl;
      case FoodCategory.fats:
        return Icons.opacity;
      case FoodCategory.vegetables:
        return Icons.eco;
      case FoodCategory.fruits:
        return Icons.apple;
      case FoodCategory.dairy:
        return Icons.local_drink;
      case FoodCategory.drinks:
        return Icons.local_cafe;
      case FoodCategory.treats:
        return Icons.icecream;
    }
  }

  Color get accentColor {
    switch (this) {
      case FoodCategory.proteins:
        return const Color(0xFFEF4444);
      case FoodCategory.carbs:
        return const Color(0xFF3B82F6);
      case FoodCategory.fats:
        return const Color(0xFFF59E0B);
      case FoodCategory.vegetables:
        return const Color(0xFF10B981);
      case FoodCategory.fruits:
        return const Color(0xFFF97316);
      case FoodCategory.dairy:
        return const Color(0xFF06B6D4);
      case FoodCategory.drinks:
        return const Color(0xFF8B5CF6);
      case FoodCategory.treats:
        return const Color(0xFFEC4899);
    }
  }
}

class FoodPreset {
  const FoodPreset({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.category,
  });

  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final FoodCategory category;

  NutritionEntry toNutritionEntry({
    required MealType mealType,
    required DateTime consumedAt,
    double multiplier = 1,
  }) {
    final factor = multiplier.clamp(0.5, 3.0).toDouble();
    final suffix = factor == 1 ? '' : ' x${_formatFactor(factor)}';

    return NutritionEntry.create(
      name: '$name$suffix',
      mealType: mealType,
      calories: (calories * factor).round(),
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      consumedAt: consumedAt,
      confidence: 0.92,
    );
  }

  String macroLine({double multiplier = 1}) {
    final factor = multiplier.clamp(0.5, 3.0).toDouble();
    return '${(calories * factor).round()} kcal · P ${(protein * factor).toStringAsFixed(0)} g · C ${(carbs * factor).toStringAsFixed(0)} g · G ${(fat * factor).toStringAsFixed(0)} g · Fibra ${(fiber * factor).toStringAsFixed(0)} g';
  }
}

String _formatFactor(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class PresetFoods {
  static const List<FoodPreset> foods = [
    FoodPreset(
      name: 'Pechuga de pollo (100 g)',
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
      fiber: 0,
      category: FoodCategory.proteins,
    ),
    FoodPreset(
      name: 'Huevos (2 unidades)',
      calories: 156,
      protein: 12,
      carbs: 1.2,
      fat: 10.6,
      fiber: 0,
      category: FoodCategory.proteins,
    ),
    FoodPreset(
      name: 'Atun en lata (100 g)',
      calories: 116,
      protein: 26,
      carbs: 0,
      fat: 0.8,
      fiber: 0,
      category: FoodCategory.proteins,
    ),
    FoodPreset(
      name: 'Salmon (100 g)',
      calories: 208,
      protein: 20,
      carbs: 0,
      fat: 13,
      fiber: 0,
      category: FoodCategory.proteins,
    ),
    FoodPreset(
      name: 'Tofu firme (100 g)',
      calories: 76,
      protein: 8,
      carbs: 1.9,
      fat: 4.8,
      fiber: 0.3,
      category: FoodCategory.proteins,
    ),
    FoodPreset(
      name: 'Yogur griego natural (170 g)',
      calories: 120,
      protein: 17,
      carbs: 6,
      fat: 2,
      fiber: 0,
      category: FoodCategory.dairy,
    ),
    FoodPreset(
      name: 'Avena (50 g)',
      calories: 190,
      protein: 6.5,
      carbs: 33,
      fat: 3.5,
      fiber: 5.1,
      category: FoodCategory.carbs,
    ),
    FoodPreset(
      name: 'Arroz blanco (100 g cocido)',
      calories: 130,
      protein: 2.7,
      carbs: 28,
      fat: 0.3,
      fiber: 0.4,
      category: FoodCategory.carbs,
    ),
    FoodPreset(
      name: 'Pasta (100 g cocida)',
      calories: 131,
      protein: 5,
      carbs: 25,
      fat: 1.1,
      fiber: 1.8,
      category: FoodCategory.carbs,
    ),
    FoodPreset(
      name: 'Pan integral (2 rebanadas)',
      calories: 160,
      protein: 8,
      carbs: 28,
      fat: 2,
      fiber: 4,
      category: FoodCategory.carbs,
    ),
    FoodPreset(
      name: 'Papa asada (100 g)',
      calories: 93,
      protein: 2.5,
      carbs: 21,
      fat: 0.1,
      fiber: 2.2,
      category: FoodCategory.carbs,
    ),
    FoodPreset(
      name: 'Batata (100 g)',
      calories: 86,
      protein: 1.6,
      carbs: 20,
      fat: 0.1,
      fiber: 3,
      category: FoodCategory.carbs,
    ),
    FoodPreset(
      name: 'Aguacate (1/2 unidad)',
      calories: 120,
      protein: 1.5,
      carbs: 6,
      fat: 11,
      fiber: 5,
      category: FoodCategory.fats,
    ),
    FoodPreset(
      name: 'Aceite de oliva (1 cda)',
      calories: 120,
      protein: 0,
      carbs: 0,
      fat: 14,
      fiber: 0,
      category: FoodCategory.fats,
    ),
    FoodPreset(
      name: 'Almendras (30 g)',
      calories: 173,
      protein: 6,
      carbs: 6,
      fat: 15,
      fiber: 3.5,
      category: FoodCategory.fats,
    ),
    FoodPreset(
      name: 'Nueces (30 g)',
      calories: 185,
      protein: 4.3,
      carbs: 3.9,
      fat: 18.5,
      fiber: 1.9,
      category: FoodCategory.fats,
    ),
    FoodPreset(
      name: 'Brocoli (100 g)',
      calories: 34,
      protein: 2.8,
      carbs: 7,
      fat: 0.4,
      fiber: 2.6,
      category: FoodCategory.vegetables,
    ),
    FoodPreset(
      name: 'Espinaca (100 g)',
      calories: 23,
      protein: 2.9,
      carbs: 3.6,
      fat: 0.4,
      fiber: 2.2,
      category: FoodCategory.vegetables,
    ),
    FoodPreset(
      name: 'Ensalada mixta',
      calories: 25,
      protein: 1.5,
      carbs: 4,
      fat: 0.3,
      fiber: 2,
      category: FoodCategory.vegetables,
    ),
    FoodPreset(
      name: 'Manzana (1 unidad)',
      calories: 95,
      protein: 0.5,
      carbs: 25,
      fat: 0.3,
      fiber: 4.4,
      category: FoodCategory.fruits,
    ),
    FoodPreset(
      name: 'Platano (1 unidad)',
      calories: 105,
      protein: 1.3,
      carbs: 27,
      fat: 0.4,
      fiber: 3.1,
      category: FoodCategory.fruits,
    ),
    FoodPreset(
      name: 'Frutos rojos (100 g)',
      calories: 57,
      protein: 0.7,
      carbs: 14,
      fat: 0.3,
      fiber: 5.4,
      category: FoodCategory.fruits,
    ),
    FoodPreset(
      name: 'Naranja (1 unidad)',
      calories: 62,
      protein: 1.2,
      carbs: 15,
      fat: 0.2,
      fiber: 3.1,
      category: FoodCategory.fruits,
    ),
    FoodPreset(
      name: 'Cafe con leche',
      calories: 68,
      protein: 3.4,
      carbs: 5.5,
      fat: 3,
      fiber: 0,
      category: FoodCategory.drinks,
    ),
    FoodPreset(
      name: 'Smoothie proteico',
      calories: 220,
      protein: 25,
      carbs: 18,
      fat: 4,
      fiber: 2,
      category: FoodCategory.drinks,
    ),
    FoodPreset(
      name: 'Chocolate negro (30 g)',
      calories: 170,
      protein: 2,
      carbs: 13,
      fat: 12,
      fiber: 3,
      category: FoodCategory.treats,
    ),
    FoodPreset(
      name: 'Granola (50 g)',
      calories: 235,
      protein: 5,
      carbs: 32,
      fat: 9,
      fiber: 4,
      category: FoodCategory.treats,
    ),
  ];

  static List<FoodPreset> filter({String query = '', FoodCategory? category}) {
    final normalizedQuery = query.trim().toLowerCase();

    return foods.where((food) {
      final matchesCategory = category == null || food.category == category;
      if (!matchesCategory) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final haystack = '${food.name} ${food.category.label}'.toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }
}
