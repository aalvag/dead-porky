import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/habits/domain/entities/habit.dart';
import 'package:dead_porky/features/habits/presentation/screens/habit_tracker_screen.dart';

/// Streak card showing current and longest streaks
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final habitLogs = ref.watch(habitLogsProvider);

    final dailyHabits = habits
        .where((habit) => habit.frequency == HabitFrequency.daily)
        .toList();
    final currentStreak = _computeCurrentStreak(dailyHabits, habitLogs);
    final longestStreak = _computeLongestStreak(dailyHabits, habitLogs);
    final completedToday = _countCompletedToday(dailyHabits, habitLogs);
    final totalPoints = completedToday * 10;
    final level = 1 + (totalPoints ~/ 50);

    if (dailyHabits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tu racha',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Agrega hábitos diarios para que puedas seguir tu racha y progresar continuamente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tu racha',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StreakItem(
                    icon: Icons.local_fire_department,
                    value: '$currentStreak',
                    label: 'Días seguidos',
                    color: Colors.orange,
                    isHighlighted: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _StreakItem(
                    icon: Icons.emoji_events,
                    value: '$longestStreak',
                    label: 'Récord',
                    color: Colors.amber,
                    isHighlighted: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$level',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nivel $level',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          totalPoints > 0
                              ? '$totalPoints XP acumulados'
                              : 'Suma puntos completando tus hábitos diarios',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (totalPoints % 50) / 50,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalPoints > 0
                              ? '${50 - (totalPoints % 50)} XP para nivel ${level + 1}'
                              : 'Completa un hábito para avanzar',
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
            const SizedBox(height: 12),
            Text(
              currentStreak > 0
                  ? '¡Manténla! $completedToday hábitos del día completados.'
                  : 'Aún no tienes racha activa. Empieza con tu primer hábito diario.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _countCompletedToday(
    List<Habit> habits,
    Map<String, Map<String, double>> habitLogs,
  ) {
    final todayKey = _dateKey(DateTime.now());
    return habits.where((habit) {
      final value = habitLogs[habit.id]?[todayKey] ?? 0;
      return habit.type == HabitType.boolean
          ? value > 0
          : value >= (habit.targetValue ?? 1);
    }).length;
  }

  bool _isHabitCompletedOnDate(
    Habit habit,
    Map<String, Map<String, double>> habitLogs,
    DateTime date,
  ) {
    final dateKey = _dateKey(date);
    final value = habitLogs[habit.id]?[dateKey] ?? 0;
    return habit.type == HabitType.boolean
        ? value > 0
        : value >= (habit.targetValue ?? 1);
  }

  int _computeCurrentStreak(
    List<Habit> habits,
    Map<String, Map<String, double>> habitLogs,
  ) {
    if (habits.isEmpty) return 0;

    var streak = 0;
    var date = DateTime.now();
    while (true) {
      final allCompleted = habits.every(
        (habit) => _isHabitCompletedOnDate(habit, habitLogs, date),
      );
      if (!allCompleted) break;
      streak += 1;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _computeLongestStreak(
    List<Habit> habits,
    Map<String, Map<String, double>> habitLogs,
  ) {
    if (habits.isEmpty) return 0;

    final dates =
        habitLogs.values
            .expand((map) => map.keys)
            .toSet()
            .map(DateTime.parse)
            .toList()
          ..sort();

    var longest = 0;
    var current = 0;
    DateTime? previousDate;

    for (final date in dates) {
      if (previousDate == null || date.difference(previousDate).inDays == 1) {
        final allCompleted = habits.every(
          (habit) => _isHabitCompletedOnDate(habit, habitLogs, date),
        );
        if (allCompleted) {
          current += 1;
        } else {
          longest = current > longest ? current : longest;
          current = 0;
        }
      } else {
        longest = current > longest ? current : longest;
        final allCompleted = habits.every(
          (habit) => _isHabitCompletedOnDate(habit, habitLogs, date),
        );
        current = allCompleted ? 1 : 0;
      }
      previousDate = date;
    }

    return current > longest ? current : longest;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _StreakItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isHighlighted;

  const _StreakItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: isHighlighted ? color : color.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlighted ? color : null,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
