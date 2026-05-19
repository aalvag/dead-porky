import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/daily_checkin/presentation/providers/daily_checkin_provider.dart';

class DailyCheckinScreen extends ConsumerStatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  ConsumerState<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends ConsumerState<DailyCheckinScreen> {
  @override
  void initState() {
    super.initState();
    ref.listen<DateTime>(selectedCheckinDateProvider, (_, next) {
      ref.read(dailyCheckinProvider.notifier).loadForDate(next);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dailyCheckinProvider.notifier)
          .loadForDate(ref.read(selectedCheckinDateProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedCheckinDateProvider);
    final checkin = ref.watch(dailyCheckinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in diario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: checkin.isSaving
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(dailyCheckinProvider.notifier).save();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Check-in guardado')),
                    );
                  },
            tooltip: 'Guardar datos',
          ),
        ],
      ),
      body: checkin.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entrada del día',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(selectedDate),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Hidratación'),
                  _buildWaterCard(theme, checkin.waterMl),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Sueño'),
                  _buildSleepCard(theme, checkin.sleepHours),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Entrenamiento y nutrición'),
                  _buildToggleCard(
                    context,
                    label: checkin.workoutCompleted
                        ? 'Entrenamiento registrado'
                        : 'Entrenamiento sin registrar',
                    icon: Icons.fitness_center,
                    isActive: checkin.workoutCompleted,
                    onTap: ref
                        .read(dailyCheckinProvider.notifier)
                        .toggleWorkoutCompleted,
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    context,
                    label: checkin.foodLogged
                        ? 'Comidas registradas'
                        : 'No registraste comidas',
                    icon: Icons.restaurant_menu,
                    isActive: checkin.foodLogged,
                    onTap: ref
                        .read(dailyCheckinProvider.notifier)
                        .toggleFoodLogged,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Estado'),
                  _buildMoodRow(
                    checkin.mood,
                    ref.read(dailyCheckinProvider.notifier).updateMood,
                  ),
                  const SizedBox(height: 12),
                  _buildEnergyRow(
                    checkin.energyLevel,
                    ref.read(dailyCheckinProvider.notifier).updateEnergy,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle(context, 'Notas rápidas'),
                  TextFormField(
                    initialValue: checkin.notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          '¿Cómo te sentiste hoy? Ej: buena energía, alimentos pesados, recuperación...',
                    ),
                    onChanged: ref
                        .read(dailyCheckinProvider.notifier)
                        .updateNotes,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        checkin.hasSavedEntry
                            ? 'Actualizar check-in'
                            : 'Guardar check-in',
                      ),
                      onPressed: checkin.isSaving
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await ref
                                  .read(dailyCheckinProvider.notifier)
                                  .save();
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Check-in guardado'),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Volver al tablero'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWaterCard(ThemeData theme, int waterMl) {
    final progress = (waterMl / 2000).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Agua',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text('$waterMl ml', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: () =>
                      ref.read(dailyCheckinProvider.notifier).updateWater(250),
                  child: const Text('+250 ml'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(dailyCheckinProvider.notifier).updateWater(-250),
                  child: const Text('-250 ml'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(ThemeData theme, double sleepHours) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Sueño',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sleepHours.toStringAsFixed(1)} h',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              min: 0,
              max: 12,
              divisions: 24,
              value: sleepHours,
              label: '${sleepHours.toStringAsFixed(1)} h',
              onChanged: ref.read(dailyCheckinProvider.notifier).updateSleep,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(label),
        trailing: Switch(value: isActive, onChanged: (_) => onTap()),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMoodRow(int mood, ValueChanged<int> onSelect) {
    return Wrap(
      spacing: 8,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = mood == value;
        return ChoiceChip(
          label: Text(['😞', '😐', '🙂', '😃', '🤩'][index]),
          selected: selected,
          onSelected: (_) => onSelect(value),
        );
      }),
    );
  }

  Widget _buildEnergyRow(int energy, ValueChanged<int> onSelect) {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = energy == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('$value'),
            selected: selected,
            onSelected: (_) => onSelect(value),
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
