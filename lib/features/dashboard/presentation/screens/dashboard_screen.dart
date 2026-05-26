import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/features/ai_assistant/presentation/providers/ai_insights_provider.dart';
import 'package:dead_porky/features/daily_checkin/presentation/providers/daily_checkin_provider.dart';
import 'package:dead_porky/features/wearable/presentation/providers/wearable_metrics_provider.dart';
import 'package:dead_porky/core/router/app_router.dart';
import 'package:dead_porky/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:dead_porky/features/nutrition/presentation/providers/nutrition_provider.dart';


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
    final nutritionState = ref.watch(nutritionProvider);

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
            _buildNutritionCard(context, theme, nutritionState),
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
    final hasMetrics = wearableMetrics.availableMetricKeys.isNotEmpty;
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
                ? 'Mostrando métricas sincronizadas desde tu reloj y Huawei Health.'
                : 'Aún no hay reloj conectado. Conecta tu Huawei GT6 Pro para ver pasos, sueño, frecuencia cardiaca, SpO2, distancia y recuperación.',
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
          if (wearableMetrics.syncCoverageNote.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                wearableMetrics.syncCoverageNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
          if (hasMetrics) ...[
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              'Todavia no hay muestras utilizables de Health Connect para mostrar aqui.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (wearableMetrics.hasMetric('steps')) ...[
            _buildSmallMetric(
              theme,
              label: 'Pasos',
              value: wearableMetrics.steps.toString(),
              icon: Icons.directions_walk,
              accent: Colors.blue,
            ),
          ],
          if (wearableMetrics.hasMetric('sleep')) ...[
            if (wearableMetrics.hasMetric('steps')) const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'Sueño',
              value: '${wearableMetrics.sleepHours.toStringAsFixed(1)}h',
              icon: Icons.bedtime,
              accent: Colors.deepPurple,
            ),
          ],
          if (wearableMetrics.hasMetric('restingHeartRate')) ...[
            if (wearableMetrics.hasMetric('steps') || wearableMetrics.hasMetric('sleep'))
              const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'FC reposo',
              value: '${wearableMetrics.restingHeartRate} bpm',
              icon: Icons.favorite,
              accent: Colors.red,
            ),
          ],
          if (wearableMetrics.hasMetric('averageHeartRate')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'FC media',
              value: '${wearableMetrics.averageHeartRate} bpm',
              icon: Icons.monitor_heart,
              accent: Colors.pink,
            ),
          ],
          if (wearableMetrics.hasMetric('activeMinutes')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'Min. activos',
              value: '${wearableMetrics.activeMinutes}',
              icon: Icons.fitness_center,
              accent: Colors.green,
            ),
          ],
          if (wearableMetrics.hasMetric('distanceKm')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'Distancia',
              value: '${wearableMetrics.distanceKm.toStringAsFixed(2)} km',
              icon: Icons.route,
              accent: Colors.indigo,
            ),
          ],
          if (wearableMetrics.hasMetric('workoutsToday')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'Sesiones',
              value: '${wearableMetrics.workoutsToday}',
              icon: Icons.sports_score,
              accent: Colors.orange,
            ),
          ],
          if (wearableMetrics.hasMetric('bloodOxygen')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'SpO2',
              value: '${wearableMetrics.bloodOxygen.toStringAsFixed(1)}%',
              icon: Icons.bloodtype,
              accent: Colors.teal,
            ),
          ],
          if (wearableMetrics.hasMetric('heartRateVariabilityMs')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'HRV',
              value: '${wearableMetrics.heartRateVariabilityMs.toStringAsFixed(0)} ms',
              icon: Icons.multiline_chart,
              accent: Colors.cyan,
            ),
          ],
          if (wearableMetrics.hasMetric('respiratoryRate')) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'Respiración',
              value: '${wearableMetrics.respiratoryRate} rpm',
              icon: Icons.air,
              accent: Colors.lightBlue,
            ),
          ],
          if (wearableMetrics.floorsClimbed > 0) ...[
            const SizedBox(height: 12),
            _buildSmallMetric(
              theme,
              label: 'Pisos subidos',
              value: '${wearableMetrics.floorsClimbed}',
              icon: Icons.stairs,
              accent: Colors.brown,
            ),
          ],
          if (wearableMetrics.deepSleepHours > 0 ||
              wearableMetrics.lightSleepHours > 0 ||
              wearableMetrics.remSleepHours > 0) ...[
            const SizedBox(height: 20),
            Text(
              'Fases de sueño',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (wearableMetrics.deepSleepHours > 0) ...[
              const SizedBox(height: 12),
              _buildSmallMetric(
                theme,
                label: 'Sueño profundo',
                value: '${wearableMetrics.deepSleepHours.toStringAsFixed(1)} h',
                icon: Icons.dark_mode,
                accent: Colors.deepPurple,
              ),
            ],
            if (wearableMetrics.lightSleepHours > 0) ...[
              const SizedBox(height: 12),
              _buildSmallMetric(
                theme,
                label: 'Sueño ligero',
                value: '${wearableMetrics.lightSleepHours.toStringAsFixed(1)} h',
                icon: Icons.nights_stay,
                accent: Colors.blueGrey,
              ),
            ],
            if (wearableMetrics.remSleepHours > 0) ...[
              const SizedBox(height: 12),
              _buildSmallMetric(
                theme,
                label: 'Sueño REM',
                value: '${wearableMetrics.remSleepHours.toStringAsFixed(1)} h',
                icon: Icons.bedtime,
                accent: Colors.purple,
              ),
            ],
          ],
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

  Widget _buildNutritionCard(
    BuildContext context,
    ThemeData theme,
    NutritionState state,
  ) {
    final consumedCalories = state.entries.fold<int>(0, (sum, entry) => sum + entry.calories);
    final calorieGoal = state.goals.calorieGoal;
    final calorieProgress = calorieGoal <= 0 ? 0.0 : (consumedCalories / calorieGoal).clamp(0.0, 1.0);

    final protein = state.entries.fold<double>(0, (sum, entry) => sum + entry.protein);
    final proteinGoal = state.goals.proteinGoal <= 0 ? 1.0 : state.goals.proteinGoal.toDouble();
    final proteinProgress = (protein / proteinGoal).clamp(0.0, 1.0);

    final carbs = state.entries.fold<double>(0, (sum, entry) => sum + entry.carbs);
    final carbsGoal = state.goals.carbsGoal <= 0 ? 1.0 : state.goals.carbsGoal.toDouble();
    final carbsProgress = (carbs / carbsGoal).clamp(0.0, 1.0);

    final fat = state.entries.fold<double>(0, (sum, entry) => sum + entry.fat);
    final fatGoal = state.goals.fatGoal <= 0 ? 1.0 : state.goals.fatGoal.toDouble();
    final fatProgress = (fat / fatGoal).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFEA580C),
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF97316).withValues(alpha: 0.03),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrición y Comidas IA',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.entries.isEmpty
                          ? 'Analiza platos con foto de IA, calibra macros y controla tu balance.'
                          : 'Hoy has registrado ${state.entries.length} comidas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: calorieProgress,
                      strokeWidth: 4.5,
                      backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$consumedCalories',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 8,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Macros horizontal rows
          Row(
            children: [
              Expanded(
                child: _buildMacroIndicator(
                  theme,
                  label: 'Prot',
                  value: protein,
                  goal: state.goals.proteinGoal.toDouble(),
                  progress: proteinProgress,
                  color: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroIndicator(
                  theme,
                  label: 'Carb',
                  value: carbs,
                  goal: state.goals.carbsGoal.toDouble(),
                  progress: carbsProgress,
                  color: const Color(0xFFEAB308),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroIndicator(
                  theme,
                  label: 'Gras',
                  value: fat,
                  goal: state.goals.fatGoal.toDouble(),
                  progress: fatProgress,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 1,
                shadowColor: const Color(0xFFEA580C).withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Ver Nutrición Completa',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(
    ThemeData theme, {
    required String label,
    required double value,
    required double goal,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}g',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3.5,
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
