import 'package:flutter/material.dart';

/// Calories ring card - circular progress for daily calorie goal
class CaloriesRingCard extends StatelessWidget {
  const CaloriesRingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const consumed = 1850;
    const goal = 2200;
    const burned = 420;
    final progress = consumed / goal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 12,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 12,
                      valueColor: AlwaysStoppedAnimation(
                        progress > 1 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$consumed',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'de $goal kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calorías',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.restaurant,
                    label: 'Consumidas',
                    value: '$consumed kcal',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    icon: Icons.local_fire_department,
                    label: 'Quemadas',
                    value: '$burned kcal',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    icon: Icons.trending_down,
                    label: 'Restantes',
                    value: '${goal - consumed + burned} kcal',
                    color: Colors.green,
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

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
