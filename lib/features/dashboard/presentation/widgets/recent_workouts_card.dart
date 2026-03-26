import 'package:flutter/material.dart';

/// Recent workouts card showing last training sessions
class RecentWorkoutsCard extends StatelessWidget {
  const RecentWorkoutsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data - replace with actual data from Firestore
    final workouts = [
      _WorkoutItem(
        name: 'Push Day',
        date: 'Hoy',
        duration: '52 min',
        exercises: 6,
        volume: '12,450 kg',
        icon: Icons.fitness_center,
        color: Colors.blue,
      ),
      _WorkoutItem(
        name: 'Pull Day',
        date: 'Ayer',
        duration: '48 min',
        exercises: 5,
        volume: '11,200 kg',
        icon: Icons.fitness_center,
        color: Colors.red,
      ),
      _WorkoutItem(
        name: 'Leg Day',
        date: 'Hace 2 días',
        duration: '61 min',
        exercises: 7,
        volume: '15,800 kg',
        icon: Icons.fitness_center,
        color: Colors.green,
      ),
    ];

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
                Text(
                  'Entrenamientos recientes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to workout history
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...workouts.map((workout) => _WorkoutTile(workout: workout)),
          ],
        ),
      ),
    );
  }
}

class _WorkoutItem {
  final String name;
  final String date;
  final String duration;
  final int exercises;
  final String volume;
  final IconData icon;
  final Color color;

  const _WorkoutItem({
    required this.name,
    required this.date,
    required this.duration,
    required this.exercises,
    required this.volume,
    required this.icon,
    required this.color,
  });
}

class _WorkoutTile extends StatelessWidget {
  final _WorkoutItem workout;

  const _WorkoutTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: workout.color.withValues(alpha: 0.15),
          child: Icon(workout.icon, color: workout.color, size: 20),
        ),
        title: Text(
          workout.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${workout.date} · ${workout.exercises} ejercicios · ${workout.volume}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            workout.duration,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          // TODO: Navigate to workout detail
        },
      ),
    );
  }
}
