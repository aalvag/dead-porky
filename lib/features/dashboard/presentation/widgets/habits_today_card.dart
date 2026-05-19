import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/core/router/app_router.dart';
import 'package:dead_porky/features/habits/domain/entities/habit.dart';
import 'package:dead_porky/features/habits/presentation/screens/habit_tracker_screen.dart';

/// Habits today card showing daily habit progress
class HabitsTodayCard extends ConsumerWidget {
  const HabitsTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final habitLogs = ref.watch(habitLogsProvider);
    final dateKey = _dateKey(selectedDate);

    if (habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Hábitos de hoy',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay hábitos configurados. Agrega hábitos para comenzar tu seguimiento diario.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(AppRoutes.habits);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ir a hábitos'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final completed = habits.where((habit) {
      final value = habitLogs[habit.id]?[dateKey] ?? 0;
      return habit.type == HabitType.boolean
          ? value > 0
          : value >= (habit.targetValue ?? 1);
    }).length;

    final todayHabits = habits.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Hábitos de hoy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completed/${habits.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...todayHabits.map((habit) {
              final value = habitLogs[habit.id]?[dateKey] ?? 0;
              final isCompleted = habit.type == HabitType.boolean
                  ? value > 0
                  : value >= (habit.targetValue ?? 1);
              final label = habit.type == HabitType.boolean
                  ? (isCompleted ? 'Completado' : 'Pendiente')
                  : '${value.toStringAsFixed(0)} / ${habit.targetValue?.toStringAsFixed(0) ?? '?'} ${habit.targetUnit ?? ''}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HabitTile(
                  habit: habit,
                  statusLabel: label,
                  isCompleted: isCompleted,
                ),
              );
            }),
            if (habits.length > 3) ...[
              Text(
                'Muestra solo los primeros hábitos. Ve a la pantalla completa para gestionar todos.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.pushNamed(AppRoutes.habits);
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ver hábitos completos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final String statusLabel;
  final bool isCompleted;

  const _HabitTile({
    required this.habit,
    required this.statusLabel,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: habit.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(habit.icon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          Icon(Icons.check_circle, color: theme.colorScheme.primary)
        else
          Icon(
            Icons.radio_button_unchecked,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      ],
    );
  }
}
