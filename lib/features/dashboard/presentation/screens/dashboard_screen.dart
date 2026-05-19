import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/features/ai_assistant/presentation/providers/ai_insights_provider.dart';
import 'package:dead_porky/features/daily_checkin/presentation/providers/daily_checkin_provider.dart';
import 'package:dead_porky/features/wearable/presentation/providers/wearable_metrics_provider.dart';
import 'package:dead_porky/core/router/app_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _handleRefresh(WidgetRef ref) async {
    final checkin = ref.read(dailyCheckinProvider.notifier);
    await Future.delayed(const Duration(milliseconds: 700));
    await checkin.loadForDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final dailyCheckin = ref.watch(dailyCheckinProvider);
    final wearableMetrics = ref.watch(wearableMetricsProvider);
    final aiInsights = ref.watch(aiInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              user?.displayName ?? 'Bienvenido',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => context.pushNamed(AppRoutes.deviceScanner),
            tooltip: 'Dispositivos',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.pushNamed(AppRoutes.aiChat),
            tooltip: 'Asistente IA',
          ),
        ],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _buildPremiumIntro(theme),
            const SizedBox(height: 18),
            _buildWearableSummary(context, theme, wearableMetrics),
            const SizedBox(height: 18),
            _buildManualCheckinCard(context, theme, dailyCheckin),
            const SizedBox(height: 18),
            _buildRecommendationCard(context, theme, aiInsights),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumIntro(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu panel premium',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conecta tu registro diario, revisa tu estado y recibe una recomendación práctica para hoy.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMiniBadge(
                theme,
                icon: Icons.flash_on,
                label: 'Foco',
              ),
              _buildMiniBadge(
                theme,
                icon: Icons.shield,
                label: 'Consistencia',
              ),
              _buildMiniBadge(
                theme,
                icon: Icons.auto_graph,
                label: 'Progreso',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(ThemeData theme,
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCheckinCard(
    BuildContext context,
    ThemeData theme,
    DailyCheckinState checkin,
  ) {
    final hasEntry = checkin.hasSavedEntry;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completa con datos manuales',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasEntry
                ? 'Ya tienes datos manuales registrados. Ajusta tu agua, energía o notas para completar el perfil.'
                : 'Si tu reloj no envía todo, añade aquí agua, energía, humor y notas para obtener recomendaciones completas.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                context.push('/dashboard/daily-checkin');
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                hasEntry ? 'Editar registro manual' : 'Registrar manualmente',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWearableSummary(
    BuildContext context,
    ThemeData theme,
    WearableMetricsState wearableMetrics,
  ) {
    final hasDevice = wearableMetrics.connectedDevices.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Datos del reloj',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.watch, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasDevice
                ? 'Mostrando métricas sincronizadas desde tu reloj y Samsung Health.'
                : 'Aún no hay reloj conectado. Conecta tu Galaxy Watch para ver pasos, sueño y frecuencia cardiaca.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (wearableMetrics.isSyncing) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Actualizando métricas...',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _buildSmallMetric(
            theme,
            label: 'Pasos',
            value: wearableMetrics.steps.toString(),
            icon: Icons.directions_walk,
            accent: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSmallMetric(
            theme,
            label: 'Sueño',
            value: '${wearableMetrics.sleepHours.toStringAsFixed(1)}h',
            icon: Icons.bedtime,
            accent: Colors.deepPurple,
          ),
          const SizedBox(height: 12),
          _buildSmallMetric(
            theme,
            label: 'FC reposo',
            value: '${wearableMetrics.restingHeartRate} bpm',
            icon: Icons.favorite,
            accent: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSmallMetric(
            theme,
            label: 'Min. activos',
            value: '${wearableMetrics.activeMinutes}',
            icon: Icons.fitness_center,
            accent: Colors.green,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pushNamed(AppRoutes.deviceScanner),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    hasDevice ? 'Sincronizar reloj' : 'Conectar reloj',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (hasDevice)
                Text(
                  'Últ. sync: ${wearableMetrics.lastSyncedAt != null ? '${wearableMetrics.lastSyncedAt!.hour}:${wearableMetrics.lastSyncedAt!.minute.toString().padLeft(2, '0')}' : 'Nunca'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    ThemeData theme,
    AiInsightsState aiInsights,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.auto_graph, color: theme.colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recomendación premium',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Obtén un consejo adaptado a tu día y a tus registros recientes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (aiInsights.isLoading)
            Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          else if (aiInsights.error != null)
            Text(
              aiInsights.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else if (aiInsights.insight != null)
            Text(
              aiInsights.insight!,
              style: theme.textTheme.bodyMedium,
            )
          else
            Text(
              'Pide una recomendación para saber qué priorizar hoy según tu agua, sueño, energía y entrenamiento.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.pushNamed(AppRoutes.aiChat),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Abrir asistente',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}
