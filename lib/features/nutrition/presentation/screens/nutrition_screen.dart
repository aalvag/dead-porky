import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_recipe.dart';
import 'package:dead_porky/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:dead_porky/features/nutrition/presentation/widgets/ai_analysis_review_sheet.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  static bool _didAttemptLostPhotoRecovery = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_didAttemptLostPhotoRecovery) {
      _didAttemptLostPhotoRecovery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recoverLostPhotoIfAny(context, ref);
      });
    }

    ref.listen<NutritionState>(nutritionProvider, (previous, next) {
      final errorMessage = next.errorMessage;
      if (errorMessage == null || errorMessage == previous?.errorMessage) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    });

    final state = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final summary = _NutritionSummary.fromState(state);
    final coach = _NutritionCoach.fromSummary(summary);

    final theme = Theme.of(context);

    if (state.isLoading && state.entries.isEmpty && state.recipes.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF97316).withValues(alpha: 0.08),
                theme.colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => notifier.loadForDate(state.date),
            child: CustomScrollView(
              slivers: [
                // ====== PREMIUM SLIVER APP BAR ======
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.colorScheme.surface,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF97316).withValues(alpha: 0.18),
                            const Color(0xFFFACC15).withValues(alpha: 0.06),
                            theme.colorScheme.surface,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Nutrición IA',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      coach.headline,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              _RingScore(
                                progress: summary.calorieProgress,
                                value: summary.consumedCalories,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, size: 22),
                      onPressed: state.isAnalyzingPhoto
                          ? null
                          : () => _showPhotoSourceSheet(context, ref),
                      tooltip: 'Analizar foto',
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 22),
                      onPressed: () => _showGoalsSheet(context, ref, state.goals),
                      tooltip: 'Objetivos',
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, size: 22),
                      onPressed: state.entries.isEmpty
                          ? null
                          : () => _showCoachSheet(context, summary, coach),
                      tooltip: 'Coach IA',
                      style: IconButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                // ====== BODY CONTENT ======
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateRow(
                          selectedDate: state.date,
                          onChanged: notifier.loadForDate,
                          onPrevious: () => notifier.shiftDate(-1),
                          onNext: state.date.isBefore(_today())
                              ? () => notifier.shiftDate(1)
                              : null,
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 16),

                        // Quick Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.flash_on,
                                label: 'Quick add',
                                color: const Color(0xFFF97316),
                                onTap: () => _showQuickAddSheet(context, ref),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.edit_note,
                                label: 'Manual',
                                color: const Color(0xFF3B82F6),
                                onTap: () => _showManualEntrySheet(context, ref),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.photo_camera_back_outlined,
                                label: 'Foto IA',
                                color: const Color(0xFF8B5CF6),
                                onTap: state.isAnalyzingPhoto
                                    ? null
                                    : () => _showPhotoSourceSheet(context, ref),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 18),

                        _GoalsCard(
                          goals: state.goals,
                          summary: summary,
                          onEdit: () => _showGoalsSheet(context, ref, state.goals),
                        ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 14),

                        _MacroGrid(summary: summary)
                            .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 14),

                        _CoachCard(
                          summary: summary,
                          coach: coach,
                          onOpenDetails: state.entries.isEmpty
                              ? null
                              : () => _showCoachSheet(context, summary, coach),
                        ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 14),

                        _RecipeLibrarySection(
                          recipes: state.recipes,
                          onOpenLibrary: () => _showRecipePickerSheet(context, ref),
                          onAddRecipe: (recipe) async {
                            await ref
                                .read(nutritionProvider.notifier)
                                .addRecipeToDay(recipe);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${recipe.name} agregado a ${recipe.mealType.label.toLowerCase()}.',
                                  ),
                                ),
                              );
                            }
                          },
                          onDeleteRecipe: (recipe) =>
                              _confirmDeleteRecipe(context, ref, recipe),
                        ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05, end: 0),
                        const SizedBox(height: 18),

                        if (state.entries.isEmpty)
                          _EmptyNutritionState(
                            onQuickAdd: () => _showQuickAddSheet(context, ref),
                            onManualAdd: () => _showManualEntrySheet(context, ref),
                            onPhotoAdd: () => _showPhotoSourceSheet(context, ref),
                          ).animate().fadeIn(duration: 500.ms, delay: 350.ms).slideY(begin: 0.08, end: 0)
                        else
                          ...MealType.values.map((mealType) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _MealSection(
                                mealType: mealType,
                                entries: summary.entriesFor(mealType),
                                totalCalories: summary.caloriesFor(mealType),
                                onAddQuick: () =>
                                    _showQuickAddSheet(context, ref, mealType: mealType),
                                onAddManual: () => _showManualEntrySheet(
                                  context,
                                  ref,
                                  mealType: mealType,
                                ),
                                onAddRecipe: () => _showRecipePickerSheet(
                                  context,
                                  ref,
                                  mealType: mealType,
                                ),
                                onAnalyzePhoto: () => _showPhotoSourceSheet(
                                  context,
                                  ref,
                                  mealType: mealType,
                                ),
                                onSaveAsRecipe: () =>
                                    _showSaveRecipeDialog(context, ref, mealType),
                                onEdit: (entry) => _showManualEntrySheet(
                                  context,
                                  ref,
                                  initialDraft: ManualEntryDraft.fromEntry(entry),
                                  title: 'Editar alimento',
                                  saveLabel: 'Actualizar alimento',
                                  description:
                                      'Ajusta macros, nombre o comida sin perder el historial.',
                                ),
                                onDelete: (entry) =>
                                    _confirmDeleteEntry(context, ref, entry),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ====== LOADING/SAVING OVERLAY ======
          if (state.isSaving || state.isAnalyzingPhoto)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Color(0xFFF97316)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          state.isAnalyzingPhoto
                              ? 'Analizando foto con IA...'
                              : 'Guardando registro...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.isAnalyzingPhoto
                              ? 'Estimando macros y calorías del plato'
                              : 'Tu registro premium queda guardado',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // ====== FLOATING ACTION BUTTON ======
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context, ref),
        backgroundColor: const Color(0xFFF97316),
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Future<void> _recoverLostPhotoIfAny(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!Platform.isAndroid || !context.mounted) {
      return;
    }

    final response = await ImagePicker().retrieveLostData();
    if (!context.mounted || response.isEmpty) {
      return;
    }

    if (response.exception != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Android interrumpio la seleccion de la foto. Intenta otra vez.',
          ),
        ),
      );
      return;
    }

    final files = response.files;
    final photo = files != null && files.isNotEmpty
        ? files.first
        : response.file;
    if (photo == null) {
      return;
    }

    final draft = await ref
        .read(nutritionProvider.notifier)
        .analyzeMealPhoto(
          photo: photo,
          mealType: MealType.snack,
          mealContext: 'Comida fotografiada',
        );

    if (!context.mounted || draft == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Recupere la foto que Android perdio al volver de la galeria.',
        ),
      ),
    );

    final state = ref.read(nutritionProvider);
    _showAiAnalysisReviewSheet(
      context,
      ref,
      initialDraft: ManualEntryDraft.fromPhotoDraft(draft),
      goals: state.goals,
      title: 'Revisar análisis IA',
      description:
          'Android reinició el flujo al volver de la galería. Recuperé la foto y rehice el análisis para que revises y guardes.',
      saveLabel: 'Guardar desde foto',
    );
  }

  Future<XFile?> _pickNutritionPhoto(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final selectedPath = result.files.first.path;
      if (selectedPath == null || selectedPath.isEmpty) {
        return null;
      }

      return XFile(selectedPath);
    }

    final picker = ImagePicker();
    return picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
      requestFullMetadata: false,
    );
  }

  void _showQuickAddSheet(
    BuildContext context,
    WidgetRef ref, {
    MealType? mealType,
  }) {
    final hostContext = context;
    String query = '';
    FoodCategory? selectedCategory;
    double multiplier = 1;
    MealType selectedMealType = mealType ?? MealType.snack;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final foods = PresetFoods.filter(
            query: query,
            category: selectedCategory,
          );

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  'Quick add premium',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Busca alimentos, elige la comida y ajusta la porcion antes de guardar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setSheetState(() => query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Pollo, avena, yogur, fruta...',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Comida',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MealType.values.map((candidate) {
                    return ChoiceChip(
                      label: Text(candidate.label),
                      avatar: Icon(candidate.icon, size: 18),
                      selected: selectedMealType == candidate,
                      onSelected: (_) {
                        setSheetState(() => selectedMealType = candidate);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Categoria',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: selectedCategory == null,
                      onSelected: (_) {
                        setSheetState(() => selectedCategory = null);
                      },
                    ),
                    ...FoodCategory.values.map((category) {
                      return ChoiceChip(
                        label: Text(category.label),
                        selected: selectedCategory == category,
                        onSelected: (_) {
                          setSheetState(() => selectedCategory = category);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Porcion',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [0.5, 1.0, 1.5, 2.0].map((factor) {
                    return ChoiceChip(
                      label: Text('${_servingLabel(factor)}x'),
                      selected: multiplier == factor,
                      onSelected: (_) {
                        setSheetState(() => multiplier = factor);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  '${foods.length} resultados',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (foods.isEmpty)
                  const _SheetEmptyState(
                    title: 'No encontre coincidencias',
                    subtitle:
                        'Prueba otra busqueda o agrega un alimento manual.',
                  )
                else
                  ...foods.map((food) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(food.macroLine(multiplier: multiplier)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _TagChip(
                                    label: food.category.label,
                                    color: food.category.accentColor,
                                    icon: food.category.icon,
                                  ),
                                  _TagChip(
                                    label: selectedMealType.label,
                                    color: selectedMealType.accentColor,
                                    icon: selectedMealType.icon,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () async {
                            await ref
                                .read(nutritionProvider.notifier)
                                .addPresetFood(
                                  food,
                                  mealType: selectedMealType,
                                  multiplier: multiplier,
                                );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                            if (hostContext.mounted) {
                              ScaffoldMessenger.of(hostContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${food.name} agregado a ${selectedMealType.label.toLowerCase()}.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_circle),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showManualEntrySheet(
    BuildContext context,
    WidgetRef ref, {
    MealType? mealType,
    ManualEntryDraft? initialDraft,
    String? title,
    String? description,
    String? saveLabel,
  }) {
    final draft =
        initialDraft ?? ManualEntryDraft.empty(mealType ?? MealType.snack);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ManualEntrySheet(
        initialDraft: draft,
        title:
            title ?? (draft.isEditing ? 'Editar alimento' : 'Entrada manual'),
        description:
            description ??
            'Perfecto para platos propios, restaurantes y recetas que no estan en presets.',
        saveLabel:
            saveLabel ??
            (draft.isEditing ? 'Actualizar comida' : 'Guardar comida'),
        onSave: (updatedDraft) async {
          final notifier = ref.read(nutritionProvider.notifier);
          if (updatedDraft.isEditing) {
            await notifier.updateEntry(
              entryId: updatedDraft.entryId!,
              name: updatedDraft.name,
              mealType: updatedDraft.mealType,
              calories: updatedDraft.calories,
              protein: updatedDraft.protein,
              carbs: updatedDraft.carbs,
              fat: updatedDraft.fat,
              fiber: updatedDraft.fiber,
              imageUrl: updatedDraft.imageUrl,
              confidence: updatedDraft.confidence,
            );
          } else {
            await notifier.addManualEntry(
              name: updatedDraft.name,
              mealType: updatedDraft.mealType,
              calories: updatedDraft.calories,
              protein: updatedDraft.protein,
              carbs: updatedDraft.carbs,
              fat: updatedDraft.fat,
              fiber: updatedDraft.fiber,
              imageUrl: updatedDraft.imageUrl,
              confidence: updatedDraft.confidence,
            );
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  updatedDraft.isEditing
                      ? '${updatedDraft.name} actualizado.'
                      : '${updatedDraft.name} guardado en ${updatedDraft.mealType.label.toLowerCase()}.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showAiAnalysisReviewSheet(
    BuildContext context,
    WidgetRef ref, {
    required ManualEntryDraft initialDraft,
    required NutritionGoal goals,
    String? title,
    String? description,
    String? saveLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiAnalysisReviewSheet(
        initialDraft: initialDraft,
        goals: goals,
        title: title ?? 'Revisar análisis IA',
        description: description ??
            'La IA hizo una primera estimación. Corrígela si hace falta antes de guardar.',
        saveLabel: saveLabel ?? 'Guardar desde foto',
        onSave: (updatedDraft) async {
          final notifier = ref.read(nutritionProvider.notifier);
          if (updatedDraft.isEditing) {
            await notifier.updateEntry(
              entryId: updatedDraft.entryId!,
              name: updatedDraft.name,
              mealType: updatedDraft.mealType,
              calories: updatedDraft.calories,
              protein: updatedDraft.protein,
              carbs: updatedDraft.carbs,
              fat: updatedDraft.fat,
              fiber: updatedDraft.fiber,
              imageUrl: updatedDraft.imageUrl,
              confidence: updatedDraft.confidence,
            );
          } else {
            await notifier.addManualEntry(
              name: updatedDraft.name,
              mealType: updatedDraft.mealType,
              calories: updatedDraft.calories,
              protein: updatedDraft.protein,
              carbs: updatedDraft.carbs,
              fat: updatedDraft.fat,
              fiber: updatedDraft.fiber,
              imageUrl: updatedDraft.imageUrl,
              confidence: updatedDraft.confidence,
            );
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  updatedDraft.isEditing
                      ? '${updatedDraft.name} actualizado.'
                      : '${updatedDraft.name} guardado en ${updatedDraft.mealType.label.toLowerCase()}.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showGoalsSheet(
    BuildContext context,
    WidgetRef ref,
    NutritionGoal goals,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalEditorSheet(
        initialGoal: goals,
        onSave: (goal) async {
          await ref.read(nutritionProvider.notifier).saveGoals(goal);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Objetivos actualizados.')),
            );
          }
        },
      ),
    );
  }

  Future<void> _showRecipePickerSheet(
    BuildContext context,
    WidgetRef ref, {
    MealType? mealType,
  }) {
    final recipes = ref.read(nutritionProvider).recipes;
    double multiplier = 1;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.72,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            expand: false,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text(
                  'Biblioteca de recetas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mealType == null
                      ? 'Guarda tus combinaciones favoritas y vuelvelas a cargar con un toque.'
                      : 'Agrega una receta directamente a ${mealType.label.toLowerCase()}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Porcion',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [0.5, 1.0, 1.5, 2.0].map((factor) {
                    return ChoiceChip(
                      label: Text('${_servingLabel(factor)}x'),
                      selected: multiplier == factor,
                      onSelected: (_) {
                        setSheetState(() => multiplier = factor);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                if (recipes.isEmpty)
                  const _SheetEmptyState(
                    title: 'Todavia no tienes recetas guardadas',
                    subtitle:
                        'Guarda una comida completa desde cualquier bloque del dia para reutilizarla despues.',
                  )
                else
                  ...recipes.map((recipe) {
                    return _RecipeSheetTile(
                      recipe: recipe,
                      multiplier: multiplier,
                      mealTypeOverride: mealType,
                      onAdd: () async {
                        await ref
                            .read(nutritionProvider.notifier)
                            .addRecipeToDay(
                              recipe,
                              multiplier: multiplier,
                              mealType: mealType,
                            );
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        if (context.mounted) {
                          final destination = mealType ?? recipe.mealType;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${recipe.name} agregado a ${destination.label.toLowerCase()}.',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSaveRecipeDialog(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
  ) async {
    final nameController = TextEditingController(
      text: '${mealType.label} premium',
    );
    final notesController = TextEditingController();

    final draft = await showDialog<_RecipeSaveDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Guardar como receta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas',
                hintText:
                    'Opcional: salsa aparte, version ligera, pre entreno...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(
                _RecipeSaveDraft(
                  name: name,
                  notes: notesController.text.trim(),
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    nameController.dispose();
    notesController.dispose();

    if (draft == null) {
      return;
    }

    await ref
        .read(nutritionProvider.notifier)
        .saveMealAsRecipe(
          mealType: mealType,
          name: draft.name,
          notes: draft.notes,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${draft.name} guardada en tu biblioteca.')),
      );
    }
  }

  Future<void> _showPhotoSourceSheet(
    BuildContext context,
    WidgetRef ref, {
    MealType? mealType,
  }) async {
    MealType selectedMealType = mealType ?? MealType.snack;
    final request = await showModalBottomSheet<_PhotoCaptureRequest>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analizar comida desde foto',
                  style: Theme.of(sheetContext).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toma una foto o elige una imagen. La IA propone macros y tu decides si los ajustas antes de guardar.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Comida',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MealType.values.map((candidate) {
                    return ChoiceChip(
                      label: Text(candidate.label),
                      selected: selectedMealType == candidate,
                      onSelected: (_) {
                        setSheetState(() => selectedMealType = candidate);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          _PhotoCaptureRequest(
                            source: ImageSource.camera,
                            mealType: selectedMealType,
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camara'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          _PhotoCaptureRequest(
                            source: ImageSource.gallery,
                            mealType: selectedMealType,
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeria'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (request == null || !context.mounted) {
      return;
    }

    final photo = await _pickNutritionPhoto(request.source);

    if (photo == null || !context.mounted) {
      return;
    }

    final draft = await ref
        .read(nutritionProvider.notifier)
        .analyzeMealPhoto(
          photo: photo,
          mealType: request.mealType,
          mealContext: request.mealType.label,
        );

    if (draft == null || !context.mounted) {
      return;
    }

    final state = ref.read(nutritionProvider);
    _showAiAnalysisReviewSheet(
      context,
      ref,
      initialDraft: ManualEntryDraft.fromPhotoDraft(draft),
      goals: state.goals,
      title: 'Revisar análisis IA',
      description:
          'La IA hizo una primera estimación. Corrígela si hace falta antes de guardar.',
      saveLabel: 'Guardar desde foto',
    );
  }

  Future<void> _confirmDeleteEntry(
    BuildContext context,
    WidgetRef ref,
    NutritionEntry entry,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar alimento'),
        content: Text('Voy a quitar ${entry.name} de tu registro del dia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(nutritionProvider.notifier).deleteEntry(entry.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${entry.name} eliminado.')));
    }
  }

  Future<void> _confirmDeleteRecipe(
    BuildContext context,
    WidgetRef ref,
    NutritionRecipe recipe,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('Voy a quitar ${recipe.name} de tu biblioteca.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(nutritionProvider.notifier).deleteRecipe(recipe.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${recipe.name} eliminada.')));
    }
  }

  void _showCoachSheet(
    BuildContext context,
    _NutritionSummary summary,
    _NutritionCoach coach,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.56,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Coach nutricional',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _ScoreBanner(coach: coach),
            const SizedBox(height: 16),
            Text(
              'Lectura del dia',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...coach.insights.map((insight) => _InsightRow(text: insight)),
            const SizedBox(height: 18),
            Text(
              'Radar rapido',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _CoachMetricLine(
              label: 'Calorias',
              value:
                  '${summary.consumedCalories}/${summary.goals.calorieGoal} kcal',
            ),
            _CoachMetricLine(
              label: 'Proteina',
              value:
                  '${summary.protein.toStringAsFixed(0)}/${summary.goals.proteinGoal.toStringAsFixed(0)} g',
            ),
            _CoachMetricLine(
              label: 'Fibra',
              value:
                  '${summary.fiber.toStringAsFixed(0)}/${summary.goals.fiberGoal.toStringAsFixed(0)} g',
            ),
            _CoachMetricLine(
              label: 'Bloques activos',
              value: '${summary.loggedMealsCount}/4',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _servingLabel(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

bool _supportsInlineImagePreview(String imagePath) {
  final normalizedPath = imagePath.toLowerCase();
  return !normalizedPath.endsWith('.heic') && !normalizedPath.endsWith('.heif');
}

class _NutritionSummary {
  _NutritionSummary._({required this.entries, required this.goals});

  final List<NutritionEntry> entries;
  final NutritionGoal goals;

  factory _NutritionSummary.fromState(NutritionState state) {
    return _NutritionSummary._(entries: state.entries, goals: state.goals);
  }

  int get consumedCalories =>
      entries.fold<int>(0, (sum, entry) => sum + entry.calories);

  double get protein =>
      entries.fold<double>(0, (sum, entry) => sum + entry.protein);

  double get carbs =>
      entries.fold<double>(0, (sum, entry) => sum + entry.carbs);

  double get fat => entries.fold<double>(0, (sum, entry) => sum + entry.fat);

  double get fiber =>
      entries.fold<double>(0, (sum, entry) => sum + entry.fiber);

  double get calorieProgress =>
      (consumedCalories / _safeCalorieGoal).clamp(0.0, 1.0);

  int get remainingCalories => goals.calorieGoal - consumedCalories;

  int get loggedMealsCount =>
      MealType.values.where((meal) => entriesFor(meal).isNotEmpty).length;

  List<NutritionEntry> entriesFor(MealType mealType) {
    final items = entries.where((entry) => entry.mealType == mealType).toList();
    items.sort((left, right) => right.consumedAt.compareTo(left.consumedAt));
    return items;
  }

  int caloriesFor(MealType mealType) {
    return entriesFor(
      mealType,
    ).fold<int>(0, (sum, entry) => sum + entry.calories);
  }

  double progressForMacro(String macro) {
    switch (macro) {
      case 'protein':
        return (protein / _safeProteinGoal).clamp(0.0, 1.0);
      case 'carbs':
        return (carbs / _safeCarbsGoal).clamp(0.0, 1.0);
      case 'fat':
        return (fat / _safeFatGoal).clamp(0.0, 1.0);
      case 'fiber':
        return (fiber / _safeFiberGoal).clamp(0.0, 1.0);
      default:
        return 0;
    }
  }

  int get _safeCalorieGoal => goals.calorieGoal <= 0 ? 1 : goals.calorieGoal;

  double get _safeProteinGoal => goals.proteinGoal <= 0 ? 1 : goals.proteinGoal;

  double get _safeCarbsGoal => goals.carbsGoal <= 0 ? 1 : goals.carbsGoal;

  double get _safeFatGoal => goals.fatGoal <= 0 ? 1 : goals.fatGoal;

  double get _safeFiberGoal => goals.fiberGoal <= 0 ? 1 : goals.fiberGoal;
}

class _NutritionCoach {
  const _NutritionCoach({
    required this.score,
    required this.label,
    required this.headline,
    required this.insights,
  });

  final int score;
  final String label;
  final String headline;
  final List<String> insights;

  factory _NutritionCoach.fromSummary(_NutritionSummary summary) {
    if (summary.entries.isEmpty) {
      return const _NutritionCoach(
        score: 0,
        label: 'Sin datos',
        headline: 'Empieza registrando tu primera comida.',
        insights: [
          'Quick add te deja cargar alimentos base en segundos con porciones reales.',
          'La entrada manual sirve para platos propios, restaurantes o recetas.',
          'Cuando registres varias comidas, el coach empezara a detectar huecos de proteina, fibra y calorias.',
        ],
      );
    }

    final calorieAccuracy =
        (1 -
                ((summary.consumedCalories - summary._safeCalorieGoal).abs() /
                    summary._safeCalorieGoal))
            .clamp(0.0, 1.0);
    final proteinCoverage = (summary.protein / summary._safeProteinGoal).clamp(
      0.0,
      1.0,
    );
    final fiberCoverage = (summary.fiber / summary._safeFiberGoal).clamp(
      0.0,
      1.0,
    );
    final mealCoverage = (summary.loggedMealsCount / 4).clamp(0.0, 1.0);

    final score =
        (calorieAccuracy * 40 +
                proteinCoverage * 25 +
                fiberCoverage * 20 +
                mealCoverage * 15)
            .round();

    final insights = <String>[];

    if (summary.protein < summary._safeProteinGoal * 0.65) {
      insights.add(
        'La proteina va baja para tu objetivo. Mete una fuente fuerte en la siguiente comida: pollo, atun, yogur griego o tofu.',
      );
    } else if (summary.protein >= summary._safeProteinGoal * 0.9) {
      insights.add(
        'Muy bien en proteina. Mantienes una base solida para saciedad y recuperacion.',
      );
    }

    if (summary.fiber < summary._safeFiberGoal * 0.6) {
      insights.add(
        'Te faltan fibras. Suma fruta, avena, verduras o frutos rojos para que la comida no se quede solo en calorias.',
      );
    }

    if (summary.consumedCalories < summary._safeCalorieGoal * 0.65) {
      insights.add(
        'Todavia vas corto de energia. Si este es tu cierre del dia, te conviene una comida mas completa.',
      );
    } else if (summary.consumedCalories > summary._safeCalorieGoal * 1.12) {
      insights.add(
        'Hoy te pasaste de calorias. El siguiente ajuste mas rentable es recortar extras liquidos o grasas densas.',
      );
    }

    if (summary.loggedMealsCount <= 2) {
      insights.add(
        'Tu registro esta muy concentrado. Repartir mejor las comidas suele mejorar adherencia y control del hambre.',
      );
    }

    if (insights.isEmpty) {
      insights.add(
        'Dia muy solido. Calorias y macros estan en una zona estable y la estructura de comidas se ve consistente.',
      );
    }

    final label = switch (score) {
      >= 90 => 'Elite',
      >= 75 => 'Muy fuerte',
      >= 60 => 'Bien encaminado',
      >= 40 => 'Mejorable',
      _ => 'Desordenado',
    };

    final headline = switch (score) {
      >= 90 => 'Tu dia se ve premium: control, balance y buena cobertura.',
      >= 75 => 'Buena ejecucion. Hay poco que tocar para cerrar muy arriba.',
      >= 60 => 'La base esta bien, pero todavia hay uno o dos huecos claros.',
      >= 40 =>
        'Hay estructura, pero faltan decisiones mejores en macros o distribucion.',
      _ =>
        'La nutricion del dia todavia esta demasiado incompleta para fiarte de ella.',
    };

    return _NutritionCoach(
      score: score,
      label: label,
      headline: headline,
      insights: insights,
    );
  }
}

class _RecipeSaveDraft {
  const _RecipeSaveDraft({required this.name, required this.notes});

  final String name;
  final String notes;
}

class _PhotoCaptureRequest {
  const _PhotoCaptureRequest({required this.source, required this.mealType});

  final ImageSource source;
  final MealType mealType;
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.selectedDate,
    required this.onChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today();
    final isToday =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF97316).withValues(alpha: 0.06),
            theme.colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: onPrevious,
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: today,
                );
                if (date != null) {
                  onChanged(date);
                }
              },
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isToday)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        isToday
                            ? 'Hoy'
                            : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isToday ? 'Registro en vivo' : 'Historial del día',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: onNext,
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }
}


class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.summary,
    required this.coach,
    required this.onOpenDetails,
  });

  final _NutritionSummary summary;
  final _NutritionCoach coach;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF97316).withValues(alpha: 0.10),
            theme.colorScheme.tertiary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFEA580C),
                  size: 18,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(end: const Offset(1.12, 1.12), duration: 1200.ms),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach Nutricional IA',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                    Text(
                      'Score ${coach.score} · ${coach.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenDetails != null)
                IconButton(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFFEA580C),
                  ),
                  tooltip: 'Ver detalle',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            coach.insights.first,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                label: '${summary.protein.toStringAsFixed(0)} g proteina',
                color: const Color(0xFFEF4444),
                icon: Icons.bolt,
              ),
              _TagChip(
                label: '${summary.fiber.toStringAsFixed(0)} g fibra',
                color: const Color(0xFF10B981),
                icon: Icons.spa,
              ),
              _TagChip(
                label: '${summary.loggedMealsCount}/4 comidas',
                color: const Color(0xFF3B82F6),
                icon: Icons.schedule,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.goals,
    required this.summary,
    required this.onEdit,
  });

  final NutritionGoal goals;
  final _NutritionSummary summary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: Color(0xFFEA580C), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Objetivos del día',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.tune, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFFEA580C),
                ),
                tooltip: 'Editar metas',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _GoalBadge(
                label: 'Kcal',
                current: '${summary.consumedCalories}',
                target: '${goals.calorieGoal}',
                color: const Color(0xFFF97316),
              ),
              _GoalBadge(
                label: 'P',
                current: summary.protein.toStringAsFixed(0),
                target: goals.proteinGoal.toStringAsFixed(0),
                color: const Color(0xFFEF4444),
              ),
              _GoalBadge(
                label: 'C',
                current: summary.carbs.toStringAsFixed(0),
                target: goals.carbsGoal.toStringAsFixed(0),
                color: const Color(0xFF3B82F6),
              ),
              _GoalBadge(
                label: 'G',
                current: summary.fat.toStringAsFixed(0),
                target: goals.fatGoal.toStringAsFixed(0),
                color: const Color(0xFFF59E0B),
              ),
              _GoalBadge(
                label: 'Fibra',
                current: summary.fiber.toStringAsFixed(0),
                target: goals.fiberGoal.toStringAsFixed(0),
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  final String label;
  final String current;
  final String target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: '$current/$target',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeLibrarySection extends StatelessWidget {
  const _RecipeLibrarySection({
    required this.recipes,
    required this.onOpenLibrary,
    required this.onAddRecipe,
    required this.onDeleteRecipe,
  });

  final List<NutritionRecipe> recipes;
  final VoidCallback onOpenLibrary;
  final ValueChanged<NutritionRecipe> onAddRecipe;
  final ValueChanged<NutritionRecipe> onDeleteRecipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biblioteca de recetas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comidas compuestas listas para reutilizar con un toque.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onOpenLibrary,
                  child: Text(recipes.isEmpty ? 'Abrir' : 'Ver todas'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (recipes.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guarda cualquier comida completa desde su bloque para convertirla en receta.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: onOpenLibrary,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Abrir biblioteca'),
                  ),
                ],
              )
            else
              SizedBox(
                height: 196,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recipes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return _RecipePreviewCard(
                      recipe: recipe,
                      onAdd: () => onAddRecipe(recipe),
                      onDelete: () => onDeleteRecipe(recipe),
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

class _RecipePreviewCard extends StatelessWidget {
  const _RecipePreviewCard({
    required this.recipe,
    required this.onAdd,
    required this.onDelete,
  });

  final NutritionRecipe recipe;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Eliminar receta'),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${recipe.mealType.label} · ${recipe.calories} kcal',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(
                label: 'P ${recipe.protein.toStringAsFixed(0)} g',
                color: const Color(0xFFEF4444),
                icon: Icons.bolt,
              ),
              _TagChip(
                label: 'C ${recipe.carbs.toStringAsFixed(0)} g',
                color: const Color(0xFF3B82F6),
                icon: Icons.grain,
              ),
              _TagChip(
                label: 'G ${recipe.fat.toStringAsFixed(0)} g',
                color: const Color(0xFFF59E0B),
                icon: Icons.water_drop,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recipe.ingredients.join(' · '),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Agregar hoy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  const _MacroGrid({required this.summary});

  final _NutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 52) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: itemWidth,
          child: _MetricCard(
            label: 'Proteina',
            value:
                '${summary.protein.toStringAsFixed(0)}/${summary.goals.proteinGoal.toStringAsFixed(0)} g',
            progress: summary.progressForMacro('protein'),
            color: const Color(0xFFEF4444),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _MetricCard(
            label: 'Carbos',
            value:
                '${summary.carbs.toStringAsFixed(0)}/${summary.goals.carbsGoal.toStringAsFixed(0)} g',
            progress: summary.progressForMacro('carbs'),
            color: const Color(0xFF3B82F6),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _MetricCard(
            label: 'Grasas',
            value:
                '${summary.fat.toStringAsFixed(0)}/${summary.goals.fatGoal.toStringAsFixed(0)} g',
            progress: summary.progressForMacro('fat'),
            color: const Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: itemWidth,
          child: _MetricCard(
            label: 'Fibra',
            value:
                '${summary.fiber.toStringAsFixed(0)}/${summary.goals.fiberGoal.toStringAsFixed(0)} g',
            progress: summary.progressForMacro('fiber'),
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.mealType,
    required this.entries,
    required this.totalCalories,
    required this.onAddQuick,
    required this.onAddManual,
    required this.onAddRecipe,
    required this.onAnalyzePhoto,
    required this.onSaveAsRecipe,
    required this.onEdit,
    required this.onDelete,
  });

  final MealType mealType;
  final List<NutritionEntry> entries;
  final int totalCalories;
  final VoidCallback onAddQuick;
  final VoidCallback onAddManual;
  final VoidCallback onAddRecipe;
  final VoidCallback onAnalyzePhoto;
  final VoidCallback onSaveAsRecipe;
  final ValueChanged<NutritionEntry> onEdit;
  final ValueChanged<NutritionEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: mealType.accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: mealType.accentColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          mealType.accentColor.withValues(alpha: 0.18),
                          mealType.accentColor.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(mealType.icon, color: mealType.accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealType.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entries.isEmpty
                              ? 'Sin registros aún'
                              : '${entries.length} items · $totalCalories kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'quick') {
                        onAddQuick();
                      } else if (value == 'manual') {
                        onAddManual();
                      } else if (value == 'recipe') {
                        onAddRecipe();
                      } else if (value == 'photo') {
                        onAnalyzePhoto();
                      } else if (value == 'save_recipe') {
                        onSaveAsRecipe();
                      }
                    },
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: mealType.accentColor,
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'quick', child: Text('Quick add')),
                      PopupMenuItem(value: 'manual', child: Text('Agregar manual')),
                      PopupMenuItem(value: 'recipe', child: Text('Usar receta')),
                      PopupMenuItem(value: 'photo', child: Text('Analizar foto')),
                      PopupMenuItem(
                        value: 'save_recipe',
                        child: Text('Guardar como receta'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                _MealEmptyState(
                  mealType: mealType,
                  onAddQuick: onAddQuick,
                  onAddManual: onAddManual,
                  onAddRecipe: onAddRecipe,
                  onPhotoAdd: onAnalyzePhoto,
                )
              else
                ...entries.map(
                  (entry) => _MealEntryTile(
                    entry: entry,
                    onEdit: () => onEdit(entry),
                    onDelete: () => onDelete(entry),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingScore extends StatelessWidget {
  const _RingScore({required this.progress, required this.value});

  final double progress;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(
                const Color(0xFFF97316).withValues(alpha: 0.12),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF97316)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              Text(
                'kcal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyNutritionState extends StatelessWidget {
  const _EmptyNutritionState({
    required this.onQuickAdd,
    required this.onManualAdd,
    required this.onPhotoAdd,
  });

  final VoidCallback onQuickAdd;
  final VoidCallback onManualAdd;
  final VoidCallback onPhotoAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF97316).withValues(alpha: 0.06),
            const Color(0xFFFACC15).withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF97316).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFACC15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Empieza a registrar tu nutrición',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Foto IA, búsqueda rápida o registro manual. Tú eliges cómo empezar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.flash_on,
                  label: 'Quick add',
                  color: const Color(0xFFF97316),
                  onTap: onQuickAdd,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.edit_note,
                  label: 'Manual',
                  color: const Color(0xFF3B82F6),
                  onTap: onManualAdd,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.photo_camera_back_outlined,
                  label: 'Foto IA',
                  color: const Color(0xFF8B5CF6),
                  onTap: onPhotoAdd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealEmptyState extends StatelessWidget {
  const _MealEmptyState({
    required this.mealType,
    required this.onAddQuick,
    required this.onAddManual,
    required this.onAddRecipe,
    required this.onPhotoAdd,
  });

  final MealType mealType;
  final VoidCallback onAddQuick;
  final VoidCallback onAddManual;
  final VoidCallback onAddRecipe;
  final VoidCallback onPhotoAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nada registrado en ${mealType.label.toLowerCase()}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onAddQuick,
                child: const Text('Quick add'),
              ),
              OutlinedButton(
                onPressed: onAddManual,
                child: const Text('Agregar manual'),
              ),
              OutlinedButton(
                onPressed: onAddRecipe,
                child: const Text('Usar receta'),
              ),
              OutlinedButton(
                onPressed: onPhotoAdd,
                child: const Text('Foto IA'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealEntryTile extends StatelessWidget {
  const _MealEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final NutritionEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = TimeOfDay.fromDateTime(entry.consumedAt).format(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time · ${entry.calories} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagChip(
                      label: 'P ${entry.protein.toStringAsFixed(0)} g',
                      color: const Color(0xFFEF4444),
                      icon: Icons.bolt,
                    ),
                    _TagChip(
                      label: 'C ${entry.carbs.toStringAsFixed(0)} g',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.grain,
                    ),
                    _TagChip(
                      label: 'G ${entry.fat.toStringAsFixed(0)} g',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.water_drop,
                    ),
                    if (entry.fiber > 0)
                      _TagChip(
                        label: 'Fibra ${entry.fiber.toStringAsFixed(0)} g',
                        color: const Color(0xFF10B981),
                        icon: Icons.spa,
                      ),
                    if (entry.imageUrl != null)
                      _TagChip(
                        label: entry.confidence >= 0.999
                            ? 'Foto'
                            : 'IA ${(entry.confidence * 100).round()}%',
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.camera_alt_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBanner extends StatelessWidget {
  const _ScoreBanner({required this.coach});

  final _NutritionCoach coach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '${coach.score}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(coach.headline),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.check_circle, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _CoachMetricLine extends StatelessWidget {
  const _CoachMetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ManualEntryDraft {
  const ManualEntryDraft({
    this.entryId,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.imageUrl,
    this.confidence = 1,
    this.assistantNote,
  });

  final String? entryId;
  final String name;
  final MealType mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String? imageUrl;
  final double confidence;
  final String? assistantNote;

  bool get isEditing => entryId != null;

  bool get hasPhoto => imageUrl != null && imageUrl!.isNotEmpty;

  factory ManualEntryDraft.empty(MealType mealType) {
    return ManualEntryDraft(
      name: '',
      mealType: mealType,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      fiber: 0,
    );
  }

  factory ManualEntryDraft.fromEntry(NutritionEntry entry) {
    return ManualEntryDraft(
      entryId: entry.id,
      name: entry.name,
      mealType: entry.mealType,
      calories: entry.calories,
      protein: entry.protein,
      carbs: entry.carbs,
      fat: entry.fat,
      fiber: entry.fiber,
      imageUrl: entry.imageUrl,
      confidence: entry.confidence,
    );
  }

  factory ManualEntryDraft.fromPhotoDraft(NutritionPhotoDraft draft) {
    return ManualEntryDraft(
      name: draft.analysis.name,
      mealType: draft.mealType,
      calories: draft.analysis.calories,
      protein: draft.analysis.protein,
      carbs: draft.analysis.carbs,
      fat: draft.analysis.fat,
      fiber: draft.analysis.fiber,
      imageUrl: draft.imagePath,
      confidence: draft.analysis.confidence,
      assistantNote: draft.analysis.notes,
    );
  }
}

class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet({
    required this.initialDraft,
    required this.title,
    required this.description,
    required this.saveLabel,
    required this.onSave,
  });

  final ManualEntryDraft initialDraft;
  final String title;
  final String description;
  final String saveLabel;
  final Future<void> Function(ManualEntryDraft draft) onSave;

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  late MealType _selectedMealType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialDraft.mealType;
    _nameController.text = widget.initialDraft.name;
    _caloriesController.text = widget.initialDraft.calories == 0
        ? ''
        : widget.initialDraft.calories.toString();
    _proteinController.text = widget.initialDraft.protein == 0
        ? ''
        : widget.initialDraft.protein.toStringAsFixed(0);
    _carbsController.text = widget.initialDraft.carbs == 0
        ? ''
        : widget.initialDraft.carbs.toStringAsFixed(0);
    _fatController.text = widget.initialDraft.fat == 0
        ? ''
        : widget.initialDraft.fat.toStringAsFixed(0);
    _fiberController.text = widget.initialDraft.fiber == 0
        ? ''
        : widget.initialDraft.fiber.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPreviewablePhoto =
        widget.initialDraft.hasPhoto &&
        _supportsInlineImagePreview(widget.initialDraft.imageUrl!);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (widget.initialDraft.hasPhoto) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: hasPreviewablePhoto
                      ? Image.file(
                          File(widget.initialDraft.imageUrl!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 120,
                            color: theme.colorScheme.surfaceContainerLow,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: theme.colorScheme.surfaceContainerLow,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_outlined),
                              const SizedBox(height: 8),
                              Text(
                                'La foto se cargó, pero este dispositivo no puede previsualizar HEIC/HEIF aquí.',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimacion IA ${(widget.initialDraft.confidence * 100).round()}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.initialDraft.assistantNote != null &&
                          widget.initialDraft.assistantNote!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(widget.initialDraft.assistantNote!),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del alimento o plato',
                  hintText: 'Bowl de pollo con arroz',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ponle un nombre.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Comida',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MealType.values.map((mealType) {
                  return ChoiceChip(
                    label: Text(mealType.label),
                    selected: _selectedMealType == mealType,
                    onSelected: (_) {
                      setState(() => _selectedMealType = mealType);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _NumericField(
                      controller: _caloriesController,
                      label: 'Calorias',
                      hint: '520',
                      isInteger: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumericField(
                      controller: _proteinController,
                      label: 'Proteina (g)',
                      hint: '38',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumericField(
                      controller: _carbsController,
                      label: 'Carbos (g)',
                      hint: '42',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumericField(
                      controller: _fatController,
                      label: 'Grasas (g)',
                      hint: '18',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _NumericField(
                controller: _fiberController,
                label: 'Fibra (g)',
                hint: '8',
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(_isSaving ? 'Guardando...' : widget.saveLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final calories = _parseInt(_caloriesController.text);
    final protein = _parseDouble(_proteinController.text);
    final carbs = _parseDouble(_carbsController.text);
    final fat = _parseDouble(_fatController.text);
    final fiber = _parseDouble(_fiberController.text);

    if (calories == 0 && protein == 0 && carbs == 0 && fat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pon al menos calorias o macros para que el registro sirva.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(
      ManualEntryDraft(
        entryId: widget.initialDraft.entryId,
        name: _nameController.text.trim(),
        mealType: _selectedMealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        imageUrl: widget.initialDraft.imageUrl,
        confidence: widget.initialDraft.confidence,
        assistantNote: widget.initialDraft.assistantNote,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  double _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }
}

class _GoalEditorSheet extends StatefulWidget {
  const _GoalEditorSheet({required this.initialGoal, required this.onSave});

  final NutritionGoal initialGoal;
  final Future<void> Function(NutritionGoal goal) onSave;

  @override
  State<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<_GoalEditorSheet> {
  late final TextEditingController _calorieController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calorieController = TextEditingController(
      text: widget.initialGoal.calorieGoal.toString(),
    );
    _proteinController = TextEditingController(
      text: widget.initialGoal.proteinGoal.toStringAsFixed(0),
    );
    _carbsController = TextEditingController(
      text: widget.initialGoal.carbsGoal.toStringAsFixed(0),
    );
    _fatController = TextEditingController(
      text: widget.initialGoal.fatGoal.toStringAsFixed(0),
    );
    _fiberController = TextEditingController(
      text: widget.initialGoal.fiberGoal.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _calorieController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objetivos personalizados',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta calorias y macros para que el coach mida contra lo que de verdad buscas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    controller: _calorieController,
                    label: 'Calorias',
                    hint: '2200',
                    isInteger: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumericField(
                    controller: _proteinController,
                    label: 'Proteina',
                    hint: '150',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    controller: _carbsController,
                    label: 'Carbos',
                    hint: '250',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumericField(
                    controller: _fatController,
                    label: 'Grasas',
                    hint: '70',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _NumericField(
              controller: _fiberController,
              label: 'Fibra',
              hint: '28',
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar objetivos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave(
      NutritionGoal(
        calorieGoal: _parsePositiveInt(
          _calorieController.text,
          widget.initialGoal.calorieGoal,
        ),
        proteinGoal: _parsePositiveDouble(
          _proteinController.text,
          widget.initialGoal.proteinGoal,
        ),
        carbsGoal: _parsePositiveDouble(
          _carbsController.text,
          widget.initialGoal.carbsGoal,
        ),
        fatGoal: _parsePositiveDouble(
          _fatController.text,
          widget.initialGoal.fatGoal,
        ),
        fiberGoal: _parsePositiveDouble(
          _fiberController.text,
          widget.initialGoal.fiberGoal,
        ),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  int _parsePositiveInt(String value, int fallback) {
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed <= 0 ? fallback : parsed;
  }

  double _parsePositiveDouble(String value, double fallback) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed == null || parsed <= 0 ? fallback : parsed;
  }
}

class _RecipeSheetTile extends StatelessWidget {
  const _RecipeSheetTile({
    required this.recipe,
    required this.multiplier,
    required this.mealTypeOverride,
    required this.onAdd,
  });

  final NutritionRecipe recipe;
  final double multiplier;
  final MealType? mealTypeOverride;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final effectiveMealType = mealTypeOverride ?? recipe.mealType;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          recipe.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${effectiveMealType.label} · ${(recipe.calories * multiplier).round()} kcal · ${recipe.ingredients.join(' · ')}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TagChip(
                    label:
                        'P ${(recipe.protein * multiplier).toStringAsFixed(0)} g',
                    color: const Color(0xFFEF4444),
                    icon: Icons.bolt,
                  ),
                  _TagChip(
                    label:
                        'C ${(recipe.carbs * multiplier).toStringAsFixed(0)} g',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.grain,
                  ),
                  _TagChip(
                    label:
                        'G ${(recipe.fat * multiplier).toStringAsFixed(0)} g',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.water_drop,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle),
        ),
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isInteger = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isInteger;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
