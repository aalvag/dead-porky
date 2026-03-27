import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/core/router/app_router.dart';

/// Health metrics card showing vital signs
class HealthMetricsCard extends StatelessWidget {
  const HealthMetricsCard({super.key});

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
                Icon(Icons.monitor_heart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Métricas de salud',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.pushNamed(AppRoutes.health);
                  },
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.favorite,
                    label: 'FC Reposo',
                    value: '62',
                    unit: 'bpm',
                    color: Colors.red,
                    trend: Trend.decreasing,
                    trendText: '-3',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.monitor_weight,
                    label: 'Peso',
                    value: '78.5',
                    unit: 'kg',
                    color: Colors.blue,
                    trend: Trend.decreasing,
                    trendText: '-0.3',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.bloodtype,
                    label: 'Presión',
                    value: '118/76',
                    unit: 'mmHg',
                    color: Colors.green,
                    trend: Trend.stable,
                    trendText: 'OK',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.air,
                    label: 'SpO2',
                    value: '98',
                    unit: '%',
                    color: Colors.cyan,
                    trend: Trend.stable,
                    trendText: 'Normal',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum Trend { increasing, decreasing, stable }

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Trend trend;
  final String trendText;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
    required this.trendText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color trendColor;
    IconData trendIcon;

    switch (trend) {
      case Trend.increasing:
        trendColor = Colors.orange;
        trendIcon = Icons.trending_up;
        break;
      case Trend.decreasing:
        trendColor = Colors.green;
        trendIcon = Icons.trending_down;
        break;
      case Trend.stable:
        trendColor = Colors.grey;
        trendIcon = Icons.trending_flat;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trendText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
