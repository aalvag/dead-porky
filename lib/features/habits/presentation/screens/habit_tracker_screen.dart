import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/habits/domain/entities/habit.dart';

// ==================== Providers ====================

final habitsProvider = StateProvider<List<Habit>>((ref) {
  return PresetHabits.habits
      .map(
        (h) => Habit.create(
          name: h['name'],
          icon: h['icon'],
          color: h['color'],
          type: h['type'],
          targetValue: h['targetValue'],
          targetUnit: h['targetUnit'],
          category: h['category'],
          frequency: HabitFrequency.daily,
        ),
      )
      .toList();
});

final habitLogsProvider = StateProvider<Map<String, Map<String, double>>>((
  ref,
) {
  return {}; // {habitId: {date: value}}
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// ==================== Screen ====================

class HabitTrackerScreen extends ConsumerWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitsProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final habitLogs = ref.watch(habitLogsProvider);

    final completedToday = habits.where((h) {
      final dateKey = _dateKey(selectedDate);
      return habitLogs[h.id]?[dateKey] != null &&
          (h.type == HabitType.boolean
              ? habitLogs[h.id]![dateKey]! > 0
              : habitLogs[h.id]![dateKey]! >= (h.targetValue ?? 1));
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHabitSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          _DateSelector(
            selectedDate: selectedDate,
            onDateChanged: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),

          // Progress summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '$completedToday/${habits.length} completados',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(completedToday / habits.length * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Habits list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final dateKey = _dateKey(selectedDate);
                final value = habitLogs[habit.id]?[dateKey] ?? 0;
                final isCompleted = habit.type == HabitType.boolean
                    ? value > 0
                    : value >= (habit.targetValue ?? 1);

                return _HabitCard(
                  habit: habit,
                  currentValue: value,
                  isCompleted: isCompleted,
                  onTap: () => _toggleHabit(context, ref, habit),
                  onIncrement: () => _incrementHabit(ref, habit),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _toggleHabit(BuildContext context, WidgetRef ref, Habit habit) {
    final logs = Map<String, Map<String, double>>.from(
      ref.read(habitLogsProvider),
    );
    final dateKey = _dateKey(ref.read(selectedDateProvider));

    logs[habit.id] ??= {};
    final current = logs[habit.id]![dateKey] ?? 0;

    if (habit.type == HabitType.boolean) {
      logs[habit.id]![dateKey] = current > 0 ? 0 : 1;
    } else {
      _showValueDialog(context, ref, habit, logs, dateKey);
      return;
    }

    ref.read(habitLogsProvider.notifier).state = logs;
  }

  void _incrementHabit(WidgetRef ref, Habit habit) {
    final logs = Map<String, Map<String, double>>.from(
      ref.read(habitLogsProvider),
    );
    final dateKey = _dateKey(ref.read(selectedDateProvider));

    logs[habit.id] ??= {};
    logs[habit.id]![dateKey] = (logs[habit.id]![dateKey] ?? 0) + 1;

    ref.read(habitLogsProvider.notifier).state = logs;
  }

  void _showValueDialog(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    Map<String, Map<String, double>> logs,
    String dateKey,
  ) {
    final controller = TextEditingController(
      text: (logs[habit.id]?[dateKey] ?? 0).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(habit.name),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: habit.targetUnit ?? 'Valor',
            suffixText: habit.targetUnit,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0;
              logs[habit.id] ??= {};
              logs[habit.id]![dateKey] = value;
              ref.read(habitLogsProvider.notifier).state = logs;
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddHabitSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Agregar hábito',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: PresetHabits.habits.length,
                itemBuilder: (context, index) {
                  final preset = PresetHabits.habits[index];
                  return ListTile(
                    leading: Text(
                      preset['icon'],
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(preset['name']),
                    subtitle: Text(preset['type'].label),
                    onTap: () {
                      final habit = Habit.create(
                        name: preset['name'],
                        icon: preset['icon'],
                        color: preset['color'],
                        type: preset['type'],
                        targetValue: preset['targetValue'],
                        targetUnit: preset['targetUnit'],
                        category: preset['category'],
                        frequency: HabitFrequency.daily,
                      );
                      final habits = List<Habit>.from(ref.read(habitsProvider));
                      habits.add(habit);
                      ref.read(habitsProvider.notifier).state = habits;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Widgets ====================

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days.map((date) {
          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return GestureDetector(
            onTap: () => onDateChanged(date),
            child: Container(
              width: 45,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: theme.colorScheme.primary)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['L', 'M', 'X', 'J', 'V', 'S', 'D'][date.weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final double currentValue;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onIncrement;

  const _HabitCard({
    required this.habit,
    required this.currentValue,
    required this.isCompleted,
    required this.onTap,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = habit.targetValue != null
        ? (currentValue / habit.targetValue!).clamp(0.0, 1.0)
        : (isCompleted ? 1.0 : 0.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCompleted ? habit.color.withValues(alpha: 0.15) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(habit.icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (habit.type != HabitType.boolean)
                      Text(
                        '${currentValue.toStringAsFixed(0)} / ${habit.targetValue?.toStringAsFixed(0) ?? '?'} ${habit.targetUnit ?? ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (habit.type != HabitType.boolean) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(habit.color),
                      ),
                    ],
                  ],
                ),
              ),

              // Streak / Action
              if (habit.type == HabitType.boolean)
                Icon(
                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: isCompleted ? Colors.green : theme.colorScheme.outline,
                  size: 32,
                )
              else
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: habit.color,
                  iconSize: 32,
                  onPressed: onIncrement,
                ),

              // Streak badge
              if (habit.currentStreak > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      Text(
                        '${habit.currentStreak}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
