import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// ==================== Tables ====================

/// Workouts table
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get templateId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  RealColumn get totalVolume => real().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Workout sets (individual sets within a workout)
class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real().withDefault(const Constant(0))();
  TextColumn get tempo => text().nullable()();
  IntColumn get rpe => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Habits table
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get type => text()(); // boolean, quantity, duration, timer
  RealColumn get targetValue => real().nullable()();
  TextColumn get targetUnit => text().nullable()();
  TextColumn get frequency => text()(); // daily, weekly, weekdays, custom
  TextColumn get customDays => text().nullable()(); // JSON array [1,3,5]
  TextColumn get reminderTime => text().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get category => text()();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Habit logs (daily entries)
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  RealColumn get value => real().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Health metrics table
class HealthMetrics extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // weight, heart_rate, blood_pressure, etc.
  RealColumn get value => real()();
  RealColumn get valueSecondary => real().nullable()(); // for BP diastolic
  TextColumn get unit => text()();
  TextColumn get source => text()(); // manual, ble, health_api
  TextColumn get deviceId => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get measuredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Nutrition entries table
class NutritionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack
  IntColumn get calories => integer().withDefault(const Constant(0))();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();
  RealColumn get fiber => real().withDefault(const Constant(0))();
  TextColumn get imageUrl => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get consumedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue for offline operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // create, update, delete
  TextColumn get entityType => text()(); // workout, habit, metric, etc.
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ==================== Database ====================

@DriftDatabase(
  tables: [
    Workouts,
    WorkoutSets,
    Habits,
    HabitLogs,
    HealthMetrics,
    NutritionEntries,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle future migrations
    },
  );

  // ==================== Workouts ====================

  Future<List<Workout>> getAllWorkouts() => (select(
    workouts,
  )..orderBy([(t) => OrderingTerm.desc(t.startedAt)])).get();

  Future<Workout?> getWorkout(String id) =>
      (select(workouts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertWorkout(WorkoutsCompanion workout) =>
      into(workouts).insert(workout);

  Future<void> updateWorkout(WorkoutsCompanion workout) => (update(
    workouts,
  )..where((t) => t.id.equals(workout.id.value))).write(workout);

  Future<void> deleteWorkout(String id) =>
      (delete(workouts)..where((t) => t.id.equals(id))).go();

  // ==================== Workout Sets ====================

  Future<List<WorkoutSet>> getSetsForWorkout(String workoutId) =>
      (select(workoutSets)
            ..where((t) => t.workoutId.equals(workoutId))
            ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
          .get();

  Future<void> insertWorkoutSet(WorkoutSetsCompanion set) =>
      into(workoutSets).insert(set);

  // ==================== Habits ====================

  Future<List<Habit>> getAllHabits() =>
      (select(habits)..where((t) => t.archived.equals(false))).get();

  Future<Habit?> getHabit(String id) =>
      (select(habits)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertHabit(HabitsCompanion habit) => into(habits).insert(habit);

  Future<void> updateHabit(HabitsCompanion habit) =>
      (update(habits)..where((t) => t.id.equals(habit.id.value))).write(habit);

  // ==================== Habit Logs ====================

  Future<List<HabitLog>> getLogsForHabit(
    String habitId, {
    DateTime? from,
    DateTime? to,
  }) =>
      (select(habitLogs)
            ..where((t) => t.habitId.equals(habitId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<HabitLog?> getLogForDate(String habitId, DateTime date) =>
      (select(habitLogs)
            ..where((t) => t.habitId.equals(habitId) & t.date.equals(date)))
          .getSingleOrNull();

  Future<void> insertHabitLog(HabitLogsCompanion log) => into(habitLogs).insert(
    log,
    onConflict: DoUpdate(
      (old) => log,
      target: [habitLogs.habitId, habitLogs.date],
    ),
  );

  // ==================== Health Metrics ====================

  Future<List<HealthMetric>> getMetrics(
    String type, {
    DateTime? from,
    DateTime? to,
  }) =>
      (select(healthMetrics)
            ..where((t) => t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
          .get();

  Future<void> insertMetric(HealthMetricsCompanion metric) =>
      into(healthMetrics).insert(metric);

  // ==================== Nutrition ====================

  Future<List<NutritionEntry>> getEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(nutritionEntries)
          ..where(
            (t) =>
                t.consumedAt.isBiggerOrEqualValue(startOfDay) &
                t.consumedAt.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.consumedAt)]))
        .get();
  }

  Future<void> insertNutritionEntry(NutritionEntriesCompanion entry) =>
      into(nutritionEntries).insert(entry);

  // ==================== Sync Queue ====================

  Future<void> addToSyncQueue(SyncQueueCompanion item) =>
      into(syncQueue).insert(item);

  Future<List<SyncQueueData>> getPendingSync() =>
      (select(syncQueue)
            ..where((t) => t.processed.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> markSynced(int id) =>
      (update(syncQueue)..where((t) => t.id.equals(id))).write(
        const SyncQueueCompanion(processed: Value(true)),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'dead_porky.db'));
    return NativeDatabase.createInBackground(file);
  });
}
