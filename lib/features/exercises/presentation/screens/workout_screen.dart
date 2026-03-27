import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dead_porky/features/exercises/domain/entities/routine.dart';
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_real.dart';

// ==================== Workout State ====================

class WorkoutState {
  final Routine? routine;
  final DateTime startedAt;
  final List<WorkoutExerciseState> exercises;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final bool isActive;
  final bool isCompleted;

  const WorkoutState({
    this.routine,
    required this.startedAt,
    this.exercises = const [],
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.isActive = true,
    this.isCompleted = false,
  });

  WorkoutState copyWith({
    List<WorkoutExerciseState>? exercises,
    int? currentExerciseIndex,
    int? currentSetIndex,
    bool? isActive,
    bool? isCompleted,
  }) {
    return WorkoutState(
      routine: routine,
      startedAt: startedAt,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Duration get elapsed => DateTime.now().difference(startedAt);

  String get formattedElapsed {
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    final s = elapsed.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  int get totalCompletedSets {
    return exercises.fold(0, (sum, e) => sum + e.completedSets);
  }

  double get totalVolume {
    return exercises.fold(0, (sum, e) => sum + e.totalVolume);
  }
}

class WorkoutExerciseState {
  final String exerciseId;
  final String exerciseName;
  final String category;
  final List<WorkoutSetState> sets;
  final int restSeconds;

  const WorkoutExerciseState({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.sets,
    this.restSeconds = 90,
  });

  WorkoutExerciseState copyWith({List<WorkoutSetState>? sets}) {
    return WorkoutExerciseState(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      category: category,
      sets: sets ?? this.sets,
      restSeconds: restSeconds,
    );
  }

  int get completedSets => sets.where((s) => s.completed).length;

  double get totalVolume {
    return sets
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + (s.weight * s.reps));
  }
}

class WorkoutSetState {
  final int setNumber;
  final int targetReps;
  final int reps;
  final double weight;
  final SetType type;
  final int? rpe;
  final bool completed;
  final DateTime? completedAt;

  const WorkoutSetState({
    required this.setNumber,
    required this.targetReps,
    this.reps = 0,
    this.weight = 0,
    this.type = SetType.normal,
    this.rpe,
    this.completed = false,
    this.completedAt,
  });

  WorkoutSetState copyWith({
    int? reps,
    double? weight,
    int? rpe,
    bool? completed,
    DateTime? completedAt,
  }) {
    return WorkoutSetState(
      setNumber: setNumber,
      targetReps: targetReps,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      type: type,
      rpe: rpe ?? this.rpe,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// ==================== Workout Notifier ====================

class WorkoutNotifier extends StateNotifier<WorkoutState?> {
  Timer? _timer;

  WorkoutNotifier() : super(null);

  void startFromRoutine(Routine routine) {
    final exercises = routine.exercises.map((e) {
      return WorkoutExerciseState(
        exerciseId: e.exerciseId,
        exerciseName: e.exerciseName,
        category: e.category,
        restSeconds: e.restSeconds,
        sets: e.sets
            .map(
              (s) => WorkoutSetState(
                setNumber: s.setNumber,
                targetReps: s.targetReps,
                type: s.type,
              ),
            )
            .toList(),
      );
    }).toList();

    state = WorkoutState(
      routine: routine,
      startedAt: DateTime.now(),
      exercises: exercises,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state != null && state!.isActive) {
        state = state!.copyWith(); // Triggers rebuild for elapsed time
      }
    });
  }

  void completeSet(
    int exerciseIndex,
    int setIndex,
    int reps,
    double weight, {
    int? rpe,
  }) {
    if (state == null) return;

    final exercises = List<WorkoutExerciseState>.from(state!.exercises);
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;

    final exercise = exercises[exerciseIndex];
    final sets = List<WorkoutSetState>.from(exercise.sets);
    if (setIndex < 0 || setIndex >= sets.length) return;

    sets[setIndex] = sets[setIndex].copyWith(
      reps: reps,
      weight: weight,
      rpe: rpe,
      completed: true,
      completedAt: DateTime.now(),
    );

    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);

    HapticFeedback.mediumImpact();
  }

  void uncompleteSet(int exerciseIndex, int setIndex) {
    if (state == null) return;

    final exercises = List<WorkoutExerciseState>.from(state!.exercises);
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;

    final exercise = exercises[exerciseIndex];
    final sets = List<WorkoutSetState>.from(exercise.sets);
    if (setIndex < 0 || setIndex >= sets.length) return;

    sets[setIndex] = sets[setIndex].copyWith(completed: false);
    exercises[exerciseIndex] = exercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
  }

  Future<String> finishAndGetEvaluation() async {
    if (state == null) return '';

    _timer?.cancel();
    state = state!.copyWith(isActive: false, isCompleted: true);

    // Generate AI evaluation
    final buffer = StringBuffer();
    buffer.writeln('📊 **Resumen del Entrenamiento**\n');
    buffer.writeln('⏱️ Duración: ${state!.formattedElapsed}');
    buffer.writeln('🏋️ Ejercicios: ${state!.exercises.length}');
    buffer.writeln('💪 Series completadas: ${state!.totalCompletedSets}');
    buffer.writeln('📦 Volumen: ${state!.totalVolume.toStringAsFixed(0)} kg\n');

    for (final exercise in state!.exercises) {
      buffer.writeln('**${exercise.exerciseName}**');
      buffer.writeln(
        '- ${exercise.completedSets}/${exercise.sets.length} series',
      );
      buffer.writeln(
        '- Volumen: ${exercise.totalVolume.toStringAsFixed(0)} kg\n',
      );
    }

    // Try real AI evaluation
    try {
      final gateway = KiloGatewayReal();
      final evaluation = await gateway.chat(
        messages: [
          {
            'role': 'system',
            'content':
                'Eres un entrenador experto. Evalúa este entrenamiento y da recomendaciones. Responde en español con emojis.',
          },
          {'role': 'user', 'content': buffer.toString()},
        ],
        maxTokens: 800,
      );
      return evaluation;
    } catch (e) {
      return '${buffer.toString()}\n\n¡Buen trabajo! 💪🔥';
    }
  }

  void cancel() {
    _timer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ==================== Rest Timer Notifier ====================

class WorkoutRestTimerNotifier extends StateNotifier<WorkoutRestTimerState> {
  Timer? _timer;

  WorkoutRestTimerNotifier() : super(const WorkoutRestTimerState());

  void start({int seconds = 90, String exerciseName = ''}) {
    _timer?.cancel();
    state = WorkoutRestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      exerciseName: exerciseName,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 0) {
        timer.cancel();
        state = state.copyWith(isRunning: false, isFinished: true);
        HapticFeedback.heavyImpact();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  void skip() {
    _timer?.cancel();
    state = const WorkoutRestTimerState();
  }

  void addTime(int seconds) {
    state = state.copyWith(
      remainingSeconds: (state.remainingSeconds + seconds).clamp(0, 999),
      totalSeconds: (state.totalSeconds + seconds).clamp(0, 999),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class WorkoutRestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isFinished;
  final String exerciseName;

  const WorkoutRestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 90,
    this.isRunning = false,
    this.isFinished = false,
    this.exerciseName = '',
  });

  WorkoutRestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isFinished,
    String? exerciseName,
  }) {
    return WorkoutRestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
      exerciseName: exerciseName ?? this.exerciseName,
    );
  }
}

// ==================== Providers ====================

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState?>((
  ref,
) {
  return WorkoutNotifier();
});

final workoutRestTimerProvider =
    StateNotifierProvider<WorkoutRestTimerNotifier, WorkoutRestTimerState>((
      ref,
    ) {
      return WorkoutRestTimerNotifier();
    });

// ==================== Workout Screen ====================

class WorkoutScreen extends ConsumerStatefulWidget {
  final Routine? routine;

  const WorkoutScreen({super.key, this.routine});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Start workout from routine if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.routine != null) {
        ref.read(workoutProvider.notifier).startFromRoutine(widget.routine!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = ref.watch(workoutProvider);
    final workoutNotifier = ref.read(workoutProvider.notifier);
    final restTimer = ref.watch(workoutRestTimerProvider);
    final restTimerNotifier = ref.read(workoutRestTimerProvider.notifier);

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Entrenamiento')),
        body: const Center(child: Text('No hay entrenamiento activo')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(workout.routine?.name ?? 'Entrenamiento'),
            Text(workout.formattedElapsed, style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => _showFinishDialog(context, workoutNotifier),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top bar with total time and stats
          _TopStatsBar(workout: workout),

          // Rest timer (if running)
          if (restTimer.isRunning || restTimer.isFinished)
            _RestTimerBanner(
              state: restTimer,
              onSkip: restTimerNotifier.skip,
              onAddTime: (s) => restTimerNotifier.addTime(s),
            ),

          // Exercises list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workout.exercises.length,
              itemBuilder: (context, exerciseIndex) {
                final exercise = workout.exercises[exerciseIndex];
                return _ExerciseCard(
                  exercise: exercise,
                  exerciseIndex: exerciseIndex,
                  onCompleteSet: (setIndex, reps, weight, rpe) {
                    workoutNotifier.completeSet(
                      exerciseIndex,
                      setIndex,
                      reps,
                      weight,
                      rpe: rpe,
                    );
                    // Start rest timer
                    final nextExercise =
                        exerciseIndex < workout.exercises.length - 1
                        ? workout.exercises[exerciseIndex + 1].exerciseName
                        : '';
                    restTimerNotifier.start(
                      seconds: exercise.restSeconds,
                      exerciseName: nextExercise,
                    );
                  },
                  onUncompleteSet: (setIndex) {
                    workoutNotifier.uncompleteSet(exerciseIndex, setIndex);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context, WorkoutNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Entrenamiento'),
        content: const Text('¿Listo? La IA evaluará tu rendimiento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

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
              Navigator.pop(context); // Go back
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ==================== Widgets ====================

class _TopStatsBar extends StatelessWidget {
  final WorkoutState workout;

  const _TopStatsBar({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.timer,
            value: workout.formattedElapsed,
            label: 'Tiempo',
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outlineVariant,
          ),
          _StatItem(
            icon: Icons.check_circle,
            value: '${workout.totalCompletedSets}',
            label: 'Series',
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outlineVariant,
          ),
          _StatItem(
            icon: Icons.monitor_weight,
            value: '${(workout.totalVolume / 1000).toStringAsFixed(1)}k',
            label: 'Volumen',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _RestTimerBanner extends StatelessWidget {
  final WorkoutRestTimerState state;
  final VoidCallback onSkip;
  final Function(int) onAddTime;

  const _RestTimerBanner({
    required this.state,
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
      timerColor = const Color(0xFF10B981);
    } else if (state.remainingSeconds > 10) {
      timerColor = const Color(0xFFF59E0B);
    } else {
      timerColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            timerColor.withValues(alpha: 0.15),
            timerColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: timerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Timer circle
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation(timerColor),
                ),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: timerColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descanso',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                  ),
                ),
                if (state.exerciseName.isNotEmpty)
                  Text(
                    'Siguiente: ${state.exerciseName}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (state.isFinished)
                  Text(
                    '¡Tiempo! Continúa con la siguiente serie',
                    style: TextStyle(
                      color: timerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Controls
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onAddTime(-15),
          ),
          IconButton.filled(
            icon: const Icon(Icons.skip_next),
            onPressed: onSkip,
            style: IconButton.styleFrom(backgroundColor: timerColor),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onAddTime(15),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExerciseState exercise;
  final int exerciseIndex;
  final Function(int setIndex, int reps, double weight, int? rpe) onCompleteSet;
  final Function(int setIndex) onUncompleteSet;

  const _ExerciseCard({
    required this.exercise,
    required this.exerciseIndex,
    required this.onCompleteSet,
    required this.onUncompleteSet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${exerciseIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${exercise.completedSets}/${exercise.sets.length} series · ${exercise.restSeconds}s descanso',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Progress indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: exercise.sets.isEmpty
                        ? 0
                        : exercise.completedSets / exercise.sets.length,
                    strokeWidth: 4,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          // Sets header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'OBJ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'RPE',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
          ),
          const Divider(height: 1),

          // Sets
          ...exercise.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = entry.value;
            return _SetRow(
              set: set,
              restSeconds: exercise.restSeconds,
              onComplete: (reps, weight, rpe) =>
                  onCompleteSet(setIndex, reps, weight, rpe),
              onUncomplete: () => onUncompleteSet(setIndex),
            );
          }),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final WorkoutSetState set;
  final int restSeconds;
  final Function(int reps, double weight, int? rpe) onComplete;
  final VoidCallback onUncomplete;

  const _SetRow({
    required this.set,
    required this.restSeconds,
    required this.onComplete,
    required this.onUncomplete,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.set.completed
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : null,
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 30,
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
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.set.type.color,
                ),
              ),
            ),
          ),

          // Target reps
          Expanded(
            child: Text(
              '${widget.set.targetReps}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),

          // Weight input
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
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          // Reps input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                      ? _getRPEColor(widget.set.rpe!).withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.set.rpe?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: widget.set.rpe != null
                        ? _getRPEColor(widget.set.rpe!)
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
                    icon: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                    onPressed: widget.onUncomplete,
                  )
                : IconButton(
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.outline,
                      size: 28,
                    ),
                    onPressed: () {
                      final reps = int.tryParse(_repsController.text) ?? 0;
                      final weight =
                          double.tryParse(_weightController.text) ?? 0;
                      widget.onComplete(reps, weight, widget.set.rpe);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 5) return const Color(0xFF10B981);
    if (rpe <= 7) return const Color(0xFFF59E0B);
    if (rpe <= 8) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
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
              'RPE - Esfuerzo Percibido',
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
                return ChoiceChip(
                  label: Text('$rpe'),
                  selected: widget.set.rpe == rpe,
                  onSelected: (selected) {
                    setState(() {
                      // Update RPE
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
