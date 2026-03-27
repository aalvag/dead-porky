import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ==================== Entities ====================

class NutritionEntry {
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

  factory NutritionEntry.create({
    required String name,
    required MealType mealType,
    int calories = 0,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) {
    return NutritionEntry(
      id: const Uuid().v4(),
      name: name,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      consumedAt: DateTime.now(),
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
}

// ==================== Preset Foods ====================

class PresetFoods {
  static final List<Map<String, dynamic>> foods = [
    // Proteínas
    {
      'name': 'Pechuga de pollo (100g)',
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fat': 3.6,
      'category': 'proteins',
    },
    {
      'name': 'Huevos (2 unidades)',
      'calories': 156,
      'protein': 12,
      'carbs': 1.2,
      'fat': 10.6,
      'category': 'proteins',
    },
    {
      'name': 'Atún en lata (100g)',
      'calories': 116,
      'protein': 26,
      'carbs': 0,
      'fat': 0.8,
      'category': 'proteins',
    },
    {
      'name': 'Salmón (100g)',
      'calories': 208,
      'protein': 20,
      'carbs': 0,
      'fat': 13,
      'category': 'proteins',
    },
    {
      'name': 'Carne magra (100g)',
      'calories': 250,
      'protein': 26,
      'carbs': 0,
      'fat': 15,
      'category': 'proteins',
    },
    {
      'name': 'Tofu (100g)',
      'calories': 76,
      'protein': 8,
      'carbs': 1.9,
      'fat': 4.8,
      'category': 'proteins',
    },

    // Carbohidratos
    {
      'name': 'Arroz blanco (100g cocido)',
      'calories': 130,
      'protein': 2.7,
      'carbs': 28,
      'fat': 0.3,
      'category': 'carbs',
    },
    {
      'name': 'Pasta (100g cocida)',
      'calories': 131,
      'protein': 5,
      'carbs': 25,
      'fat': 1.1,
      'category': 'carbs',
    },
    {
      'name': 'Pan integral (2 rebanadas)',
      'calories': 160,
      'protein': 8,
      'carbs': 28,
      'fat': 2,
      'category': 'carbs',
    },
    {
      'name': 'Papa (100g)',
      'calories': 77,
      'protein': 2,
      'carbs': 17,
      'fat': 0.1,
      'category': 'carbs',
    },
    {
      'name': 'Avena (50g)',
      'calories': 190,
      'protein': 6.5,
      'carbs': 33,
      'fat': 3.5,
      'category': 'carbs',
    },
    {
      'name': 'Batata (100g)',
      'calories': 86,
      'protein': 1.6,
      'carbs': 20,
      'fat': 0.1,
      'category': 'carbs',
    },

    // Grasas
    {
      'name': 'Aguacate (1/2 unidad)',
      'calories': 120,
      'protein': 1.5,
      'carbs': 6,
      'fat': 11,
      'category': 'fats',
    },
    {
      'name': 'Aceite de oliva (1 cda)',
      'calories': 120,
      'protein': 0,
      'carbs': 0,
      'fat': 14,
      'category': 'fats',
    },
    {
      'name': 'Nueces (30g)',
      'calories': 185,
      'protein': 4.3,
      'carbs': 3.9,
      'fat': 18.5,
      'category': 'fats',
    },
    {
      'name': 'Almendras (30g)',
      'calories': 173,
      'protein': 6,
      'carbs': 6,
      'fat': 15,
      'category': 'fats',
    },

    // Verduras
    {
      'name': 'Brócoli (100g)',
      'calories': 34,
      'protein': 2.8,
      'carbs': 7,
      'fat': 0.4,
      'category': 'vegetables',
    },
    {
      'name': 'Espinaca (100g)',
      'calories': 23,
      'protein': 2.9,
      'carbs': 3.6,
      'fat': 0.4,
      'category': 'vegetables',
    },
    {
      'name': 'Ensalada mixta',
      'calories': 25,
      'protein': 1.5,
      'carbs': 4,
      'fat': 0.3,
      'category': 'vegetables',
    },

    // Frutas
    {
      'name': 'Manzana (1 unidad)',
      'calories': 95,
      'protein': 0.5,
      'carbs': 25,
      'fat': 0.3,
      'category': 'fruits',
    },
    {
      'name': 'Plátano (1 unidad)',
      'calories': 105,
      'protein': 1.3,
      'carbs': 27,
      'fat': 0.4,
      'category': 'fruits',
    },
    {
      'name': 'Fresas (100g)',
      'calories': 32,
      'protein': 0.7,
      'carbs': 7.7,
      'fat': 0.3,
      'category': 'fruits',
    },

    // Lácteos
    {
      'name': 'Yogur griego (150g)',
      'calories': 100,
      'protein': 17,
      'carbs': 6,
      'fat': 0.7,
      'category': 'dairy',
    },
    {
      'name': 'Leche (250ml)',
      'calories': 122,
      'protein': 8,
      'carbs': 12,
      'fat': 4.8,
      'category': 'dairy',
    },
    {
      'name': 'Queso cottage (100g)',
      'calories': 98,
      'protein': 11,
      'carbs': 3.4,
      'fat': 4.3,
      'category': 'dairy',
    },
  ];
}
