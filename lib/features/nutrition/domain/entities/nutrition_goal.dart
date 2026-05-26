import 'dart:math' as math;

import 'package:dead_porky/features/auth/domain/entities/user.dart';

class NutritionGoal {
  const NutritionGoal({
    required this.calorieGoal,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.fiberGoal,
  });

  final int calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final double fiberGoal;

  factory NutritionGoal.defaults() {
    return const NutritionGoal(
      calorieGoal: 2200,
      proteinGoal: 150,
      carbsGoal: 250,
      fatGoal: 70,
      fiberGoal: 28,
    );
  }

  factory NutritionGoal.suggested(User? user) {
    final profile = user?.profile;
    if (profile == null) {
      return NutritionGoal.defaults();
    }

    final tdee = profile.tdee ?? 2200;
    final weight = profile.weight ?? 75;

    double calories = tdee;
    double proteinPerKg = 1.8;

    switch (profile.fitnessGoal) {
      case FitnessGoal.loseWeight:
        calories -= 400;
        proteinPerKg = 2.0;
      case FitnessGoal.gainMuscle:
        calories += 250;
        proteinPerKg = 2.0;
      case FitnessGoal.improveEndurance:
        calories += 150;
        proteinPerKg = 1.6;
      case FitnessGoal.improveFlexibility:
        proteinPerKg = 1.4;
      case FitnessGoal.generalHealth:
        proteinPerKg = 1.6;
      case FitnessGoal.maintain:
        proteinPerKg = 1.8;
    }

    final normalizedCalories = math.max(1600, calories.round());
    final proteinGoal = math
        .max(120, (weight * proteinPerKg).round())
        .toDouble();
    final fatGoal = math
        .max(55, (normalizedCalories * 0.27 / 9).round())
        .toDouble();
    final carbsGoal = math
        .max(
          120,
          ((normalizedCalories - (proteinGoal * 4) - (fatGoal * 9)) / 4)
              .round(),
        )
        .toDouble();
    final fiberGoal = math
        .max(28, (normalizedCalories / 1000 * 14).round())
        .toDouble();

    return NutritionGoal(
      calorieGoal: normalizedCalories,
      proteinGoal: proteinGoal,
      carbsGoal: carbsGoal,
      fatGoal: fatGoal,
      fiberGoal: fiberGoal,
    );
  }

  NutritionGoal copyWith({
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    double? fiberGoal,
  }) {
    return NutritionGoal(
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      fiberGoal: fiberGoal ?? this.fiberGoal,
    );
  }
}
