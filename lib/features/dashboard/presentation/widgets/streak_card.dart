import 'package:flutter/material.dart';

/// Streak card showing current and longest streaks
class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data - replace with actual data
    const currentStreak = 12;
    const longestStreak = 28;
    const totalPoints = 4850;
    const level = 5;

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
                // Current streak
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
                // Longest streak
                Expanded(
                  child: _StreakItem(
                    icon: Icons.emoji_events,
                    value: '$longestStreak',
                    label: 'Récord personal',
                    color: Colors.amber,
                    isHighlighted: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Level and XP
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
                  // Level badge
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
                          '$totalPoints XP acumulados',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: 0.65, // Progress to next level
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '150 XP para nivel ${level + 1}',
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
            // Achievements preview
            Row(
              children: [
                Text(
                  'Logros recientes:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                ...['🏆', '💪', '🔥', '⭐'].map((badge) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(badge, style: const TextStyle(fontSize: 20)),
                  );
                }),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to achievements
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
