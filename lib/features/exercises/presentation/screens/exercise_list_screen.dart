import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/exercises/data/exercise_library.dart';

/// Search query provider
final exerciseSearchProvider = StateProvider<String>((ref) => '');

/// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchQuery = ref.watch(exerciseSearchProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    // Filter exercises
    var exercises = ExerciseLibrary.exercises;
    if (searchQuery.isNotEmpty) {
      exercises = ExerciseLibrary.search(searchQuery);
    } else if (selectedCategory != null) {
      exercises = ExerciseLibrary.getByCategory(selectedCategory);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ejercicios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(exerciseSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(exerciseSearchProvider.notifier).state = value;
              },
            ),
          ),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ExerciseLibrary.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: selectedCategory == null && searchQuery.isEmpty,
                      onSelected: (selected) {
                        ref.read(selectedCategoryProvider.notifier).state =
                            null;
                        ref.read(exerciseSearchProvider.notifier).state = '';
                        _searchController.clear();
                      },
                    ),
                  );
                }
                final category = ExerciseLibrary.categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ExerciseLibrary.getCategoryIcon(category)),
                        const SizedBox(width: 4),
                        Text(ExerciseLibrary.getCategoryName(category)),
                      ],
                    ),
                    selected: selectedCategory == category,
                    onSelected: (selected) {
                      ref.read(selectedCategoryProvider.notifier).state =
                          selected ? category : null;
                      ref.read(exerciseSearchProvider.notifier).state = '';
                      _searchController.clear();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Exercise count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${exercises.length} ejercicios',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return _ExerciseCard(
                  exercise: exercise,
                  onTap: () {
                    _showExerciseDetail(context, exercise);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              // TODO: Add filter options (equipment, difficulty, muscle group)
              Text('Próximamente: filtros avanzados'),
            ],
          ),
        );
      },
    );
  }

  void _showExerciseDetail(
    BuildContext context,
    Map<String, dynamic> exercise,
  ) {
    final theme = Theme.of(context);

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
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    exercise['name'],
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    exercise['nameEn'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Text(
                          ExerciseLibrary.getCategoryIcon(exercise['category']),
                        ),
                        label: Text(
                          ExerciseLibrary.getCategoryName(exercise['category']),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.fitness_center, size: 16),
                        label: Text(
                          ExerciseLibrary.getEquipmentName(
                            exercise['equipment'],
                          ),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.signal_cellular_alt, size: 16),
                        label: Text('Nivel ${exercise['difficulty']}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Muscles
                  Text(
                    'Músculos trabajados',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (exercise['muscleGroups'] as List)
                        .map((m) => Chip(label: Text(m.toString())))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // Instructions
                  Text(
                    'Instrucciones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exercise['instructions'],
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.history),
                          label: const Text('Ver historial'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Navigate to active workout with this exercise
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Agregar a rutina'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            ExerciseLibrary.getCategoryIcon(exercise['category']),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          exercise['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${ExerciseLibrary.getCategoryName(exercise['category'])} · ${ExerciseLibrary.getEquipmentName(exercise['equipment'])}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            exercise['difficulty'],
            (index) =>
                Icon(Icons.star, size: 14, color: theme.colorScheme.primary),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
