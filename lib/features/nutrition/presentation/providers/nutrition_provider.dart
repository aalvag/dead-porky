import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:dead_porky/database/app_database.dart' as database;
import 'package:dead_porky/features/ai_engine/data/datasources/kilo_gateway_service.dart';
import 'package:dead_porky/features/auth/domain/entities/user.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_recipe.dart';

final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
      return NutritionNotifier(ref);
    });

class NutritionState {
  const NutritionState({
    required this.date,
    this.entries = const [],
    this.goals = const NutritionGoal(
      calorieGoal: 2200,
      proteinGoal: 150,
      carbsGoal: 250,
      fatGoal: 70,
      fiberGoal: 28,
    ),
    this.recipes = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.isAnalyzingPhoto = false,
    this.errorMessage,
  });

  final DateTime date;
  final List<NutritionEntry> entries;
  final NutritionGoal goals;
  final List<NutritionRecipe> recipes;
  final bool isLoading;
  final bool isSaving;
  final bool isAnalyzingPhoto;
  final String? errorMessage;

  NutritionState copyWith({
    DateTime? date,
    List<NutritionEntry>? entries,
    NutritionGoal? goals,
    List<NutritionRecipe>? recipes,
    bool? isLoading,
    bool? isSaving,
    bool? isAnalyzingPhoto,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return NutritionState(
      date: date ?? this.date,
      entries: entries ?? this.entries,
      goals: goals ?? this.goals,
      recipes: recipes ?? this.recipes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isAnalyzingPhoto: isAnalyzingPhoto ?? this.isAnalyzingPhoto,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class NutritionPhotoDraft {
  const NutritionPhotoDraft({
    required this.imagePath,
    required this.mealType,
    required this.analysis,
  });

  final String imagePath;
  final MealType mealType;
  final NutritionAnalysis analysis;
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  NutritionNotifier(this._ref)
    : _kiloGateway = KiloGatewayService(),
      super(
        NutritionState(date: _normalizeDate(DateTime.now()), isLoading: true),
      ) {
    Future<void>.microtask(() => loadForDate(state.date));
  }

  static const String _goalRowId = 'default';

  final Ref _ref;
  final KiloGatewayService _kiloGateway;

  Future<void> loadForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    state = state.copyWith(
      date: normalizedDate,
      isLoading: true,
      clearErrorMessage: true,
    );

    try {
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: 'No pude cargar tus comidas ahora mismo.',
      );
    }
  }

  Future<void> shiftDate(int offsetDays) {
    return loadForDate(state.date.add(Duration(days: offsetDays)));
  }

  Future<void> addPresetFood(
    FoodPreset food, {
    required MealType mealType,
    double multiplier = 1,
  }) {
    final entry = food.toNutritionEntry(
      mealType: mealType,
      consumedAt: _entryTimestampFor(mealType),
      multiplier: multiplier,
    );

    return _persistEntry(entry);
  }

  Future<void> addManualEntry({
    required String name,
    required MealType mealType,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    String? imageUrl,
    double confidence = 1,
  }) {
    final entry = NutritionEntry.create(
      name: name.trim(),
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      imageUrl: imageUrl,
      confidence: confidence,
      consumedAt: _entryTimestampFor(mealType),
    );

    return _persistEntry(entry);
  }

  Future<void> updateEntry({
    required String entryId,
    required String name,
    required MealType mealType,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
    String? imageUrl,
    double confidence = 1,
  }) async {
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final db = _ref.read(database.appDatabaseProvider);
      final entry = NutritionEntry(
        id: entryId,
        name: name.trim(),
        mealType: mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        imageUrl: imageUrl,
        confidence: confidence,
        consumedAt: _entryTimestampFor(mealType),
      );

      await db.updateNutritionEntry(_entryCompanion(entry));
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No pude actualizar este alimento. Intentalo de nuevo.',
      );
    }
  }

  Future<void> deleteEntry(String entryId) async {
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final db = _ref.read(database.appDatabaseProvider);
      await db.deleteNutritionEntry(entryId);
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No pude borrar este alimento. Intentalo de nuevo.',
      );
    }
  }

  Future<void> saveGoals(NutritionGoal goals) async {
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final db = _ref.read(database.appDatabaseProvider);
      await db.upsertNutritionGoal(
        database.NutritionGoalsCompanion(
          id: const Value(_goalRowId),
          calorieGoal: Value(goals.calorieGoal),
          proteinGoal: Value(goals.proteinGoal),
          carbsGoal: Value(goals.carbsGoal),
          fatGoal: Value(goals.fatGoal),
          fiberGoal: Value(goals.fiberGoal),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No pude guardar tus objetivos.',
      );
    }
  }

  Future<void> saveMealAsRecipe({
    required MealType mealType,
    required String name,
    String? notes,
  }) async {
    final mealEntries = state.entries
        .where((entry) => entry.mealType == mealType)
        .toList();

    if (mealEntries.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'No hay alimentos en esta comida para guardar como receta.',
      );
      return;
    }

    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final recipe = NutritionRecipe.create(
        name: name.trim(),
        mealType: mealType,
        calories: mealEntries.fold<int>(
          0,
          (sum, entry) => sum + entry.calories,
        ),
        protein: mealEntries.fold<double>(
          0,
          (sum, entry) => sum + entry.protein,
        ),
        carbs: mealEntries.fold<double>(0, (sum, entry) => sum + entry.carbs),
        fat: mealEntries.fold<double>(0, (sum, entry) => sum + entry.fat),
        fiber: mealEntries.fold<double>(0, (sum, entry) => sum + entry.fiber),
        ingredients: mealEntries.map((entry) => entry.name).toList(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );

      final db = _ref.read(database.appDatabaseProvider);
      await db.upsertNutritionRecipe(_recipeCompanion(recipe));
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No pude guardar la receta.',
      );
    }
  }

  Future<void> addRecipeToDay(
    NutritionRecipe recipe, {
    double multiplier = 1,
    MealType? mealType,
  }) {
    final effectiveMealType = mealType ?? recipe.mealType;
    final entry = recipe.toEntry(
      consumedAt: _entryTimestampFor(effectiveMealType),
      mealType: effectiveMealType,
      multiplier: multiplier,
    );

    return _persistEntry(entry);
  }

  Future<void> deleteRecipe(String recipeId) async {
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final db = _ref.read(database.appDatabaseProvider);
      await db.deleteNutritionRecipe(recipeId);
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'No pude borrar la receta.',
      );
    }
  }

  Future<NutritionPhotoDraft?> analyzeMealPhoto({
    required XFile photo,
    required MealType mealType,
    String? mealContext,
  }) async {
    print('[NUTRITION] analyzeMealPhoto START — photo: ${photo.path}, mealType: $mealType');
    state = state.copyWith(isAnalyzingPhoto: true, clearErrorMessage: true);

    try {
      final bytes = await photo.readAsBytes();
      final mimeType = photo.mimeType ?? _mimeTypeFromPath(photo.path);
      final analysis = await _kiloGateway.analyzeMealPhoto(
        imageBytes: bytes,
        mimeType: mimeType,
        mealContext: mealContext,
        userProfile: _userProfilePayload(),
      );

      state = state.copyWith(isAnalyzingPhoto: false, clearErrorMessage: true);
      return NutritionPhotoDraft(
        imagePath: photo.path,
        mealType: mealType,
        analysis: analysis,
      );
    } catch (error, stackTrace) {
      print('[NUTRITION] analyzeMealPhoto FAILED');
      print('[NUTRITION]   error type: ${error.runtimeType}');
      print('[NUTRITION]   error message: $error');
      print('[NUTRITION]   stackTrace: $stackTrace');
      state = state.copyWith(
        isAnalyzingPhoto: false,
        errorMessage: _photoAnalysisErrorMessage(error),
      );
      return null;
    }
  }

  String _photoAnalysisErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('GEMINI_API_KEY')) {
      return 'Falta configurar GEMINI_API_KEY en .env.';
    }
    if (message.contains('Formato de imagen no compatible') ||
        message.contains('mime_type') ||
        message.contains('Gemini 400')) {
      return 'La foto no se pudo procesar. Prueba con una imagen JPG o PNG.';
    }
    if (message.contains('Gemini 401') || message.contains('Gemini 403')) {
      return 'La clave de Gemini no es válida o no tiene permisos.';
    }
    if (message.contains('Gemini 429')) {
      return 'Gemini no tiene cuota disponible o está saturado.';
    }
    if (message.contains('timeout') || message.contains('timed out')) {
      return 'Gemini tardó demasiado en responder.';
    }
    if (message.contains('Network is unreachable') ||
        message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('DioException')) {
      return 'Sin conexión a Internet. Verifica tu red y vuelve a intentar.';
    }

    return 'No pude analizar la foto: ${error.runtimeType}: $message';
  }

  String _mimeTypeFromPath(String filePath) {
    switch (path.extension(filePath).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _persistEntry(NutritionEntry entry) async {
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final db = _ref.read(database.appDatabaseProvider);
      await db.insertNutritionEntry(_entryCompanion(entry));
      await _refreshAll();
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage:
            'No pude guardar este alimento. Revisa los datos y vuelve a intentar.',
      );
    }
  }

  Future<void> _refreshAll() async {
    final db = _ref.read(database.appDatabaseProvider);
    final rows = await db.getEntriesForDate(state.date);
    final goals = await _loadGoals(db);
    final recipeRows = await db.getAllNutritionRecipes();

    final entries = rows.map(_mapEntry).toList();
    final recipes = recipeRows.map(_mapRecipe).toList();

    await db.upsertDailyCheckin(
      database.DailyCheckinsCompanion(
        dateKey: Value(_dateKey(state.date)),
        foodLogged: Value(entries.isNotEmpty),
        updatedAt: Value(DateTime.now()),
      ),
    );

    state = state.copyWith(
      entries: entries,
      goals: goals,
      recipes: recipes,
      isLoading: false,
      isSaving: false,
      clearErrorMessage: true,
    );
  }

  Future<NutritionGoal> _loadGoals(database.AppDatabase db) async {
    final row = await db.getNutritionGoal(_goalRowId);
    if (row != null) {
      return _mapGoal(row);
    }

    final suggested = NutritionGoal.suggested(_ref.read(currentUserProvider));
    await db.upsertNutritionGoal(
      database.NutritionGoalsCompanion(
        id: const Value(_goalRowId),
        calorieGoal: Value(suggested.calorieGoal),
        proteinGoal: Value(suggested.proteinGoal),
        carbsGoal: Value(suggested.carbsGoal),
        fatGoal: Value(suggested.fatGoal),
        fiberGoal: Value(suggested.fiberGoal),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return suggested;
  }

  Map<String, dynamic>? _userProfilePayload() {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      return null;
    }

    return {
      'displayName': user.displayName,
      'weight': user.profile.weight,
      'height': user.profile.height,
      'age': user.profile.age,
      'activityLevel': user.profile.activityLevel.label,
      'fitnessGoal': user.profile.fitnessGoal.label,
      'allergies': user.profile.allergies,
      'calorieGoal': state.goals.calorieGoal,
      'proteinGoal': state.goals.proteinGoal,
      'carbsGoal': state.goals.carbsGoal,
      'fatGoal': state.goals.fatGoal,
      'fiberGoal': state.goals.fiberGoal,
    };
  }

  database.NutritionEntriesCompanion _entryCompanion(NutritionEntry entry) {
    return database.NutritionEntriesCompanion(
      id: Value(entry.id),
      name: Value(entry.name),
      mealType: Value(entry.mealType.name),
      calories: Value(entry.calories),
      protein: Value(entry.protein),
      carbs: Value(entry.carbs),
      fat: Value(entry.fat),
      fiber: Value(entry.fiber),
      imageUrl: Value(entry.imageUrl),
      confidence: Value(entry.confidence),
      consumedAt: Value(entry.consumedAt),
    );
  }

  database.NutritionRecipesCompanion _recipeCompanion(NutritionRecipe recipe) {
    return database.NutritionRecipesCompanion(
      id: Value(recipe.id),
      name: Value(recipe.name),
      mealType: Value(recipe.mealType.name),
      calories: Value(recipe.calories),
      protein: Value(recipe.protein),
      carbs: Value(recipe.carbs),
      fat: Value(recipe.fat),
      fiber: Value(recipe.fiber),
      ingredientsJson: Value(jsonEncode(recipe.ingredients)),
      notes: Value(recipe.notes),
      createdAt: Value(recipe.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  NutritionEntry _mapEntry(database.NutritionEntry row) {
    return NutritionEntry(
      id: row.id,
      name: row.name,
      mealType: MealType.values.firstWhere(
        (value) => value.name == row.mealType,
        orElse: () => MealType.snack,
      ),
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      fiber: row.fiber,
      imageUrl: row.imageUrl,
      confidence: row.confidence,
      consumedAt: row.consumedAt,
    );
  }

  NutritionGoal _mapGoal(database.NutritionGoal row) {
    return NutritionGoal(
      calorieGoal: row.calorieGoal,
      proteinGoal: row.proteinGoal,
      carbsGoal: row.carbsGoal,
      fatGoal: row.fatGoal,
      fiberGoal: row.fiberGoal,
    );
  }

  NutritionRecipe _mapRecipe(database.NutritionRecipe row) {
    final rawIngredients = jsonDecode(row.ingredientsJson);
    final ingredients = rawIngredients is List
        ? rawIngredients.map((item) => item.toString()).toList()
        : <String>[];

    return NutritionRecipe(
      id: row.id,
      name: row.name,
      mealType: MealType.values.firstWhere(
        (value) => value.name == row.mealType,
        orElse: () => MealType.snack,
      ),
      calories: row.calories,
      protein: row.protein,
      carbs: row.carbs,
      fat: row.fat,
      fiber: row.fiber,
      ingredients: ingredients,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  DateTime _entryTimestampFor(MealType mealType) {
    final now = DateTime.now();
    if (_isSameDate(state.date, now)) {
      return now;
    }

    return DateTime(
      state.date.year,
      state.date.month,
      state.date.day,
      mealType.defaultHour,
    );
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
