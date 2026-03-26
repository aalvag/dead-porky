import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dead_porky/features/auth/presentation/screens/login_screen.dart';
import 'package:dead_porky/features/auth/presentation/screens/register_screen.dart';
import 'package:dead_porky/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:dead_porky/features/auth/presentation/providers/auth_provider.dart';
import 'package:dead_porky/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:dead_porky/features/exercises/presentation/screens/exercise_list_screen.dart';
import 'package:dead_porky/features/exercises/presentation/screens/active_workout_screen.dart';

// ==================== Route Names ====================
abstract class AppRoutes {
  // Auth
  static const String login = 'login';
  static const String register = 'register';
  static const String onboarding = 'onboarding';

  // Main Shell
  static const String dashboard = 'dashboard';
  static const String exercises = 'exercises';
  static const String habits = 'habits';
  static const String health = 'health';
  static const String settings = 'settings';

  // Exercises
  static const String exerciseDetail = 'exercise-detail';
  static const String activeWorkout = 'active-workout';
  static const String workoutHistory = 'workout-history';
  static const String workoutTemplates = 'workout-templates';

  // Habits
  static const String habitDetail = 'habit-detail';
  static const String habitForm = 'habit-form';

  // Wearable
  static const String deviceScanner = 'device-scanner';
  static const String devicePairing = 'device-pairing';

  // AI
  static const String aiChat = 'ai-chat';

  // Reports
  static const String weeklyReport = 'weekly-report';
  static const String monthlyReport = 'monthly-report';

  // Misc
  static const String profile = 'profile';
}

// ==================== Onboarding State ====================
final hasCompletedOnboardingProvider = StateProvider<bool>((ref) => false);

// ==================== Router Provider ====================
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final isAuthenticated = authState.isAuthenticated;
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      // Not authenticated and not on auth route -> redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      // Authenticated but hasn't completed onboarding
      if (isAuthenticated && !hasCompletedOnboarding && !isOnboardingRoute) {
        return '/onboarding';
      }

      // Authenticated and on auth route -> redirect to dashboard
      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ==================== Auth Routes ====================
      GoRoute(
        path: '/auth/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        name: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ==================== Onboarding ====================
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ==================== Main Shell ====================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Exercises
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exercises',
                name: AppRoutes.exercises,
                builder: (context, state) => const ExerciseListScreen(),
                routes: [
                  GoRoute(
                    path: 'active-workout',
                    name: AppRoutes.activeWorkout,
                    builder: (context, state) => const ActiveWorkoutScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Habits
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                name: AppRoutes.habits,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Hábitos'),
              ),
            ],
          ),
          // Health
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health',
                name: AppRoutes.health,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Salud'),
              ),
            ],
          ),
          // Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: AppRoutes.settings,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Ajustes'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ==================== Main Shell with Navigation ====================
class _MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Ejercicios',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Hábitos',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Salud',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

// ==================== Placeholder Screen ====================
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '$title\n(Pendiente de implementar)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
