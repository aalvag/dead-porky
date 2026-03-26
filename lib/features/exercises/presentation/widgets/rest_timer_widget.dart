import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/exercises/data/exercise_library.dart';

/// Rest timer state
class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final int currentSet;
  final int totalSets;
  final String nextExercise;
  final String nextReps;

  const RestTimerState({
    required this.totalSeconds,
    required this.remainingSeconds,
    this.isRunning = false,
    this.isPaused = false,
    this.currentSet = 0,
    this.totalSets = 0,
    this.nextExercise = '',
    this.nextReps = '',
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isPaused,
    int? currentSet,
    int? totalSets,
    String? nextExercise,
    String? nextReps,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      currentSet: currentSet ?? this.currentSet,
      totalSets: totalSets ?? this.totalSets,
      nextExercise: nextExercise ?? this.nextExercise,
      nextReps: nextReps ?? this.nextReps,
    );
  }
}

/// Rest timer notifier
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerState get initialState =>
      const RestTimerState(totalSeconds: 90, remainingSeconds: 90);

  RestTimerNotifier()
    : super(const RestTimerState(totalSeconds: 90, remainingSeconds: 90));

  void startTimer({
    int seconds = 90,
    int currentSet = 0,
    int totalSets = 0,
    String nextExercise = '',
    String nextReps = '',
  }) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
      isPaused: false,
      currentSet: currentSet,
      totalSets: totalSets,
      nextExercise: nextExercise,
      nextReps: nextReps,
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

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resumeTimer() {
    if (state.isPaused) {
      startTimer(
        seconds: state.remainingSeconds,
        currentSet: state.currentSet,
        totalSets: state.totalSets,
        nextExercise: state.nextExercise,
        nextReps: state.nextReps,
      );
    }
  }

  void skipTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  void addTime(int seconds) {
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + seconds,
      totalSeconds: state.totalSeconds + seconds,
    );
  }

  void reset() {
    _timer?.cancel();
    state = const RestTimerState(totalSeconds: 90, remainingSeconds: 90);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Rest timer provider
final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
      return RestTimerNotifier();
    });

/// Rest timer widget
class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timerState = ref.watch(restTimerProvider);
    final timer = ref.read(restTimerProvider.notifier);

    if (!timerState.isRunning && timerState.remainingSeconds == 0) {
      return const SizedBox.shrink();
    }

    final progress = timerState.isRunning
        ? timerState.remainingSeconds / timerState.totalSeconds
        : 0.0;

    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;

    Color timerColor;
    if (timerState.remainingSeconds > 30) {
      timerColor = Colors.green;
    } else if (timerState.remainingSeconds > 10) {
      timerColor = Colors.orange;
    } else {
      timerColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.timer, color: timerColor),
              const SizedBox(width: 8),
              Text(
                'DESCANSO',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (timerState.nextExercise.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Siguiente: ${timerState.nextExercise}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Timer ring
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                // Progress ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation(timerColor),
                  ),
                ),
                // Time
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (timerState.nextReps.isNotEmpty)
                      Text(
                        'Próxima: ${timerState.nextReps}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Set info
          if (timerState.totalSets > 0)
            Text(
              'Serie ${timerState.currentSet}/${timerState.totalSets}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // -15s
              _ControlButton(
                icon: Icons.remove,
                label: '15s',
                onTap: () => timer.addTime(-15),
              ),
              // Play/Pause
              _ControlButton(
                icon: timerState.isPaused || !timerState.isRunning
                    ? Icons.play_arrow
                    : Icons.pause,
                isPrimary: true,
                onTap: () {
                  if (timerState.isPaused) {
                    timer.resumeTimer();
                  } else if (timerState.isRunning) {
                    timer.pauseTimer();
                  }
                },
              ),
              // +15s
              _ControlButton(
                icon: Icons.add,
                label: '15s',
                onTap: () => timer.addTime(15),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Skip button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => timer.skipTimer(),
              icon: const Icon(Icons.skip_next),
              label: const Text('Saltar descanso'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isPrimary) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: Icon(icon, size: 32),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label ?? ''),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
