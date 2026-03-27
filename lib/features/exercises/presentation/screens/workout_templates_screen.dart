import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/exercises/domain/entities/workout_template.dart';
import 'package:fl_chart/fl_chart.dart';

class WorkoutTemplatesScreen extends ConsumerStatefulWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  ConsumerState<WorkoutTemplatesScreen> createState() =>
      _WorkoutTemplatesScreenState();
}

class _WorkoutTemplatesScreenState extends ConsumerState<WorkoutTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Biblioteca'),
            Tab(text: 'Plantillas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLibraryTab(),
          _buildTemplatesTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    // This shows the existing exercise library
    return const Center(child: Text('Biblioteca (ya implementada)'));
  }

  Widget _buildTemplatesTab() {
    final theme = Theme.of(context);
    final templates = PresetTemplates.templates;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.copy),
            ),
            title: Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${template.exercises.length} ejercicios · ~${template.estimatedDuration} min',
            ),
            trailing: FilledButton(
              onPressed: () {
                // TODO: Start workout from template
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Iniciando: ${template.name}')),
                );
              },
              child: const Text('Iniciar'),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: template.exercises.map((exercise) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(exercise.exerciseName)),
                          Text(
                            '${exercise.targetSets}x${exercise.targetReps}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    final theme = Theme.of(context);
    final history = PresetHistory.items;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volumen Semanal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: history.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.totalVolume / 1000,
                                color: Colors.blue,
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats summary
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Entrenamientos',
                  value: '${history.length}',
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Volumen total',
                  value:
                      '${(history.fold<double>(0, (sum, h) => sum + h.totalVolume) / 1000).toStringAsFixed(0)}k kg',
                  icon: Icons.monitor_weight,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  label: 'Promedio',
                  value:
                      '${history.fold<int>(0, (sum, h) => sum + h.durationMinutes) ~/ history.length} min',
                  icon: Icons.timer,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // History list
          Text(
            'Historial',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...history.map((item) => _HistoryCard(item: item)),
        ],
      ),
    );
  }
}

// ==================== Widgets ====================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkoutHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysDiff = DateTime.now().difference(item.date).inDays;
    final dateStr = daysDiff == 0
        ? 'Hoy'
        : daysDiff == 1
        ? 'Ayer'
        : 'Hace $daysDiff días';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.fitness_center),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$dateStr · ${item.durationMinutes} min · ${item.totalSets} series',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(item.totalVolume / 1000).toStringAsFixed(1)}k',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('kg', style: theme.textTheme.bodySmall),
          ],
        ),
        onTap: () {
          // TODO: Show workout detail
        },
      ),
    );
  }
}
