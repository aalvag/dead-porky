import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dead_porky/features/nutrition/presentation/screens/nutrition_screen.dart';
import 'package:dead_porky/database/app_database.dart';
import 'package:dead_porky/features/health_metrics/presentation/providers/health_metrics_provider.dart';
import 'package:dead_porky/features/wearable/presentation/providers/wearable_metrics_provider.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/features/auth/domain/entities/user.dart';

// ==================== Consumer Stateful Widget Screen ====================

class HealthMetricsScreen extends ConsumerStatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  ConsumerState<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends ConsumerState<HealthMetricsScreen> {
  String _selectedTab = 'Resumen'; // Resumen, Composición, Cardio, Sueño

  final List<String> _tabs = ['Resumen', 'Composición', 'Cardio', 'Sueño'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wearableMetrics = ref.watch(wearableMetricsProvider);
    final healthMetrics = ref.watch(healthMetricsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.tertiary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hola, ${currentUser?.displayName.split(' ').first ?? 'Usuario'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Métricas de Salud',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              wearableMetrics.lastSyncedAt != null
                                  ? 'Sync: ${wearableMetrics.lastSyncedAt!.hour.toString().padLeft(2, '0')}:${wearableMetrics.lastSyncedAt!.minute.toString().padLeft(2, '0')}'
                                  : 'Sin sincronizar',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        // Health Score Circular Widget
                        _buildHealthScoreWidget(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.restaurant, size: 24),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NutritionScreen()),
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                tooltip: 'Nutrición IA',
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
                onPressed: () => _showAddMetricSheet(context),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                tooltip: 'Registrar Métrica',
              ),
            ],
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab capsule selector
                  _buildTabCapsules(theme),
                  const SizedBox(height: 20),

                  // Display selected screen tab with animations
                  _buildAnimatedTabContent(theme, wearableMetrics, healthMetrics, currentUser),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMetricSheet(context),
        label: const Text('Registrar Métrica'),
        icon: const Icon(Icons.add),
        elevation: 4,
      ),
    );
  }

  // Radial health score display
  Widget _buildHealthScoreWidget(ThemeData theme) {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: CircularProgressIndicator(
              value: 0.94,
              strokeWidth: 4,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '94',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  height: 1,
                ),
              ),
              Text(
                'Score',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9));
  }

  // Horizontal Tab capsules
  Widget _buildTabCapsules(ThemeData theme) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          IconData icon;
          switch (tab) {
            case 'Resumen':
              icon = Icons.dashboard_rounded;
            case 'Composición':
              icon = Icons.scale_rounded;
            case 'Cardio':
              icon = Icons.favorite_rounded;
            case 'Sueño':
              icon = Icons.bedtime_rounded;
            default:
              icon = Icons.health_and_safety_rounded;
          }

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = tab),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Helper to build weight spots for chart
  List<FlSpot> _buildWeightSpots(List<HealthMetric> weights, double defaultWeight) {
    if (weights.isEmpty) {
      return [
        FlSpot(0, defaultWeight),
        FlSpot(1, defaultWeight),
        FlSpot(2, defaultWeight),
        FlSpot(3, defaultWeight),
        FlSpot(4, defaultWeight),
        FlSpot(5, defaultWeight),
        FlSpot(6, defaultWeight),
      ];
    }

    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      double weightVal = defaultWeight;
      for (final w in weights) {
        if (w.measuredAt.isBefore(targetDate.add(const Duration(days: 1)))) {
          weightVal = w.value;
          break;
        }
      }
      spots.add(FlSpot((6 - i).toDouble(), weightVal));
    }
    return spots;
  }

  // Animated switch tab contents
  Widget _buildAnimatedTabContent(
    ThemeData theme,
    WearableMetricsState wearableMetrics,
    HealthMetricsState healthMetrics,
    User? currentUser,
  ) {
    switch (_selectedTab) {
      case 'Resumen':
        return _buildResumenTab(theme, wearableMetrics, healthMetrics, currentUser)
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0);
      case 'Composición':
        return _buildComposicionTab(theme, healthMetrics, currentUser)
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0);
      case 'Cardio':
        return _buildCardioTab(theme, wearableMetrics)
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0);
      case 'Sueño':
        return _buildSuenoTab(theme, wearableMetrics)
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0);
      default:
        return Container();
    }
  }

  // ==================== RESUMEN TAB ====================
  Widget _buildResumenTab(
    ThemeData theme,
    WearableMetricsState wearableMetrics,
    HealthMetricsState healthMetrics,
    User? currentUser,
  ) {
    final restingHR = wearableMetrics.restingHeartRate > 0 ? wearableMetrics.restingHeartRate.toDouble() : 62.0;
    final hrSpots = [
      const FlSpot(0, 68),
      const FlSpot(1, 66),
      const FlSpot(2, 65),
      const FlSpot(3, 67),
      const FlSpot(4, 63),
      FlSpot(5, restingHR),
      FlSpot(6, restingHR),
    ];

    final defaultWeight = currentUser?.profile.weight ?? 78.5;
    final latestWeightVal = healthMetrics.latestWeight != null
        ? healthMetrics.latestWeight!.value
        : defaultWeight;
    final weightSpots = _buildWeightSpots(healthMetrics.weights, defaultWeight);

    final bpSystolic = healthMetrics.latestPressure != null ? healthMetrics.latestPressure!.value : 118.0;
    final bpSpots = [
      const FlSpot(0, 120),
      const FlSpot(1, 119),
      const FlSpot(2, 117),
      const FlSpot(3, 118),
      const FlSpot(4, 118),
      FlSpot(5, bpSystolic),
      FlSpot(6, bpSystolic),
    ];

    final spo2Val = wearableMetrics.bloodOxygen > 0 
        ? wearableMetrics.bloodOxygen 
        : (healthMetrics.latestSpO2 != null ? healthMetrics.latestSpO2!.value : 98.0);
    final spo2Spots = [
      const FlSpot(0, 97),
      const FlSpot(1, 98),
      const FlSpot(2, 98),
      const FlSpot(3, 99),
      const FlSpot(4, 98),
      FlSpot(5, spo2Val),
      FlSpot(6, spo2Val),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid of Quick stats with sparklines
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _QuickStatCard(
              icon: Icons.favorite,
              label: 'FC Reposo',
              value: wearableMetrics.restingHeartRate > 0 ? '${wearableMetrics.restingHeartRate}' : '62',
              unit: 'bpm',
              color: const Color(0xFFEF4444),
              trend: wearableMetrics.restingHeartRate > 0 ? 'Sync' : '-3 bpm',
              trendDown: true,
              spots: hrSpots,
            ),
            _QuickStatCard(
              icon: Icons.monitor_weight,
              label: 'Peso',
              value: latestWeightVal.toStringAsFixed(1),
              unit: 'kg',
              color: const Color(0xFF3B82F6),
              trend: healthMetrics.latestWeight != null ? 'Manual' : 'Perfil',
              trendDown: true,
              spots: weightSpots,
            ),
            _QuickStatCard(
              icon: Icons.bloodtype,
              label: 'Presión',
              value: healthMetrics.latestPressure != null 
                  ? '${healthMetrics.latestPressure!.value.toStringAsFixed(0)}/${healthMetrics.latestPressure!.valueSecondary?.toStringAsFixed(0) ?? "80"}' 
                  : '118/76',
              unit: 'mmHg',
              color: const Color(0xFF10B981),
              trend: healthMetrics.latestPressure != null ? 'Manual' : 'Normal',
              trendDown: false,
              spots: bpSpots,
            ),
            _QuickStatCard(
              icon: Icons.air,
              label: 'SpO2',
              value: spo2Val.toStringAsFixed(0),
              unit: '%',
              color: const Color(0xFF06B6D4),
              trend: wearableMetrics.bloodOxygen > 0 ? 'Sync' : 'Óptimo',
              trendDown: false,
              spots: spo2Spots,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // AI Insights Bubble
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.tertiary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(end: const Offset(1.15, 1.15), duration: 1.seconds),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach Health Insight',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu recuperación cardiovascular es óptima (FC de reposo en 62 bpm). Notamos un déficit de 45 minutos de sueño profundo promedio esta semana. Intenta limitar pantallas tras las 21:30 para mejorar la calidad del descanso.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Nutrition Shortcut Card
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NutritionScreen()),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF97316).withValues(alpha: 0.12),
                  const Color(0xFFFACC15).withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrición y Comidas IA',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analiza tus platos con IA, calibra macros y controla tu balance calórico.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: const Color(0xFFF97316).withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== COMPOSICIÓN (PESO) TAB ====================
  Widget _buildComposicionTab(
    ThemeData theme,
    HealthMetricsState healthMetrics,
    User? currentUser,
  ) {
    final defaultWeight = currentUser?.profile.weight ?? 78.5;
    final targetWeight = currentUser?.profile.targetWeight ?? 75.0;
    final latestWeightVal = healthMetrics.latestWeight != null
        ? healthMetrics.latestWeight!.value
        : defaultWeight;
    final weightSpots = _buildWeightSpots(healthMetrics.weights, defaultWeight);

    final minWeight = weightSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxWeight = weightSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = (minWeight - 2).clamp(0.0, 300.0);
    final maxY = maxWeight + 2;

    final targetDiff = latestWeightVal - targetWeight;
    final diffSign = targetDiff > 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.scale_rounded, color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Peso Corporal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Objetivo: ${targetWeight.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Weight Line Chart with baseline
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toStringAsFixed(0)}k',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.outline,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                              if (value >= 0 && value < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.outline,
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        // Baseline Meta
                        LineChartBarData(
                          spots: [
                            FlSpot(0, targetWeight),
                            FlSpot(6, targetWeight),
                          ],
                          isCurved: false,
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          barWidth: 1.5,
                          dashArray: const [5, 5],
                          dotData: const FlDotData(show: false),
                        ),
                        // Current Weight
                        LineChartBarData(
                          spots: weightSpots,
                          isCurved: true,
                          color: const Color(0xFF3B82F6),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(
                            show: true,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                const Color(0xFF3B82F6).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diferencia para Meta',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$diffSign${targetDiff.toStringAsFixed(1)} kg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: targetDiff <= 0 ? const Color(0xFF10B981) : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Velocidad Semanal',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '-0.3 kg / sem',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== CARDIO TAB ====================
  Widget _buildCardioTab(ThemeData theme, WearableMetricsState wearableMetrics) {
    final hasSync = wearableMetrics.averageHeartRate > 0;
    final avgHr = hasSync ? wearableMetrics.averageHeartRate : 72;
    final minHr = wearableMetrics.restingHeartRate > 0 ? wearableMetrics.restingHeartRate : 48;
    final maxHr = hasSync ? (avgHr * 1.5).round().clamp(100, 195) : 178;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Zonas de Ritmo Cardíaco',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // HR Zones Graphic (Stacked Bar representation)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildZoneItem(
                      label: 'Zona 4 (Pico: 170+ bpm)',
                      percentage: 0.05,
                      timeText: '12 min',
                      color: const Color(0xFFEC4899),
                      theme: theme,
                    ),
                    _buildZoneItem(
                      label: 'Zona 3 (Cardio: 140-169 bpm)',
                      percentage: 0.20,
                      timeText: '48 min',
                      color: const Color(0xFFF97316),
                      theme: theme,
                    ),
                    _buildZoneItem(
                      label: 'Zona 2 (Quema Grasa: 110-139 bpm)',
                      percentage: 0.35,
                      timeText: '1h 24m',
                      color: const Color(0xFFF59E0B),
                      theme: theme,
                    ),
                    _buildZoneItem(
                      label: 'Zona 1 (Reposo/Ligero: <110 bpm)',
                      percentage: 0.40,
                      timeText: '10h 15m',
                      color: const Color(0xFF10B981),
                      theme: theme,
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Key metrics
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardioMiniStat('Mínimo', '$minHr bpm', theme),
                    _buildCardioMiniStat('Promedio', '$avgHr bpm', theme),
                    _buildCardioMiniStat('Máximo', '$maxHr bpm', theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneItem({
    required String label,
    required double percentage,
    required String timeText,
    required Color color,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '$timeText (${(percentage * 100).round()}%)',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardioMiniStat(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  // Helper to format decimal hours into Hh Mm
  String _formatHours(double hours) {
    final h = hours.toInt();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  // ==================== SUEÑO TAB ====================
  Widget _buildSuenoTab(ThemeData theme, WearableMetricsState wearableMetrics) {
    final deep = wearableMetrics.deepSleepHours > 0 ? wearableMetrics.deepSleepHours : 1.33;
    final rem = wearableMetrics.remSleepHours > 0 ? wearableMetrics.remSleepHours : 1.63;
    final light = wearableMetrics.lightSleepHours > 0 ? wearableMetrics.lightSleepHours : 3.70;
    final awake = wearableMetrics.sleepHours > 0 ? (wearableMetrics.sleepHours * 0.1).clamp(0.2, 1.5) : 0.73;

    final total = deep + rem + light + awake;
    final deepPct = (deep / total * 100).round();
    final remPct = (rem / total * 100).round();
    final lightPct = (light / total * 100).round();
    final awakePct = (awake / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bedtime_rounded, color: Color(0xFF8B5CF6), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Calidad de Sueño',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Óptimo',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Custom Sleep Phases distribution bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Promedio: ${_formatHours(deep + rem + light)} / Noche',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Eficiencia: 89%',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stacked bar of sleep phases
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 16,
                        child: Row(
                          children: [
                            Expanded(
                              flex: deepPct,
                              child: Container(
                                color: const Color(0xFF6D28D9), // Deep Purple
                                child: Tooltip(message: 'Profundo ($deepPct%)'),
                              ),
                            ),
                            Expanded(
                              flex: remPct,
                              child: Container(
                                color: const Color(0xFF8B5CF6), // Purple
                                child: Tooltip(message: 'REM ($remPct%)'),
                              ),
                            ),
                            Expanded(
                              flex: lightPct,
                              child: Container(
                                color: const Color(0xFF3B82F6), // Blue
                                child: Tooltip(message: 'Ligero ($lightPct%)'),
                              ),
                            ),
                            Expanded(
                              flex: awakePct,
                              child: Container(
                                color: const Color(0xFFF59E0B), // Amber
                                child: Tooltip(message: 'Despierto ($awakePct%)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildSleepLegendItem('Profundo (${_formatHours(deep)})', const Color(0xFF6D28D9), theme),
                        _buildSleepLegendItem('REM (${_formatHours(rem)})', const Color(0xFF8B5CF6), theme),
                        _buildSleepLegendItem('Ligero (${_formatHours(light)})', const Color(0xFF3B82F6), theme),
                        _buildSleepLegendItem('Despierto (${_formatHours(awake)})', const Color(0xFFF59E0B), theme),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Latencia', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        const SizedBox(height: 2),
                        Text('14 min', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Despertares', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        const SizedBox(height: 2),
                        Text('2 veces', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Calificación', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                        const SizedBox(height: 2),
                        Text('88 / 100', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  // ==================== MODAL REGISTER DIALOGS ====================

  void _showAddMetricSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registrar Métrica',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona el tipo de dato de salud que deseas registrar hoy para llevar un control detallado.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _buildAddMetricTile(
                theme: theme,
                icon: Icons.monitor_weight_rounded,
                title: 'Peso Corporal',
                subtitle: 'Evolución de masa corporal en kg',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _showManualMetricInputDialog(context, 'peso', 'Peso Corporal', 'kg', 50.0, 150.0, 78.5);
                },
              ),
              _buildAddMetricTile(
                theme: theme,
                icon: Icons.bloodtype_rounded,
                title: 'Presión Arterial',
                subtitle: 'Sistólica / Diastólica (mmHg)',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  _showDoubleMetricInputDialog(context, 'presion', 'Presión Arterial', 'Sistólica', 'Diastólica', 'mmHg', 120, 80);
                },
              ),
              _buildAddMetricTile(
                theme: theme,
                icon: Icons.air_rounded,
                title: 'SpO2',
                subtitle: 'Saturación de oxígeno en sangre (%)',
                color: const Color(0xFF06B6D4),
                onTap: () {
                  Navigator.pop(context);
                  _showManualMetricInputDialog(context, 'spo2', 'Saturación de Oxígeno', '%', 80.0, 100.0, 98.0);
                },
              ),
              _buildAddMetricTile(
                theme: theme,
                icon: Icons.opacity_rounded,
                title: 'Glucosa',
                subtitle: 'Nivel de azúcar en sangre (mg/dL)',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.pop(context);
                  _showManualMetricInputDialog(context, 'glucosa', 'Glucosa en Sangre', 'mg/dL', 40.0, 300.0, 90.0);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMetricTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog for simple single numeric values
  void _showManualMetricInputDialog(
    BuildContext context,
    String key,
    String title,
    String unit,
    double min,
    double max,
    double initialValue,
  ) {
    final theme = Theme.of(context);
    double currentValue = initialValue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registrar $title',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Value Display Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentValue.toStringAsFixed(1),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        unit,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Interactive Slider for fast input
              Slider(
                value: currentValue,
                min: min,
                max: max,
                onChanged: (val) {
                  setModalState(() => currentValue = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(healthMetricsProvider.notifier).logMetric(
                      type: key,
                      value: currentValue,
                      unit: unit,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title guardado: ${currentValue.toStringAsFixed(1)} $unit')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirmar y Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog for double values (e.g. Systolic/Diastolic BP)
  void _showDoubleMetricInputDialog(
    BuildContext context,
    String key,
    String title,
    String label1,
    String label2,
    String unit,
    int initialVal1,
    int initialVal2,
  ) {
    final theme = Theme.of(context);
    int val1 = initialVal1;
    int val2 = initialVal2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registrar $title',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Double Value Display Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$val1 / $val2',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        unit,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Double Slider / Increments controls
              Text('$label1 (Sistólica)', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Slider(
                value: val1.toDouble(),
                min: 80,
                max: 180,
                onChanged: (val) {
                  setModalState(() => val1 = val.round());
                },
              ),
              const SizedBox(height: 8),
              Text('$label2 (Diastólica)', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
              Slider(
                value: val2.toDouble(),
                min: 50,
                max: 110,
                onChanged: (val) {
                  setModalState(() => val2 = val.round());
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(healthMetricsProvider.notifier).logMetric(
                      type: key,
                      value: val1.toDouble(),
                      valueSecondary: val2.toDouble(),
                      unit: unit,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title guardada: $val1/$val2 $unit')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirmar y Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PREMIUM QUICK STAT CARD WITH SPARKLINE ====================

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String trend;
  final bool trendDown;
  final List<FlSpot> spots;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
    required this.trendDown,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendDown ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trendDown ? Icons.arrow_downward : Icons.arrow_forward,
                        size: 10,
                        color: trendDown ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: trendDown ? const Color(0xFF10B981) : Colors.grey,
                        ),
                      ),
                    ],
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Integrated Sparkline
            SizedBox(
              height: 28,
              width: double.infinity,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.12),
                            color.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
