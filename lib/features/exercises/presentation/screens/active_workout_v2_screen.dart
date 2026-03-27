import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/exercises/domain/entities/workout_v2.dart';
import 'package:dead_porky/features/exercises/data/exercise_library.dart';
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_real.dart';

// ==================== Providers ====================

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, WorkoutSession?>((ref) {
      return ActiveSessionNotifier();
    });

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
      return RestTimerNotifier();
    });

// ==================== Rest Timer State ====================

class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final String nextExercise;
  final String nextSetInfo;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 90,
    this.isRunning = false,
    this.nextExercise = '',
    this.nextSetInfo = '',
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    String? nextExercise,
    String? nextSetInfo,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      nextExercise: nextExercise ?? this.nextExercise,
      nextSetInfo: nextSetInfo ?? this.nextSetInfo,
    );
  }
}

// ==================== Rest Timer Notifier ====================

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(const RestTimerState());

  void start({
    int seconds = 90,
    String nextExercise = '',
    String nextSetInfo = '',
  }) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      nextExercise: nextExercise,
      nextSetInfo: nextSetInfo,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(isRunning: false);
        HapticFeedback.heavyImpact();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
  }

  void resume() {
    if (state.remainingSeconds > 0) {
      start(
        seconds: state.remainingSeconds,
        nextExercise: state.nextExercise,
        nextSetInfo: state.nextSetInfo,
      );
    }
  }

  void skip() {
    _timer?.cancel();
    state = const RestTimerState();
  }

  void addTime(int seconds) {
    state = state.copyWith(
      remainingSeconds: (state.remainingSeconds + seconds).clamp(0, 9999),
      totalSeconds: (state.totalSeconds + seconds).clamp(0, 9999),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ==================== Active Session Notifier ====================

class ActiveSessionNotifier extends StateNotifier<WorkoutSession?> {
  Timer? _durationTimer;

  ActiveSessionNotifier() : super(null);

  void startSession({String name = 'Entrenamiento'}) {
    state = WorkoutSession(name: name);
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Trigger rebuild to update duration display
      if (state != null) {
        state = state!.copyWith();
      }
    });
  }

  void addExercise(String exerciseId, String exerciseName, String category) {
    if (state == null) return;

    final exercise = WorkoutExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      category: category,
      sets: [WorkoutSet(setNumber: 1, type: SetType.warmup)],
    );

    state = state!.addExercise(exercise);
  }

  void removeExercise(int index) {
    if (state == null) return;
    state = state!.removeExercise(index);
  }

  void updateExercise(int index, WorkoutExercise exercise) {
    if (state == null) return;
    state = state!.updateExercise(index, exercise);
  }

  void addSet(int exerciseIndex, {SetType type = SetType.normal}) {
    if (state == null) return;

    final exercises = List<WorkoutExercise>.from(state!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].addSet(type: type);
      state = state!.copyWith(exercises: exercises);
    }
  }

  void addDropSet(int exerciseIndex) {
    if (state == null) return;

    final exercises = List<WorkoutExercise>.from(state!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].addDropSet();
      state = state!.copyWith(exercises: exercises);
    }
  }

  void updateSet(int exerciseIndex, int setIndex, WorkoutSet set) {
    if (state == null) return;

    final exercises = List<WorkoutExercise>.from(state!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].updateSet(
        setIndex,
        set,
      );
      state = state!.copyWith(exercises: exercises);
    }
  }

  void completeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;

    final exercises = List<WorkoutExercise>.from(state!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      final exercise = exercises[exerciseIndex];
      if (setIndex >= 0 && setIndex < exercise.sets.length) {
        final set = exercise.sets[setIndex].complete();
        exercises[exerciseIndex] = exercise.updateSet(setIndex, set);
        state = state!.copyWith(exercises: exercises);
        HapticFeedback.mediumImpact();
      }
    }
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;

    final exercises = List<WorkoutExercise>.from(state!.exercises);
    if (exerciseIndex >= 0 && exerciseIndex < exercises.length) {
      exercises[exerciseIndex] = exercises[exerciseIndex].removeSet(setIndex);
      state = state!.copyWith(exercises: exercises);
    }
  }

  /// Finish session and get AI evaluation
  Future<String> finishAndGetEvaluation() async {
    if (state == null) return '';

    final session = state!.finish();
    state = session;

    // Generate AI evaluation
    final context = session.toAIContext();
    final gateway = KiloGatewayReal();

    final systemPrompt =
        '''Eres un entrenador personal experto. Evalúa el siguiente entrenamiento y proporciona:
1. Resumen del rendimiento
2. Fortalezas identificadas
3. Áreas de mejora
4. Recomendaciones para el próximo entrenamiento
5. Predicción de progresión

Responde en español, de forma concisa y motivadora. Usa emojis.''';

    final userPrompt = '''Evalúa este entrenamiento:

${context.toString()}''';

    try {
      final evaluation = await gateway.chat(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        maxTokens: 1000,
      );
      return evaluation;
    } catch (e) {
      return _generateFallbackEvaluation(session);
    }
  }

  String _generateFallbackEvaluation(WorkoutSession session) {
    final buffer = StringBuffer();
    buffer.writeln('📊 **Resumen del Entrenamiento**');
    buffer.writeln('');
    buffer.writeln('⏱️ Duración: ${session.formattedDuration}');
    buffer.writeln('🏋️ Ejercicios: ${session.totalExercises}');
    buffer.writeln('💪 Series completadas: ${session.totalCompletedSets}');
    buffer.writeln(
      '📦 Volumen total: ${session.totalVolume.toStringAsFixed(0)} kg',
    );
    buffer.writeln('');

    for (final exercise in session.exercises) {
      buffer.writeln('**${exercise.exerciseName}**');
      buffer.writeln('- Series: ${exercise.completedSetsCount}');
      buffer.writeln(
        '- Volumen: ${exercise.totalVolume.toStringAsFixed(0)} kg',
      );
      if (exercise.estimatedOneRepMax != null) {
        buffer.writeln(
          '- 1RM estimado: ${exercise.estimatedOneRepMax!.toStringAsFixed(1)} kg',
        );
      }
      buffer.writeln('');
    }

    buffer.writeln('¡Buen trabajo! 💪🔥');
    return buffer.toString();
  }

  void cancelSession() {
    _durationTimer?.cancel();
    if (state != null) {
      state = state!.cancel();
    }
    state = null;
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}

// ==================== Active Workout Screen ====================

class ActiveWorkoutScreenV2 extends ConsumerStatefulWidget {
  const ActiveWorkoutScreenV2({super.key});

  @override
  ConsumerState<ActiveWorkoutScreenV2> createState() =>
      _ActiveWorkoutScreenV2State();
}

class _ActiveWorkoutScreenV2State extends ConsumerState<ActiveWorkoutScreenV2> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(activeSessionProvider);
    final sessionNotifier = ref.read(activeSessionProvider.notifier);
    final restTimer = ref.watch(restTimerProvider);
    final restTimerNotifier = ref.read(restTimerProvider.notifier);

    // If no active session, show start screen
    if (session == null) {
      return _buildStartScreen(theme, sessionNotifier);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(session.name),
            Text(session.formattedDuration, style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExerciseSheet(context, sessionNotifier),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest timer (if running)
          if (restTimer.isRunning)
            _RestTimerBar(
              state: restTimer,
              onPause: restTimerNotifier.pause,
              onResume: restTimerNotifier.resume,
              onSkip: restTimerNotifier.skip,
              onAddTime: (s) => restTimerNotifier.addTime(s),
            ),

          // Summary bar
          _SummaryBar(session: session),

          // Exercises list
          Expanded(
            child: session.exercises.isEmpty
                ? _buildEmptyState(theme, sessionNotifier)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: session.exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      // TODO: Reorder exercises
                    },
                    itemBuilder: (context, index) {
                      final exercise = session.exercises[index];
                      return _ExerciseCard(
                        key: ValueKey(exercise.id),
                        exercise: exercise,
                        exerciseIndex: index,
                        onUpdateSet: (setIndex, set) {
                          sessionNotifier.updateSet(index, setIndex, set);
                        },
                        onCompleteSet: (setIndex) {
                          sessionNotifier.completeSet(index, setIndex);
                          // Start rest timer
                          final nextExercise =
                              index < session.exercises.length - 1
                              ? session.exercises[index + 1].exerciseName
                              : '';
                          final nextSetInfo =
                              setIndex < exercise.sets.length - 1
                              ? 'Serie ${setIndex + 2}'
                              : '';
                          restTimerNotifier.start(
                            seconds: exercise.defaultRestSeconds,
                            nextExercise: nextExercise,
                            nextSetInfo: nextSetInfo,
                          );
                        },
                        onAddSet: () {
                          sessionNotifier.addSet(index);
                        },
                        onAddDropSet: () {
                          sessionNotifier.addDropSet(index);
                        },
                        onRemoveSet: (setIndex) {
                          sessionNotifier.removeSet(index, setIndex);
                        },
                        onRemoveExercise: () {
                          sessionNotifier.removeExercise(index);
                        },
                        onChangeSetType: (setIndex, type) {
                          final set = exercise.sets[setIndex].copyWith(
                            type: type,
                          );
                          sessionNotifier.updateSet(index, setIndex, set);
                        },
                      );
                    },
                  ),
          ),

          // Bottom bar
          _BottomBar(
            onAddExercise: () =>
                _showAddExerciseSheet(context, sessionNotifier),
            onFinish: () => _showFinishDialog(context, sessionNotifier),
            onCancel: () => _showCancelDialog(context, sessionNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen(ThemeData theme, ActiveSessionNotifier notifier) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Entrenamiento')),
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
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => notifier.startSession(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Entrenamiento'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
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

  Widget _buildEmptyState(ThemeData theme, ActiveSessionNotifier notifier) {
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
              'Toca + para comenzar',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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

  void _showAddExerciseSheet(
    BuildContext context,
    ActiveSessionNotifier notifier,
  ) {
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
                'Agregar ejercicio',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                      ExerciseLibrary.getEquipmentName(exercise['equipment']),
                    ),
                    onTap: () {
                      notifier.addExercise(
                        exercise['id'],
                        exercise['name'],
                        exercise['category'],
                      );
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

  void _showFinishDialog(BuildContext context, ActiveSessionNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Entrenamiento'),
        content: const Text('¿Listo? La IA evaluará tu rendimiento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Seguir'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // Get AI evaluation
              final evaluation = await notifier.finishAndGetEvaluation();

              if (context.mounted) {
                Navigator.pop(context); // Close loading
                _showEvaluationDialog(context, evaluation);
              }
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _showEvaluationDialog(BuildContext context, String evaluation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('Evaluación IA'),
          ],
        ),
        content: SingleChildScrollView(child: Text(evaluation)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to exercises
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ActiveSessionNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Entrenamiento'),
        content: const Text('¿Estás seguro? Se perderá todo el progreso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () {
              notifier.cancelSession();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

// ==================== Widgets ====================

class _SummaryBar extends StatelessWidget {
  final WorkoutSession session;

  const _SummaryBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(value: '${session.totalExercises}', label: 'Ejercicios'),
          _SummaryItem(value: '${session.totalCompletedSets}', label: 'Series'),
          _SummaryItem(
            value: '${(session.totalVolume / 1000).toStringAsFixed(1)}k',
            label: 'Volumen (kg)',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  final RestTimerState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkip;
  final Function(int) onAddTime;

  const _RestTimerBar({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onSkip,
    required this.onAddTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = state.remainingSeconds / state.totalSeconds;
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;

    Color timerColor;
    if (state.remainingSeconds > 30) {
      timerColor = Colors.green;
    } else if (state.remainingSeconds > 10) {
      timerColor = Colors.orange;
    } else {
      timerColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      color: timerColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          // Timer ring
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 4,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(timerColor),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Next info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.nextExercise.isNotEmpty)
                  Text(
                    'Siguiente: ${state.nextExercise}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (state.nextSetInfo.isNotEmpty)
                  Text(state.nextSetInfo, style: theme.textTheme.bodySmall),
              ],
            ),
          ),

          // Controls
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: () => onAddTime(-15),
          ),
          IconButton(
            icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: state.isRunning ? onPause : onResume,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => onAddTime(15),
          ),
          IconButton(icon: const Icon(Icons.skip_next), onPressed: onSkip),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final Function(int, WorkoutSet) onUpdateSet;
  final Function(int) onCompleteSet;
  final VoidCallback onAddSet;
  final VoidCallback onAddDropSet;
  final Function(int) onRemoveSet;
  final VoidCallback onRemoveExercise;
  final Function(int, SetType) onChangeSetType;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.onUpdateSet,
    required this.onCompleteSet,
    required this.onAddSet,
    required this.onAddDropSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onChangeSetType,
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
                const SizedBox(
                  width: 25,
                  child: Text('#', textAlign: TextAlign.center),
                ),
                const SizedBox(width: 40),
                const Expanded(
                  child: Text('Peso (kg)', textAlign: TextAlign.center),
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
                onChangeType: (type) => onChangeSetType(index, type),
              );
            }),

            const SizedBox(height: 8),

            // Add set buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Serie'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: onAddDropSet,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: const Text('Drop Set'),
                ),
              ],
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
  final Function(SetType) onChangeType;

  const _SetRow({
    required this.set,
    required this.onUpdate,
    required this.onComplete,
    this.onRemove,
    required this.onChangeType,
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
          // Set number with type indicator
          SizedBox(
            width: 25,
            child: GestureDetector(
              onTap: () => _showTypeSelector(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.set.type.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.set.type.abbreviation.isNotEmpty
                      ? '${widget.set.setNumber}${widget.set.type.abbreviation}'
                      : '${widget.set.setNumber}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: widget.set.type.color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Remove button
          if (widget.onRemove != null)
            SizedBox(
              width: 32,
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: widget.onRemove,
                color: theme.colorScheme.error,
                padding: EdgeInsets.zero,
              ),
            )
          else
            const SizedBox(width: 32),

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
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: '0',
                  border: OutlineInputBorder(),
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
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintText: '0',
                  border: OutlineInputBorder(),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: widget.set.rpe != null
                      ? RPEScale.getColor(
                          widget.set.rpe!,
                        ).withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
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
            width: 44,
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

  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tipo de serie',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...SetType.values.map((type) {
              return ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: type.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(type.label),
                trailing: widget.set.type == type
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  widget.onChangeType(type);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showRPEPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback onAddExercise;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const _BottomBar({
    required this.onAddExercise,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Ejercicio'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.check),
              label: const Text('Finalizar'),
            ),
          ),
        ],
      ),
    );
  }
}
