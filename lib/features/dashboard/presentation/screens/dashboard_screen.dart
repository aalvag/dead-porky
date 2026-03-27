import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/daily_summary_card.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/recent_workouts_card.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/habits_today_card.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/health_metrics_card.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/streak_card.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/ai_insights_card.dart';
import 'package:dead_porky/features/dashboard/presentation/widgets/calories_ring_card.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/core/router/app_router.dart';

/// Dashboard widget type enum
enum DashboardWidgetType {
  dailySummary,
  caloriesRing,
  recentWorkouts,
  habitsToday,
  healthMetrics,
  streak,
  aiInsights,
}

/// Dashboard layout provider
final dashboardLayoutProvider = StateProvider<List<DashboardWidgetType>>((ref) {
  return [
    DashboardWidgetType.dailySummary,
    DashboardWidgetType.caloriesRing,
    DashboardWidgetType.habitsToday,
    DashboardWidgetType.recentWorkouts,
    DashboardWidgetType.healthMetrics,
    DashboardWidgetType.streak,
    DashboardWidgetType.aiInsights,
  ];
});

/// Dashboard refreshing state
final dashboardRefreshingProvider = StateProvider<bool>((ref) => false);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isReordering = false;

  Future<void> _handleRefresh() async {
    ref.read(dashboardRefreshingProvider.notifier).state = true;
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));
    ref.read(dashboardRefreshingProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final layout = ref.watch(dashboardLayoutProvider);
    final isRefreshing = ref.watch(dashboardRefreshingProvider);

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
              user?.displayName ?? 'Usuario',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Devices button
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () => context.pushNamed(AppRoutes.deviceScanner),
            tooltip: 'Dispositivos',
          ),
          // Reorder toggle
          IconButton(
            icon: Icon(_isReordering ? Icons.check : Icons.reorder),
            onPressed: () {
              setState(() {
                _isReordering = !_isReordering;
              });
            },
            tooltip: _isReordering ? 'Guardar orden' : 'Reordenar widgets',
          ),
          // AI Chat button
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              // TODO: Navigate to AI chat
            },
            tooltip: 'Asistente IA',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isReordering
            ? _buildReorderableList(layout, ref)
            : _buildNormalList(layout, isRefreshing),
      ),
    );
  }

  Widget _buildNormalList(List<DashboardWidgetType> layout, bool isRefreshing) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: layout.length + 1, // +1 for greeting card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildGreetingBanner();
        }
        final widgetType = layout[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildWidget(widgetType, isRefreshing),
        );
      },
    );
  }

  Widget _buildReorderableList(
    List<DashboardWidgetType> layout,
    WidgetRef ref,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: layout.length,
      onReorder: (oldIndex, newIndex) {
        final newLayout = List<DashboardWidgetType>.from(layout);
        if (newIndex > oldIndex) newIndex--;
        final item = newLayout.removeAt(oldIndex);
        newLayout.insert(newIndex, item);
        ref.read(dashboardLayoutProvider.notifier).state = newLayout;
      },
      itemBuilder: (context, index) {
        final widgetType = layout[index];
        return Padding(
          key: ValueKey(widgetType),
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildWidget(widgetType, false),
        );
      },
    );
  }

  Widget _buildWidget(DashboardWidgetType type, bool isRefreshing) {
    switch (type) {
      case DashboardWidgetType.dailySummary:
        return const DailySummaryCard();
      case DashboardWidgetType.caloriesRing:
        return const CaloriesRingCard();
      case DashboardWidgetType.recentWorkouts:
        return const RecentWorkoutsCard();
      case DashboardWidgetType.habitsToday:
        return const HabitsTodayCard();
      case DashboardWidgetType.healthMetrics:
        return const HealthMetricsCard();
      case DashboardWidgetType.streak:
        return const StreakCard();
      case DashboardWidgetType.aiInsights:
        return const AiInsightsCard();
    }
  }

  Widget _buildGreetingBanner() {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    Color color;

    if (hour < 12) {
      greeting = 'Buenos días';
      icon = Icons.wb_sunny;
      color = Colors.orange;
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
      icon = Icons.wb_cloudy;
      color = Colors.amber;
    } else {
      greeting = 'Buenas noches';
      icon = Icons.nightlight;
      color = Colors.indigo;
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '¿Cómo te sientes hoy?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Mood selector
            Row(
              children: ['😊', '😐', '😔'].map((emoji) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Save mood
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
