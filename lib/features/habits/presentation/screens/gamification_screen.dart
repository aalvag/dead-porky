import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================== Gamification Entities ====================

class UserBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final BadgeRarity rarity;
  final int requiredValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.requiredValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });
}

enum BadgeRarity { common, rare, epic, legendary }

extension BadgeRarityX on BadgeRarity {
  Color get color {
    switch (this) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }

  String get label {
    switch (this) {
      case BadgeRarity.common:
        return 'Común';
      case BadgeRarity.rare:
        return 'Raro';
      case BadgeRarity.epic:
        return 'Épico';
      case BadgeRarity.legendary:
        return 'Legendario';
    }
  }
}

// ==================== Preset Badges ====================

class PresetBadges {
  static final List<UserBadge> badges = [
    // Streaks
    const UserBadge(
      id: 'streak_7',
      name: 'Semana Perfecta',
      description: '7 días de racha',
      emoji: '🔥',
      rarity: BadgeRarity.common,
      requiredValue: 7,
    ),
    const UserBadge(
      id: 'streak_30',
      name: 'Mes Imparable',
      description: '30 días de racha',
      emoji: '⚡',
      rarity: BadgeRarity.rare,
      requiredValue: 30,
    ),
    const UserBadge(
      id: 'streak_100',
      name: 'Centurión',
      description: '100 días de racha',
      emoji: '🏆',
      rarity: BadgeRarity.epic,
      requiredValue: 100,
    ),
    const UserBadge(
      id: 'streak_365',
      name: 'Año Completo',
      description: '365 días de racha',
      emoji: '👑',
      rarity: BadgeRarity.legendary,
      requiredValue: 365,
    ),

    // Workouts
    const UserBadge(
      id: 'workout_1',
      name: 'Primer Entreno',
      description: 'Completa tu primer entrenamiento',
      emoji: '💪',
      rarity: BadgeRarity.common,
      requiredValue: 1,
    ),
    const UserBadge(
      id: 'workout_10',
      name: 'Constante',
      description: '10 entrenamientos',
      emoji: '🏋️',
      rarity: BadgeRarity.common,
      requiredValue: 10,
    ),
    const UserBadge(
      id: 'workout_50',
      name: 'Atleta',
      description: '50 entrenamientos',
      emoji: '🥇',
      rarity: BadgeRarity.rare,
      requiredValue: 50,
    ),
    const UserBadge(
      id: 'workout_100',
      name: 'Bestia',
      description: '100 entrenamientos',
      emoji: '🦁',
      rarity: BadgeRarity.epic,
      requiredValue: 100,
    ),

    // Habits
    const UserBadge(
      id: 'habits_50',
      name: 'Hábitos Saludables',
      description: '50 hábitos completados',
      emoji: '✅',
      rarity: BadgeRarity.common,
      requiredValue: 50,
    ),
    const UserBadge(
      id: 'habits_200',
      name: 'Disciplinado',
      description: '200 hábitos completados',
      emoji: '🎯',
      rarity: BadgeRarity.rare,
      requiredValue: 200,
    ),
    const UserBadge(
      id: 'habits_500',
      name: 'Maestro de Hábitos',
      description: '500 hábitos completados',
      emoji: '🌟',
      rarity: BadgeRarity.epic,
      requiredValue: 500,
    ),

    // Volume
    const UserBadge(
      id: 'volume_10k',
      name: '10 Toneladas',
      description: '10,000 kg de volumen total',
      emoji: '📦',
      rarity: BadgeRarity.common,
      requiredValue: 10000,
    ),
    const UserBadge(
      id: 'volume_100k',
      name: '100 Toneladas',
      description: '100,000 kg de volumen total',
      emoji: '🚛',
      rarity: BadgeRarity.rare,
      requiredValue: 100000,
    ),

    // Special
    const UserBadge(
      id: 'early_bird',
      name: 'Madrugador',
      description: 'Entrena antes de las 7am',
      emoji: '🌅',
      rarity: BadgeRarity.rare,
      requiredValue: 1,
    ),
    const UserBadge(
      id: 'night_owl',
      name: 'Búho Nocturno',
      description: 'Entrena después de las 10pm',
      emoji: '🦉',
      rarity: BadgeRarity.rare,
      requiredValue: 1,
    ),
    const UserBadge(
      id: 'iron_will',
      name: 'Voluntad de Hierro',
      description: 'Nunca fallar un hábito en 30 días',
      emoji: '🦾',
      rarity: BadgeRarity.legendary,
      requiredValue: 30,
    ),
  ];
}

// ==================== Gamification Screen ====================

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Mock user stats
    const totalPoints = 4850;
    const level = 5;
    const currentStreak = 12;
    const unlockedBadges = 6;

    return Scaffold(
      appBar: AppBar(title: const Text('Logros y Progreso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Level badge
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nivel $level',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalPoints XP acumulados',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.65,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '150 XP para nivel ${level + 1}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.local_fire_department,
                    value: '$currentStreak',
                    label: 'Días de racha',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.emoji_events,
                    value: '$unlockedBadges/${PresetBadges.badges.length}',
                    label: 'Logros',
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.star,
                    value: '$totalPoints',
                    label: 'Puntos',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Badges section
            Text(
              'Logros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Badges grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: PresetBadges.badges.length,
              itemBuilder: (context, index) {
                final badge = PresetBadges.badges[index];
                final isUnlocked = index < unlockedBadges; // Mock
                return _BadgeCard(badge: badge, isUnlocked: isUnlocked);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Widgets ====================

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final UserBadge badge;
  final bool isUnlocked;

  const _BadgeCard({required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isUnlocked
          ? badge.rarity.color.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.emoji,
              style: TextStyle(
                fontSize: 32,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isUnlocked ? null : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badge.rarity.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge.rarity.label,
                style: TextStyle(
                  fontSize: 9,
                  color: badge.rarity.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
