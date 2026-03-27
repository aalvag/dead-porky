import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/core/router/app_router.dart';

/// AI insights card showing personalized recommendations
class AiInsightsCard extends StatelessWidget {
  const AiInsightsCard({super.key});

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insights de IA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Personalizado para ti',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    // TODO: Refresh insights
                  },
                  tooltip: 'Actualizar insights',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Insight items
            _InsightItem(
              icon: Icons.trending_up,
              title: 'Progresión detectada',
              description:
                  'Tu press de banca ha aumentado 2.5kg esta semana. ¡Excelente progreso!',
              color: Colors.green,
              action: 'Ver detalles',
              onAction: () {
                // TODO: Navigate to exercise detail
              },
            ),
            const Divider(height: 24),
            _InsightItem(
              icon: Icons.warning_amber,
              title: 'Atención: Sueño reducido',
              description:
                  'Has dormido promedio 6h esta semana. Intenta llegar a 7-8h para mejor recuperación.',
              color: Colors.orange,
              action: 'Ver análisis',
              onAction: () {
                // TODO: Navigate to sleep analysis
              },
            ),
            const Divider(height: 24),
            _InsightItem(
              icon: Icons.restaurant,
              title: 'Sugerencia nutricional',
              description:
                  'Basado en tu entrenamiento de hoy, considera aumentar proteína a 150g.',
              color: Colors.blue,
              action: 'Ver plan',
              onAction: () {
                // TODO: Navigate to nutrition
              },
            ),
            const SizedBox(height: 12),
            // Chat button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.pushNamed(AppRoutes.aiChat);
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Preguntar al asistente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String action;
  final VoidCallback onAction;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onAction,
                child: Text(
                  action,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
