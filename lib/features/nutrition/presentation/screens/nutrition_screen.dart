import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_entry.dart';

// ==================== Providers ====================

final nutritionEntriesProvider =
    StateProvider<Map<String, List<NutritionEntry>>>((ref) {
      return {}; // {dateKey: [entries]}
    });

final selectedMealDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// ==================== Screen ====================

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedMealDateProvider);
    final entries = ref.watch(nutritionEntriesProvider);
    final dateKey = _dateKey(selectedDate);
    final dayEntries = entries[dateKey] ?? [];

    final totalCalories = dayEntries.fold<int>(0, (sum, e) => sum + e.calories);
    final totalProtein = dayEntries.fold<double>(
      0,
      (sum, e) => sum + e.protein,
    );
    final totalCarbs = dayEntries.fold<double>(0, (sum, e) => sum + e.carbs);
    final totalFat = dayEntries.fold<double>(0, (sum, e) => sum + e.fat);

    // Goals
    const calorieGoal = 2200;
    const proteinGoal = 150;
    const carbsGoal = 250;
    const fatGoal = 70;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrición'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _showPhotoAnalysis(context),
            tooltip: 'Fotografiar comida',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFoodSheet(context, ref),
            tooltip: 'Agregar alimento',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector
            _DateRow(
              selectedDate: selectedDate,
              onChanged: (date) {
                ref.read(selectedMealDateProvider.notifier).state = date;
              },
            ),
            const SizedBox(height: 16),

            // Calories ring
            _CaloriesSummary(
              consumed: totalCalories,
              goal: calorieGoal,
              protein: totalProtein,
              carbs: totalCarbs,
              fat: totalFat,
              proteinGoal: proteinGoal,
              carbsGoal: carbsGoal,
              fatGoal: fatGoal,
            ),
            const SizedBox(height: 16),

            // Macros progress
            Row(
              children: [
                Expanded(
                  child: _MacroCard(
                    label: 'Proteína',
                    consumed: totalProtein,
                    goal: proteinGoal,
                    unit: 'g',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroCard(
                    label: 'Carbos',
                    consumed: totalCarbs,
                    goal: carbsGoal,
                    unit: 'g',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroCard(
                    label: 'Grasas',
                    consumed: totalFat,
                    goal: fatGoal,
                    unit: 'g',
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Meals by type
            ...MealType.values.map((mealType) {
              final mealEntries = dayEntries
                  .where((e) => e.mealType == mealType)
                  .toList();
              final mealCalories = mealEntries.fold<int>(
                0,
                (sum, e) => sum + e.calories,
              );

              return _MealSection(
                mealType: mealType,
                entries: mealEntries,
                totalCalories: mealCalories,
                onAdd: () =>
                    _showAddFoodSheet(context, ref, mealType: mealType),
              );
            }),

            // AI Analysis button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAIAnalysis(context, dayEntries),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Análisis IA de nutrición'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _showAddFoodSheet(
    BuildContext context,
    WidgetRef ref, {
    MealType? mealType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Agregar alimento${mealType != null ? ' - ${mealType.label}' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: PresetFoods.foods.length,
                itemBuilder: (context, index) {
                  final food = PresetFoods.foods[index];
                  return ListTile(
                    title: Text(food['name']),
                    subtitle: Text(
                      '${food['calories']} kcal · P: ${food['protein']}g · C: ${food['carbs']}g · G: ${food['fat']}g',
                    ),
                    onTap: () {
                      final entry = NutritionEntry.create(
                        name: food['name'],
                        mealType: mealType ?? MealType.snack,
                        calories: food['calories'],
                        protein: (food['protein'] as num).toDouble(),
                        carbs: (food['carbs'] as num).toDouble(),
                        fat: (food['fat'] as num).toDouble(),
                      );

                      final entries = Map<String, List<NutritionEntry>>.from(
                        ref.read(nutritionEntriesProvider),
                      );
                      final dateKey = _dateKey(
                        ref.read(selectedMealDateProvider),
                      );
                      entries[dateKey] ??= [];
                      entries[dateKey]!.add(entry);
                      ref.read(nutritionEntriesProvider.notifier).state =
                          entries;

                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotografiar comida'),
        content: const Text(
          'Próximamente: Toma una foto de tu comida y la IA estimará los macronutrientes automáticamente.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showAIAnalysis(BuildContext context, List<NutritionEntry> entries) {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Agrega alimentos primero')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Análisis IA'),
          ],
        ),
        content: const Text(
          'Conectando con Kilo Gateway para analizar tu nutrición...\n\n'
          'Próximamente: Análisis detallado de tu ingesta calórica, '
          'balance de macronutrientes, y recomendaciones personalizadas.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ==================== Widgets ====================

class _DateRow extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onChanged;

  const _DateRow({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () =>
              onChanged(selectedDate.subtract(const Duration(days: 1))),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: today,
              );
              if (date != null) onChanged(date);
            },
            child: Text(
              isToday
                  ? 'Hoy'
                  : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: selectedDate.isBefore(today)
              ? () => onChanged(selectedDate.add(const Duration(days: 1)))
              : null,
        ),
      ],
    );
  }
}

class _CaloriesSummary extends StatelessWidget {
  final int consumed;
  final int goal;
  final double protein;
  final double carbs;
  final double fat;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  const _CaloriesSummary({
    required this.consumed,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (consumed / goal).clamp(0.0, 1.0);
    final remaining = goal - consumed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation(
                      progress > 1 ? Colors.red : Colors.orange,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$consumed',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('kcal', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meta: $goal kcal',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    remaining > 0
                        ? 'Restantes: $remaining kcal'
                        : 'Excedido: ${-remaining} kcal',
                    style: TextStyle(
                      color: remaining > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'P: ${protein.toStringAsFixed(0)}/$proteinGoal · C: ${carbs.toStringAsFixed(0)}/$carbsGoal · G: ${fat.toStringAsFixed(0)}/$fatGoal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double consumed;
  final int goal;
  final String unit;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (consumed / goal).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${consumed.toStringAsFixed(0)}/$goal$unit',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final MealType mealType;
  final List<NutritionEntry> entries;
  final int totalCalories;
  final VoidCallback onAdd;

  const _MealSection({
    required this.mealType,
    required this.entries,
    required this.totalCalories,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(mealType.icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  mealType.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$totalCalories kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAdd,
                ),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sin alimentos registrados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...entries.map(
                (entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.name),
                  subtitle: Text(
                    '${entry.calories} kcal · P: ${entry.protein.toStringAsFixed(0)}g · C: ${entry.carbs.toStringAsFixed(0)}g',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
