import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_entry.dart';
import 'package:dead_porky/features/nutrition/domain/entities/nutrition_goal.dart';
import 'package:dead_porky/features/nutrition/presentation/screens/nutrition_screen.dart';

class AiAnalysisReviewSheet extends StatefulWidget {
  const AiAnalysisReviewSheet({
    super.key,
    required this.initialDraft,
    required this.goals,
    required this.onSave,
    required this.title,
    required this.description,
    required this.saveLabel,
  });

  final ManualEntryDraft initialDraft;
  final NutritionGoal goals;
  final Future<void> Function(ManualEntryDraft draft) onSave;
  final String title;
  final String description;
  final String saveLabel;

  @override
  State<AiAnalysisReviewSheet> createState() => _AiAnalysisReviewSheetState();
}

class _AiAnalysisReviewSheetState extends State<AiAnalysisReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  late MealType _selectedMealType;
  late int _calories;
  late double _protein;
  late double _carbs;
  late double _fat;
  late double _fiber;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialDraft.mealType;
    _nameController.text = widget.initialDraft.name;
    _calories = widget.initialDraft.calories;
    _protein = widget.initialDraft.protein;
    _carbs = widget.initialDraft.carbs;
    _fat = widget.initialDraft.fat;
    _fiber = widget.initialDraft.fiber;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _supportsInlineImagePreview(String imagePath) {
    final normalizedPath = imagePath.toLowerCase();
    return !normalizedPath.endsWith('.heic') && !normalizedPath.endsWith('.heif');
  }

  void _adjustMacro(String type, double delta) {
    setState(() {
      if (type == 'protein') {
        _protein = (_protein + delta).clamp(0.0, 999.0);
        _calories = (_calories + (delta * 4).round()).clamp(0, 9999);
      } else if (type == 'carbs') {
        _carbs = (_carbs + delta).clamp(0.0, 999.0);
        _calories = (_calories + (delta * 4).round()).clamp(0, 9999);
      } else if (type == 'fat') {
        _fat = (_fat + delta).clamp(0.0, 999.0);
        _calories = (_calories + (delta * 9).round()).clamp(0, 9999);
      } else if (type == 'fiber') {
        _fiber = (_fiber + delta).clamp(0.0, 999.0);
      }
    });
  }

  Widget _buildGlassBadge(BuildContext context, double confidence) {
    final percentage = (confidence * 100).round();
    Color statusColor;
    String statusText;
    if (confidence >= 0.85) {
      statusColor = const Color(0xFF10B981); // Emerald
      statusText = 'Precisión Alta';
    } else if (confidence >= 0.6) {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusText = 'Precisión Media';
    } else {
      statusColor = const Color(0xFFEF4444); // Red
      statusText = 'Verificar';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$statusText ($percentage%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroBar(ThemeData theme) {
    // Calorías aportadas por cada macro
    final pCal = _protein * 4;
    final cCal = _carbs * 4;
    final fCal = _fat * 9;
    final totalCal = pCal + cCal + fCal;

    final pPct = totalCal > 0 ? (pCal / totalCal) : 0.0;
    final cPct = totalCal > 0 ? (cCal / totalCal) : 0.0;
    final fPct = totalCal > 0 ? (fCal / totalCal) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Distribución Calórica',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (totalCal > 0)
              Text(
                'P ${(pPct * 100).round()}% · C ${(cPct * 100).round()}% · G ${(fPct * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                if (pPct > 0)
                  Expanded(
                    flex: (pPct * 100).round(),
                    child: Container(color: const Color(0xFFEF4444)),
                  ),
                if (cPct > 0)
                  Expanded(
                    flex: (cPct * 100).round(),
                    child: Container(color: const Color(0xFF3B82F6)),
                  ),
                if (fPct > 0)
                  Expanded(
                    flex: (fPct * 100).round(),
                    child: Container(color: const Color(0xFFF59E0B)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard({
    required ThemeData theme,
    required String title,
    required double value,
    required double goalValue,
    required Color color,
    required IconData icon,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final pct = goalValue > 0 ? (value / goalValue) : 0.0;
    final pctText = (pct * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRoundButton(
                icon: Icons.remove,
                onTap: onDecrement,
                color: color,
              ),
              Text(
                '${value.toStringAsFixed(0)} g',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              _buildRoundButton(
                icon: Icons.add,
                onTap: onIncrement,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 6),
          Text(
            '$pctText% del objetivo diario (${goalValue.toStringAsFixed(0)} g)',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.08),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPreviewablePhoto =
        widget.initialDraft.hasPhoto &&
        _supportsInlineImagePreview(widget.initialDraft.imageUrl!);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre del bottom sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              if (widget.initialDraft.hasPhoto) ...[
                const SizedBox(height: 16),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: hasPreviewablePhoto
                          ? Image.file(
                              File(widget.initialDraft.imageUrl!),
                              height: 180,
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
                                    'La foto se cargó, pero no se puede previsualizar.',
                                    style: theme.textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: _buildGlassBadge(context, widget.initialDraft.confidence),
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.97, 0.97)),
              ],

              // Insights de la IA (assistantNote)
              if (widget.initialDraft.assistantNote != null &&
                  widget.initialDraft.assistantNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.08),
                        theme.colorScheme.tertiary.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                       .scale(end: const Offset(1.15, 1.15), duration: 1.seconds),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Análisis del Chef IA',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.initialDraft.assistantNote!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms).slide(begin: const Offset(0.05, 0), end: Offset.zero),
              ],

              const SizedBox(height: 18),
              
              // Nombre del alimento
              TextFormField(
                controller: _nameController,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nombre del alimento o plato',
                  prefixIcon: const Icon(Icons.abc_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ponle un nombre.';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Selector de Comida
              Text(
                'Comida del Día',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MealType.values.map((mealType) {
                    final isSelected = _selectedMealType == mealType;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          mealType.icon,
                          size: 16,
                          color: isSelected ? theme.colorScheme.onPrimary : mealType.accentColor,
                        ),
                        label: Text(mealType.label),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.onPrimary : null,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedMealType = mealType);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Calorías & Barra Macro
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          '$_calories',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildMacroBar(theme),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 18),

              // Grid de Steppers Macros
              Text(
                'Ajustar Macronutrientes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: [
                  _buildMacroCard(
                    theme: theme,
                    title: 'Proteína',
                    value: _protein,
                    goalValue: widget.goals.proteinGoal,
                    color: const Color(0xFFEF4444),
                    icon: Icons.bolt,
                    onDecrement: () => _adjustMacro('protein', -1),
                    onIncrement: () => _adjustMacro('protein', 1),
                  ),
                  _buildMacroCard(
                    theme: theme,
                    title: 'Carbos',
                    value: _carbs,
                    goalValue: widget.goals.carbsGoal,
                    color: const Color(0xFF3B82F6),
                    icon: Icons.grain,
                    onDecrement: () => _adjustMacro('carbs', -5),
                    onIncrement: () => _adjustMacro('carbs', 5),
                  ),
                  _buildMacroCard(
                    theme: theme,
                    title: 'Grasas',
                    value: _fat,
                    goalValue: widget.goals.fatGoal,
                    color: const Color(0xFFF59E0B),
                    icon: Icons.opacity,
                    onDecrement: () => _adjustMacro('fat', -1),
                    onIncrement: () => _adjustMacro('fat', 1),
                  ),
                  _buildMacroCard(
                    theme: theme,
                    title: 'Fibra',
                    value: _fiber,
                    goalValue: widget.goals.fiberGoal,
                    color: const Color(0xFF10B981),
                    icon: Icons.spa_outlined,
                    onDecrement: () => _adjustMacro('fiber', -1),
                    onIncrement: () => _adjustMacro('fiber', 1),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms).slide(begin: const Offset(0, 0.05), end: Offset.zero),

              const SizedBox(height: 24),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.check_circle_outline),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: Text(
                    _isSaving ? 'Guardando...' : widget.saveLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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

    if (_calories == 0 && _protein == 0 && _carbs == 0 && _fat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pon al menos calorías o macros para que el registro sirva.',
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
        calories: _calories,
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
        fiber: _fiber,
        imageUrl: widget.initialDraft.imageUrl,
        confidence: widget.initialDraft.confidence,
        assistantNote: widget.initialDraft.assistantNote,
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
