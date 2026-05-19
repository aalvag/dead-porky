import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/core/router/app_router.dart';
import 'package:dead_porky/features/exercises/data/workout_history_service.dart';
import 'package:dead_porky/features/exercises/domain/entities/workout_record.dart';

/// Recent workouts card showing last training sessions
class RecentWorkoutsCard extends ConsumerWidget {
  const RecentWorkoutsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final historyService = ref.watch(workoutHistoryServiceProvider);
    final workouts = historyService.getThisWeekWorkouts();
    final latestWorkouts = workouts.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Entrenamientos recientes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.pushNamed(AppRoutes.exercises);
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (latestWorkouts.isEmpty) ...[
              Text(
                'Registra un entrenamiento para que aparezca en tu historial reciente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(AppRoutes.exercises);
                  },
                  icon: const Icon(Icons.fitness_center, size: 18),
                  label: const Text('Ir a entrenamientos'),
                ),
              ),
            ] else ...[
              Text(
                'Esta semana: ${workouts.length} entrenamientos · ${historyService.getWeeklyVolume().toStringAsFixed(0)} kg de volumen',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...latestWorkouts
                  .take(3)
                  .map((workout) => _WorkoutCard(workout: workout)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(AppRoutes.exercises);
                  },
                  icon: const Icon(Icons.fitness_center, size: 18),
                  label: const Text('Ver entrenamientos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutRecord workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: theme.colorScheme.surfaceContainerHighest,
        title: Text(
          workout.routineName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_formatDate(workout.date)} · ${_formatMinutes(workout.durationSeconds)} · ${workout.totalVolume.toStringAsFixed(0)} kg',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatMinutes(int seconds) {
    final minutes = seconds ~/ 60;
    return '$minutes min';
  }
}
