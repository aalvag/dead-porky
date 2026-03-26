import 'package:flutter/material.dart';

/// Daily summary card showing key metrics
class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Resumen del día',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricItem(
                  icon: Icons.directions_walk,
                  value: '8,432',
                  label: 'Pasos',
                  color: Colors.blue,
                  progress: 0.84,
                ),
                const SizedBox(width: 12),
                _MetricItem(
                  icon: Icons.local_fire_department,
                  value: '2,145',
                  label: 'Calorías',
                  color: Colors.orange,
                  progress: 0.72,
                ),
                const SizedBox(width: 12),
                _MetricItem(
                  icon: Icons.bedtime,
                  value: '7h 23m',
                  label: 'Sueño',
                  color: Colors.purple,
                  progress: 0.92,
                ),
                const SizedBox(width: 12),
                _MetricItem(
                  icon: Icons.water_drop,
                  value: '6/8',
                  label: 'Agua',
                  color: Colors.cyan,
                  progress: 0.75,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double progress;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
