import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/exercises/domain/entities/workout.dart';
import 'package:dead_porky/features/exercises/presentation/widgets/rest_timer_widget.dart';
import 'package:dead_porky/features/exercises/data/exercise_library.dart';

/// Active workout state
class ActiveWorkoutState {
  final Workout? workout;
  final bool isActive;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final Duration elapsed;

  const ActiveWorkoutState({
    this.workout,
    this.isActive = false,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.elapsed = Duration.zero,
  });

  ActiveWorkoutState copyWith({
    Workout? workout,
    bool? isActive,
    int? currentExerciseIndex,
    int? currentSetIndex,
    Duration? elapsed,
  }) {
    return ActiveWorkoutState(
      workout: workout ?? this.workout,
      isActive: isActive ?? this.isActive,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

/// Active workout notifier
class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  Timer? _timer;

  ActiveWorkoutNotifier() : super(const ActiveWorkoutState());

  void startWorkout({String name = 'Entrenamiento'}) {
    final workout = Workout.create(name: name);
    state = ActiveWorkoutState(
      workout: workout,
      isActive: true,
      elapsed: Duration.zero,
    );

    // Start elapsed time timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.workout != null) {
        final elapsed = DateTime.now().difference(state.workout!.startedAt);
        state = state.copyWith(elapsed: elapsed);
      }
    });
  }

  void addExercise(String exerciseId, String exerciseName) {
    if (state.workout == null) return;

    final exercise = WorkoutExercise.fromExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    );

    final exercises = List<WorkoutExercise>.from(state.workout!.exercises);
    exercises.add(exercise);

    state = state.copyWith(
      workout: state.workout!.copyWith(exercises: exercises),
    );
  }

  void removeExercise(int index) {
    if (state.workout == null) return;

    final exercises = List<WorkoutExercise>.from(state.workout!.exercises);
    if (index >= 0 && index < exercises.length) {
      exercises.removeAt(index);
      state = state.copyWith(
        workout: state.workout!.copyWith(exercises: exercises),
      );
    }
  }

  void updateSet(int exerciseIndex, int setIndex, WorkoutSet set) {
    if (state.workout == null) return;

    final exercises = List<WorkoutExercise>.from(state.workout!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].updateSet(
        setIndex,
        set,
      );
      state = state.copyWith(
        workout: state.workout!.copyWith(exercises: exercises),
      );
    }
  }

  void addSet(int exerciseIndex) {
    if (state.workout == null) return;

    final exercises = List<WorkoutExercise>.from(state.workout!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].addSet();
      state = state.copyWith(
        workout: state.workout!.copyWith(exercises: exercises),
      );
    }
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state.workout == null) return;

    final exercises = List<WorkoutExercise>.from(state.workout!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].removeSet(setIndex);
      state = state.copyWith(
        workout: state.workout!.copyWith(exercises: exercises),
      );
    }
  }

  void completeSet(int exerciseIndex, int setIndex) {
    if (state.workout == null) return;

    final exercises = List<WorkoutExercise>.from(state.workout!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      final exercise = exercises[exerciseIndex];
      if (setIndex >= 0 && setIndex < exercise.sets.length) {
        final set = exercise.sets[setIndex].complete();
        exercises[exerciseIndex] = exercise.updateSet(setIndex, set);

        // Haptic feedback
        HapticFeedback.mediumImpact();

        state = state.copyWith(
          workout: state.workout!.copyWith(exercises: exercises),
        );
      }
    }
  }

  void finishWorkout() {
    _timer?.cancel();

    if (state.workout != null) {
      final finished = state.workout!.copyWith(
        finishedAt: DateTime.now(),
        durationSeconds: state.elapsed.inSeconds,
        totalVolume: state.workout!.calculateTotalVolume(),
      );

      state = state.copyWith(workout: finished, isActive: false);

      // TODO: Save to Firestore and Drift
    }
  }

  void cancelWorkout() {
    _timer?.cancel();
    state = const ActiveWorkoutState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Active workout provider
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
      return ActiveWorkoutNotifier();
    });

/// Active workout screen
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutState = ref.watch(activeWorkoutProvider);
    final workoutNotifier = ref.read(activeWorkoutProvider.notifier);
    final restTimerState = ref.watch(restTimerProvider);
    final restTimer = ref.read(restTimerProvider.notifier);

    // If no active workout, show start screen
    if (!workoutState.isActive || workoutState.workout == null) {
      return _buildStartScreen(theme, workoutNotifier);
    }

    final workout = workoutState.workout!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(workout.name),
            Text(workout.elapsedTime, style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseSheet(context, workoutNotifier),
            tooltip: 'Agregar ejercicio',
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest timer (if running)
          if (restTimerState.isRunning || restTimerState.remainingSeconds > 0)
            const RestTimerWidget(),

          // Exercises list
          Expanded(
            child: workout.exercises.isEmpty
                ? _buildEmptyState(theme, workoutNotifier)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workout.exercises.length + 1,
                    itemBuilder: (context, index) {
                      if (index == workout.exercises.length) {
                        return _buildSummaryCard(workout, theme);
                      }
                      return _ExerciseSetCard(
                        exercise: workout.exercises[index],
                        exerciseIndex: index,
                        onUpdateSet: (setIndex, set) {
                          workoutNotifier.updateSet(index, setIndex, set);
                        },
                        onCompleteSet: (setIndex) {
                          workoutNotifier.completeSet(index, setIndex);
                          // Start rest timer
                          restTimer.startTimer(
                            seconds: workout.exercises[index].restSeconds,
                            currentSet: setIndex + 1,
                            totalSets: workout.exercises[index].sets.length,
                            nextExercise: index < workout.exercises.length - 1
                                ? workout.exercises[index + 1].exerciseName
                                : '',
                            nextReps: '8-12 reps',
                          );
                        },
                        onAddSet: () {
                          workoutNotifier.addSet(index);
                        },
                        onRemoveSet: (setIndex) {
                          workoutNotifier.removeSet(index, setIndex);
                        },
                        onRemoveExercise: () {
                          workoutNotifier.removeExercise(index);
                        },
                      );
                    },
                  ),
          ),

          // Bottom bar
          _buildBottomBar(theme, workoutNotifier),
        ],
      ),
    );
  }

  Widget _buildStartScreen(ThemeData theme, ActiveWorkoutNotifier notifier) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '¿Listo para entrenar?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia un nuevo entrenamiento o usa una plantilla',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  notifier.startWorkout();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar entrenamiento vacío'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Show templates
                },
                icon: const Icon(Icons.copy),
                label: const Text('Usar plantilla'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ActiveWorkoutNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text('Agrega ejercicios', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Toca + para agregar ejercicios a tu entrenamiento',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddExerciseSheet(context, notifier),
              icon: const Icon(Icons.add),
              label: const Text('Agregar ejercicio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Workout workout, ThemeData theme) {
    final totalSets = workout.exercises.fold<int>(
      0,
      (sum, e) => sum + e.sets.where((s) => s.completed).length,
    );
    final totalVolume = workout.calculateTotalVolume();

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              value: '${workout.exercises.length}',
              label: 'Ejercicios',
              icon: Icons.fitness_center,
            ),
            _SummaryItem(
              value: '$totalSets',
              label: 'Series',
              icon: Icons.repeat,
            ),
            _SummaryItem(
              value: '${totalVolume.toStringAsFixed(0)} kg',
              label: 'Volumen',
              icon: Icons.monitor_weight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, ActiveWorkoutNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showCancelDialog(context, notifier);
              },
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                _showFinishDialog(context, notifier);
              },
              icon: const Icon(Icons.check),
              label: const Text('Finalizar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseSheet(
    BuildContext context,
    ActiveWorkoutNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Agregar ejercicio',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: ExerciseLibrary.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = ExerciseLibrary.exercises[index];
                      return ListTile(
                        leading: Text(
                          ExerciseLibrary.getCategoryIcon(exercise['category']),
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(exercise['name']),
                        subtitle: Text(
                          ExerciseLibrary.getEquipmentName(
                            exercise['equipment'],
                          ),
                        ),
                        onTap: () {
                          notifier.addExercise(
                            exercise['id'],
                            exercise['name'],
                          );
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, ActiveWorkoutNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar entrenamiento'),
          content: const Text('¿Estás seguro? Se perderá todo el progreso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar entrenando'),
            ),
            FilledButton(
              onPressed: () {
                notifier.cancelWorkout();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showFinishDialog(BuildContext context, ActiveWorkoutNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Finalizar entrenamiento'),
          content: const Text('¿Listo? Se guardará tu progreso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Seguir entrenando'),
            ),
            FilledButton(
              onPressed: () {
                notifier.finishWorkout();
                Navigator.pop(context);
              },
              child: const Text('Finalizar'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ExerciseSetCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final Function(int, WorkoutSet) onUpdateSet;
  final Function(int) onCompleteSet;
  final VoidCallback onAddSet;
  final Function(int) onRemoveSet;
  final VoidCallback onRemoveExercise;

  const _ExerciseSetCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.onUpdateSet,
    required this.onCompleteSet,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onRemoveExercise,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Set headers
            Row(
              children: [
                const SizedBox(width: 30),
                const Expanded(
                  child: Text('Peso', textAlign: TextAlign.center),
                ),
                const Expanded(
                  child: Text('Reps', textAlign: TextAlign.center),
                ),
                const Expanded(child: Text('RPE', textAlign: TextAlign.center)),
                const SizedBox(width: 50),
              ],
            ),
            const Divider(),

            // Sets
            ...exercise.sets.asMap().entries.map((entry) {
              final index = entry.key;
              final set = entry.value;
              return _SetRow(
                set: set,
                onUpdate: (updatedSet) => onUpdateSet(index, updatedSet),
                onComplete: () => onCompleteSet(index),
                onRemove: exercise.sets.length > 1
                    ? () => onRemoveSet(index)
                    : null,
              );
            }),

            const SizedBox(height: 8),

            // Add set button
            Center(
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar serie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final WorkoutSet set;
  final Function(WorkoutSet) onUpdate;
  final VoidCallback onComplete;
  final VoidCallback? onRemove;

  const _SetRow({
    required this.set,
    required this.onUpdate,
    required this.onComplete,
    this.onRemove,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight > 0 ? widget.set.weight.toStringAsFixed(1) : '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(_SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set != widget.set) {
      _weightController.text = widget.set.weight > 0
          ? widget.set.weight.toStringAsFixed(1)
          : '';
      _repsController.text = widget.set.reps > 0
          ? widget.set.reps.toString()
          : '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: widget.set.completed
            ? Colors.green.withValues(alpha: 0.1)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 30,
            child: Text(
              '${widget.set.setNumber}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.set.completed ? Colors.green : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Weight
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: 'kg',
                ),
                onChanged: (value) {
                  final weight = double.tryParse(value) ?? 0;
                  widget.onUpdate(widget.set.copyWith(weight: weight));
                },
              ),
            ),
          ),

          // Reps
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: '0',
                ),
                onChanged: (value) {
                  final reps = int.tryParse(value) ?? 0;
                  widget.onUpdate(widget.set.copyWith(reps: reps));
                },
              ),
            ),
          ),

          // RPE
          Expanded(
            child: GestureDetector(
              onTap: () => _showRPEPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: widget.set.rpe != null
                      ? RPEScale.getColor(
                          widget.set.rpe!,
                        ).withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.set.rpe?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.set.rpe != null
                        ? RPEScale.getColor(widget.set.rpe!)
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Complete button
          SizedBox(
            width: 50,
            child: widget.set.completed
                ? IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () {
                      widget.onUpdate(widget.set.copyWith(completed: false));
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () {
                      final reps = int.tryParse(_repsController.text) ?? 0;
                      final weight =
                          double.tryParse(_weightController.text) ?? 0;
                      widget.onUpdate(
                        widget.set.copyWith(reps: reps, weight: weight),
                      );
                      widget.onComplete();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRPEPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RPE (Esfuerzo Percibido)',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(10, (index) {
                  final rpe = index + 1;
                  final isSelected = widget.set.rpe == rpe;
                  return ChoiceChip(
                    label: Text('$rpe'),
                    selected: isSelected,
                    onSelected: (selected) {
                      widget.onUpdate(widget.set.copyWith(rpe: rpe));
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                widget.set.rpe != null
                    ? RPEScale.getDescription(widget.set.rpe!)
                    : 'Selecciona tu esfuerzo',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
