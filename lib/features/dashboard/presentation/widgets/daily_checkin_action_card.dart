import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/core/router/app_router.dart';

class DailyCheckinActionCard extends StatelessWidget {
  const DailyCheckinActionCard({super.key});

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
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check-in diario',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.dailyCheckin),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Entrar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Registra agua, sueño, energía y trabajo realizado. Mantén tu progreso visible cada día.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
