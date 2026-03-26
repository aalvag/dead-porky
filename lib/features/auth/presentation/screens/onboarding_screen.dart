import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dead_porky/features/auth/domain/entities/user.dart';
import 'package:dead_porky/core/router/app_router.dart';

/// Onboarding page model
class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form state
  double? _height;
  double? _weight;
  DateTime? _birthdate;
  Gender _gender = Gender.notSpecified;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  FitnessGoal _fitnessGoal = FitnessGoal.maintain;

  final List<_OnboardingPage> _pages = [
    const _OnboardingPage(
      title: 'Bienvenido a Dead Porky',
      description:
          'Tu asistente personal de salud, ejercicio y bienestar. Vamos a personalizar tu experiencia.',
      icon: Icons.fitness_center,
      color: Color(0xFF6366F1),
    ),
    const _OnboardingPage(
      title: 'Perfil Físico',
      description:
          'Necesitamos algunos datos para calcular tus métricas personalizadas.',
      icon: Icons.person,
      color: Color(0xFF10B981),
    ),
    const _OnboardingPage(
      title: 'Tu Estilo de Vida',
      description:
          'Cuéntanos sobre tu nivel de actividad para ajustar las recomendaciones.',
      icon: Icons.directions_run,
      color: Color(0xFFF59E0B),
    ),
    const _OnboardingPage(
      title: 'Tus Objetivos',
      description: '¿Qué quieres lograr? Te ayudaremos a llegar ahí.',
      icon: Icons.track_changes,
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // TODO: Save profile data to Firestore
    // ref.read(authNotifierProvider.notifier).updateProfile(...);

    // Mark onboarding as completed
    ref.read(hasCompletedOnboardingProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: List.generate(
                  _pages.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(index);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  FilledButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Comenzar'
                          : 'Siguiente',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    final page = _pages[index];
    final theme = Theme.of(context);

    switch (index) {
      case 0:
        return _buildWelcomePage(page, theme);
      case 1:
        return _buildProfilePage(page, theme);
      case 2:
        return _buildActivityPage(page, theme);
      case 3:
        return _buildGoalsPage(page, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomePage(_OnboardingPage page, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 120, color: page.color),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(_OnboardingPage page, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(page.icon, size: 64, color: page.color),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(page.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Height
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura (cm)',
              prefixIcon: Icon(Icons.height),
              hintText: '175',
            ),
            onChanged: (value) {
              _height = double.tryParse(value);
            },
          ),
          const SizedBox(height: 16),

          // Weight
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
              hintText: '75',
            ),
            onChanged: (value) {
              _weight = double.tryParse(value);
            },
          ),
          const SizedBox(height: 16),

          // Birthdate
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: Text(
              _birthdate != null
                  ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year}'
                  : 'Fecha de nacimiento',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(1990),
                firstDate: DateTime(1940),
                lastDate: DateTime.now().subtract(
                  const Duration(days: 365 * 13),
                ),
              );
              if (date != null) {
                setState(() {
                  _birthdate = date;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Gender
          Text('Género', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<Gender>(
            segments: const [
              ButtonSegment(value: Gender.male, label: Text('M')),
              ButtonSegment(value: Gender.female, label: Text('F')),
              ButtonSegment(value: Gender.other, label: Text('Otro')),
            ],
            selected: {_gender},
            onSelectionChanged: (selected) {
              setState(() {
                _gender = selected.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage(_OnboardingPage page, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(page.icon, size: 64, color: page.color),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(page.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Activity level cards
          ...ActivityLevel.values.map((level) {
            final isSelected = _activityLevel == level;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                color: isSelected ? theme.colorScheme.primaryContainer : null,
                child: ListTile(
                  leading: Icon(
                    _getActivityIcon(level),
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                  title: Text(
                    level.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_getActivityDescription(level)),
                  onTap: () {
                    setState(() {
                      _activityLevel = level;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalsPage(_OnboardingPage page, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(page.icon, size: 64, color: page.color),
          const SizedBox(height: 16),
          Text(
            page.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(page.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Goal cards
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FitnessGoal.values.map((goal) {
              final isSelected = _fitnessGoal == goal;
              return ChoiceChip(
                label: Text(goal.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _fitnessGoal = goal;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Selected goal description
          if (_fitnessGoal != FitnessGoal.maintain)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu objetivo:', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(
                      _fitnessGoal.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_fitnessGoal.label),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return Icons.weekend;
      case ActivityLevel.light:
        return Icons.directions_walk;
      case ActivityLevel.moderate:
        return Icons.directions_run;
      case ActivityLevel.active:
        return Icons.sports;
      case ActivityLevel.veryActive:
        return Icons.local_fire_department;
    }
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Trabajo de oficina, poco movimiento';
      case ActivityLevel.light:
        return 'Caminatas ocasionales, 1-3 días de ejercicio';
      case ActivityLevel.moderate:
        return 'Ejercicio regular, 3-5 días por semana';
      case ActivityLevel.active:
        return 'Ejercicio intenso, 6-7 días por semana';
      case ActivityLevel.veryActive:
        return 'Atleta o trabajo físico exigente';
    }
  }
}
