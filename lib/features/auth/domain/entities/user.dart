/// User entity representing the authenticated user
class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? phoneNumber;
  final UserProfile profile;
  final UserSettings settings;
  final UserStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.phoneNumber,
    this.profile = const UserProfile(),
    this.settings = const UserSettings(),
    this.stats = const UserStats(),
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? phoneNumber,
    UserProfile? profile,
    UserSettings? settings,
    UserStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profile: profile ?? this.profile,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'phoneNumber': phoneNumber,
    'profile': profile.toJson(),
    'settings': settings.toJson(),
    'stats': stats.toJson(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    profile: json['profile'] != null
        ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
        : const UserProfile(),
    settings: json['settings'] != null
        ? UserSettings.fromJson(json['settings'] as Map<String, dynamic>)
        : const UserSettings(),
    stats: json['stats'] != null
        ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
        : const UserStats(),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    lastLoginAt: json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'] as String)
        : null,
  );
}

/// User profile with physical information
class UserProfile {
  final double? height; // cm
  final double? weight; // kg
  final DateTime? birthdate;
  final Gender gender;
  final ActivityLevel activityLevel;
  final FitnessGoal fitnessGoal;
  final double? targetWeight;
  final int? targetBodyFatPercentage;
  final String? medicalConditions;
  final String? allergies;

  const UserProfile({
    this.height,
    this.weight,
    this.birthdate,
    this.gender = Gender.notSpecified,
    this.activityLevel = ActivityLevel.moderate,
    this.fitnessGoal = FitnessGoal.maintain,
    this.targetWeight,
    this.targetBodyFatPercentage,
    this.medicalConditions,
    this.allergies,
  });

  Map<String, dynamic> toJson() => {
    'height': height,
    'weight': weight,
    'birthdate': birthdate?.toIso8601String(),
    'gender': gender.name,
    'activityLevel': activityLevel.name,
    'fitnessGoal': fitnessGoal.name,
    'targetWeight': targetWeight,
    'targetBodyFatPercentage': targetBodyFatPercentage,
    'medicalConditions': medicalConditions,
    'allergies': allergies,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    height: (json['height'] as num?)?.toDouble(),
    weight: (json['weight'] as num?)?.toDouble(),
    birthdate: json['birthdate'] != null
        ? DateTime.parse(json['birthdate'] as String)
        : null,
    gender: Gender.values.firstWhere(
      (g) => g.name == json['gender'],
      orElse: () => Gender.notSpecified,
    ),
    activityLevel: ActivityLevel.values.firstWhere(
      (a) => a.name == json['activityLevel'],
      orElse: () => ActivityLevel.moderate,
    ),
    fitnessGoal: FitnessGoal.values.firstWhere(
      (f) => f.name == json['fitnessGoal'],
      orElse: () => FitnessGoal.maintain,
    ),
    targetWeight: (json['targetWeight'] as num?)?.toDouble(),
    targetBodyFatPercentage: json['targetBodyFatPercentage'] as int?,
    medicalConditions: json['medicalConditions'] as String?,
    allergies: json['allergies'] as String?,
  );

  /// Calculate age from birthdate
  int? get age {
    if (birthdate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthdate!.year;
    if (now.month < birthdate!.month ||
        (now.month == birthdate!.month && now.day < birthdate!.day)) {
      age--;
    }
    return age;
  }

  /// Calculate BMR using Mifflin-St Jeor equation
  double? get bmr {
    if (weight == null || height == null || age == null) return null;
    switch (gender) {
      case Gender.male:
        return (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
      case Gender.female:
        return (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
      default:
        // Average of male and female
        final male = (10 * weight!) + (6.25 * height!) - (5 * age!) + 5;
        final female = (10 * weight!) + (6.25 * height!) - (5 * age!) - 161;
        return (male + female) / 2;
    }
  }

  /// Calculate TDEE (Total Daily Energy Expenditure)
  double? get tdee {
    if (bmr == null) return null;
    return bmr! * activityLevel.multiplier;
  }
}

/// User app settings
class UserSettings {
  final ThemeModeApp themeMode;
  final String language;
  final MeasurementSystem measurementSystem;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool hapticFeedback;
  final bool autoSyncWearables;
  final bool shareDataWithAI;
  final String preferredAIModel;

  const UserSettings({
    this.themeMode = ThemeModeApp.system,
    this.language = 'es',
    this.measurementSystem = MeasurementSystem.metric,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.hapticFeedback = true,
    this.autoSyncWearables = true,
    this.shareDataWithAI = false,
    this.preferredAIModel = 'kilo/auto',
  });

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'language': language,
    'measurementSystem': measurementSystem.name,
    'notificationsEnabled': notificationsEnabled,
    'soundEnabled': soundEnabled,
    'hapticFeedback': hapticFeedback,
    'autoSyncWearables': autoSyncWearables,
    'shareDataWithAI': shareDataWithAI,
    'preferredAIModel': preferredAIModel,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    themeMode: ThemeModeApp.values.firstWhere(
      (t) => t.name == json['themeMode'],
      orElse: () => ThemeModeApp.system,
    ),
    language: json['language'] as String? ?? 'es',
    measurementSystem: MeasurementSystem.values.firstWhere(
      (m) => m.name == json['measurementSystem'],
      orElse: () => MeasurementSystem.metric,
    ),
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    hapticFeedback: json['hapticFeedback'] as bool? ?? true,
    autoSyncWearables: json['autoSyncWearables'] as bool? ?? true,
    shareDataWithAI: json['shareDataWithAI'] as bool? ?? false,
    preferredAIModel: json['preferredAIModel'] as String? ?? 'kilo/auto',
  );
}

/// User statistics (denormalized for quick access)
class UserStats {
  final int totalWorkouts;
  final int totalExercises;
  final int totalHabitsCompleted;
  final int currentStreak;
  final int longestStreak;
  final int totalPoints;
  final int level;
  final DateTime? lastWorkoutDate;
  final DateTime? lastHabitDate;

  const UserStats({
    this.totalWorkouts = 0,
    this.totalExercises = 0,
    this.totalHabitsCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalPoints = 0,
    this.level = 1,
    this.lastWorkoutDate,
    this.lastHabitDate,
  });

  Map<String, dynamic> toJson() => {
    'totalWorkouts': totalWorkouts,
    'totalExercises': totalExercises,
    'totalHabitsCompleted': totalHabitsCompleted,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalPoints': totalPoints,
    'level': level,
    'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
    'lastHabitDate': lastHabitDate?.toIso8601String(),
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    totalWorkouts: json['totalWorkouts'] as int? ?? 0,
    totalExercises: json['totalExercises'] as int? ?? 0,
    totalHabitsCompleted: json['totalHabitsCompleted'] as int? ?? 0,
    currentStreak: json['currentStreak'] as int? ?? 0,
    longestStreak: json['longestStreak'] as int? ?? 0,
    totalPoints: json['totalPoints'] as int? ?? 0,
    level: json['level'] as int? ?? 1,
    lastWorkoutDate: json['lastWorkoutDate'] != null
        ? DateTime.parse(json['lastWorkoutDate'] as String)
        : null,
    lastHabitDate: json['lastHabitDate'] != null
        ? DateTime.parse(json['lastHabitDate'] as String)
        : null,
  );

  /// XP needed for next level (1000 XP per level)
  int get xpForNextLevel => ((level) * 1000) - totalPoints;

  /// Progress to next level (0.0 - 1.0)
  double get levelProgress {
    final currentLevelXP = (level - 1) * 1000;
    final nextLevelXP = level * 1000;
    if (nextLevelXP == currentLevelXP) return 1.0;
    return (totalPoints - currentLevelXP) / (nextLevelXP - currentLevelXP);
  }
}

// ==================== Enums ====================

enum Gender { male, female, other, notSpecified }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum FitnessGoal {
  loseWeight,
  maintain,
  gainMuscle,
  improveEndurance,
  improveFlexibility,
  generalHealth,
}

enum MeasurementSystem { metric, imperial }

enum ThemeModeApp { system, light, dark }

// ==================== Extensions ====================

extension ActivityLevelX on ActivityLevel {
  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentario';
      case ActivityLevel.light:
        return 'Ligero';
      case ActivityLevel.moderate:
        return 'Moderado';
      case ActivityLevel.active:
        return 'Activo';
      case ActivityLevel.veryActive:
        return 'Muy activo';
    }
  }
}

extension FitnessGoalX on FitnessGoal {
  String get label {
    switch (this) {
      case FitnessGoal.loseWeight:
        return 'Perder peso';
      case FitnessGoal.maintain:
        return 'Mantener';
      case FitnessGoal.gainMuscle:
        return 'Ganar músculo';
      case FitnessGoal.improveEndurance:
        return 'Mejorar resistencia';
      case FitnessGoal.improveFlexibility:
        return 'Mejorar flexibilidad';
      case FitnessGoal.generalHealth:
        return 'Salud general';
    }
  }
}

extension GenderX on Gender {
  String get label {
    switch (this) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Femenino';
      case Gender.other:
        return 'Otro';
      case Gender.notSpecified:
        return 'No especificado';
    }
  }
}
