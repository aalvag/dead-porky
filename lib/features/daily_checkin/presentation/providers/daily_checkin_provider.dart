import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:dead_porky/database/app_database.dart';

final selectedCheckinDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final dailyCheckinProvider =
    StateNotifierProvider<DailyCheckinNotifier, DailyCheckinState>((ref) {
      return DailyCheckinNotifier(ref);
    });

class DailyCheckinState {
  final DateTime date;
  final int waterMl;
  final double sleepHours;
  final int mood;
  final int energyLevel;
  final bool workoutCompleted;
  final bool foodLogged;
  final String notes;
  final bool isLoading;
  final bool isSaving;
  final bool hasSavedEntry;

  const DailyCheckinState({
    required this.date,
    this.waterMl = 0,
    this.sleepHours = 0,
    this.mood = 0,
    this.energyLevel = 0,
    this.workoutCompleted = false,
    this.foodLogged = false,
    this.notes = '',
    this.isLoading = false,
    this.isSaving = false,
    this.hasSavedEntry = false,
  });

  DailyCheckinState copyWith({
    DateTime? date,
    int? waterMl,
    double? sleepHours,
    int? mood,
    int? energyLevel,
    bool? workoutCompleted,
    bool? foodLogged,
    String? notes,
    bool? isLoading,
    bool? isSaving,
    bool? hasSavedEntry,
  }) {
    return DailyCheckinState(
      date: date ?? this.date,
      waterMl: waterMl ?? this.waterMl,
      sleepHours: sleepHours ?? this.sleepHours,
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
      workoutCompleted: workoutCompleted ?? this.workoutCompleted,
      foodLogged: foodLogged ?? this.foodLogged,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasSavedEntry: hasSavedEntry ?? this.hasSavedEntry,
    );
  }
}

class DailyCheckinNotifier extends StateNotifier<DailyCheckinState> {
  final Ref _ref;

  DailyCheckinNotifier(this._ref)
    : super(DailyCheckinState(date: DateTime.now())) {
    loadForDate(state.date);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadForDate(DateTime date) async {
    state = state.copyWith(date: date, isLoading: true);
    final db = _ref.read(appDatabaseProvider);
    final entry = await db.getDailyCheckin(_dateKey(date));

    if (entry != null) {
      state = state.copyWith(
        waterMl: entry.waterMl,
        sleepHours: entry.sleepHours,
        mood: entry.mood ?? 0,
        energyLevel: entry.energyLevel ?? 0,
        workoutCompleted: entry.workoutCompleted,
        foodLogged: entry.foodLogged,
        notes: entry.notes ?? '',
        hasSavedEntry: true,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        waterMl: 0,
        sleepHours: 0,
        mood: 0,
        energyLevel: 0,
        workoutCompleted: false,
        foodLogged: false,
        notes: '',
        hasSavedEntry: false,
        isLoading: false,
      );
    }
  }

  void updateWater(int deltaMl) {
    final newValue = (state.waterMl + deltaMl).clamp(0, 5000);
    state = state.copyWith(waterMl: newValue);
  }

  void updateSleep(double hours) {
    state = state.copyWith(sleepHours: hours);
  }

  void updateMood(int value) {
    state = state.copyWith(mood: value);
  }

  void updateEnergy(int value) {
    state = state.copyWith(energyLevel: value);
  }

  void toggleWorkoutCompleted() {
    state = state.copyWith(workoutCompleted: !state.workoutCompleted);
  }

  void toggleFoodLogged() {
    state = state.copyWith(foodLogged: !state.foodLogged);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);
    final db = _ref.read(appDatabaseProvider);
    final dateKey = _dateKey(state.date);

    await db.upsertDailyCheckin(
      DailyCheckinsCompanion(
        dateKey: Value(dateKey),
        waterMl: Value(state.waterMl),
        sleepHours: Value(state.sleepHours),
        mood: Value(state.mood == 0 ? null : state.mood),
        energyLevel: Value(state.energyLevel == 0 ? null : state.energyLevel),
        workoutCompleted: Value(state.workoutCompleted),
        foodLogged: Value(state.foodLogged),
        notes: Value(state.notes.isEmpty ? null : state.notes),
        updatedAt: Value(DateTime.now()),
      ),
    );

    state = state.copyWith(isSaving: false, hasSavedEntry: true);
  }
}
