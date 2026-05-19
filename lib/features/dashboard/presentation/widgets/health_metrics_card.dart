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
            Text(
              'Registra métricas de salud o conecta un wearable para ver datos reales aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.pushNamed(AppRoutes.health);
                },
                child: const Text('Ir a métricas de salud'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

