import 'package:flutter/material.dart';

/// Habits today card showing daily habit progress
class HabitsTodayCard extends StatelessWidget {
  const HabitsTodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data - replace with actual data from Firestore
    final habits = [
      _HabitItem(
        icon: '💧',
        name: 'Hidratación',
        progress: 0.75,
        label: '6/8 vasos',
        isCompleted: false,
      ),
      _HabitItem(
        icon: '🏃',
        name: 'Ejercicio',
        progress: 1.0,
        label: '52 min',
        isCompleted: true,
      ),
      _HabitItem(
        icon: '🧘',
        name: 'Meditación',
        progress: 1.0,
        label: '10 min',
        isCompleted: true,
      ),
      _HabitItem(
        icon: '📚',
        name: 'Lectura',
        progress: 0.0,
        label: '0/20 min',
        isCompleted: false,
      ),
    ];

    final completed = habits.where((h) => h.isCompleted).length;
    final total = habits.length;

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
                    color: completed == total
                        ? Colors.green.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completed/$total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: completed == total ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...habits.map((habit) => _HabitTile(habit: habit)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Navigate to habits screen
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ver todos los hábitos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitItem {
  final String icon;
  final String name;
  final double progress;
  final String label;
  final bool isCompleted;

  const _HabitItem({
    required this.icon,
    required this.name,
    required this.progress,
    required this.label,
    required this.isCompleted,
  });
}

class _HabitTile extends StatelessWidget {
  final _HabitItem habit;

  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: habit.isCompleted
                  ? Colors.green.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(habit.icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // Name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: habit.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (habit.isCompleted) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: habit.progress,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    habit.isCompleted
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Text(
            habit.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
