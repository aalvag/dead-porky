import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

// ==================== Entities ====================

class HealthMetric {
  final String type;
  final double value;
  final double? valueSecondary;
  final String unit;
  final DateTime measuredAt;
  final String source;

  const HealthMetric({
    required this.type,
    required this.value,
    this.valueSecondary,
    required this.unit,
    required this.measuredAt,
    this.source = 'manual',
  });
}

// ==================== Screen ====================

class HealthMetricsScreen extends ConsumerWidget {
  const HealthMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas de Salud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMetricSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.favorite,
                    label: 'FC Reposo',
                    value: '62',
                    unit: 'bpm',
                    color: Colors.red,
                    trend: '-3 bpm',
                    trendDown: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.monitor_weight,
                    label: 'Peso',
                    value: '78.5',
                    unit: 'kg',
                    color: Colors.blue,
                    trend: '-0.3 kg',
                    trendDown: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.bloodtype,
                    label: 'Presión',
                    value: '118/76',
                    unit: 'mmHg',
                    color: Colors.green,
                    trend: 'Normal',
                    trendDown: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.air,
                    label: 'SpO2',
                    value: '98',
                    unit: '%',
                    color: Colors.cyan,
                    trend: 'Óptimo',
                    trendDown: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weight chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_down, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Peso - Últimos 7 días',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 79.2),
                                FlSpot(1, 79.0),
                                FlSpot(2, 78.8),
                                FlSpot(3, 78.9),
                                FlSpot(4, 78.7),
                                FlSpot(5, 78.6),
                                FlSpot(6, 78.5),
                              ],
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tendencia: -0.7 kg esta semana',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Heart rate chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Frecuencia Cardíaca - Hoy',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _barGroup(0, 65, Colors.red),
                            _barGroup(1, 72, Colors.red),
                            _barGroup(2, 85, Colors.orange),
                            _barGroup(3, 68, Colors.red),
                            _barGroup(4, 62, Colors.red),
                            _barGroup(5, 95, Colors.orange),
                            _barGroup(6, 70, Colors.red),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _LegendItem(color: Colors.red, label: 'Reposo'),
                        _LegendItem(color: Colors.orange, label: 'Activo'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sleep chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bedtime, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          'Sueño - Últimos 7 días',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _barGroup(0, 7.2, Colors.purple),
                            _barGroup(1, 6.8, Colors.purple),
                            _barGroup(2, 7.5, Colors.purple),
                            _barGroup(3, 6.5, Colors.orange),
                            _barGroup(4, 7.8, Colors.purple),
                            _barGroup(5, 8.0, Colors.green),
                            _barGroup(6, 7.3, Colors.purple),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Promedio: 7.3 horas/noche',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add metric button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddMetricSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Registrar métrica manual'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  void _showAddMetricSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar métrica',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.monitor_weight, color: Colors.blue),
              title: const Text('Peso'),
              subtitle: const Text('Registrar peso corporal'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show weight input dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Presión arterial'),
              subtitle: const Text('Sistólica / Diastólica'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show BP input dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.air, color: Colors.cyan),
              title: const Text('SpO2'),
              subtitle: const Text('Saturación de oxígeno'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show SpO2 input dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.bloodtype, color: Colors.orange),
              title: const Text('Glucosa'),
              subtitle: const Text('Nivel de azúcar en sangre'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show glucose input dialog
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Widgets ====================

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String trend;
  final bool trendDown;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
    required this.trendDown,
  });

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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
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
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trendDown ? Icons.trending_down : Icons.trending_flat,
                  size: 14,
                  color: trendDown ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trendDown ? Colors.green : Colors.grey,
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
