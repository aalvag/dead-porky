// ==================== App Constants ====================
abstract class AppConstants {
  // App Info
  static const String appName = 'Dead Porky';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String exercisesCollection = 'exercises';
  static const String habitsCollection = 'habits';
  static const String workoutsCollection = 'workouts';
  static const String healthMetricsCollection = 'health_metrics';
  static const String devicesCollection = 'devices';
  static const String chatsCollection = 'chats';

  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';

  // BLE Service UUIDs
  static const String heartRateService = '0000180d-0000-1000-8000-00805f9b34fb';
  static const String heartRateMeasurement =
      '00002a37-0000-1000-8000-00805f9b34fb';
  static const String glucoseService = '00001808-0000-1000-8000-00805f9b34fb';
  static const String weightScaleService =
      '0000181d-0000-1000-8000-00805f9b34fb';
  static const String bloodPressureService =
      '00001810-0000-1000-8000-00805f9b34fb';
  static const String bodyCompositionService =
      '0000181b-0000-1000-8000-00805f9b34fb';

  // Kilo Gateway
  static const String kiloGatewayUrl = 'https://api.kilo.ai/api/gateway';
  static const String kiloDefaultModel = 'kilo/auto';

  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int bleScanTimeoutSeconds = 15;
  static const int bleConnectTimeoutSeconds = 20;

  // Limits
  static const int maxHabitsPerUser = 20;
  static const int maxWorkoutExercises = 15;
  static const int maxWorkoutSets = 10;
  static const int maxChatHistory = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Gamification
  static const int pointsPerHabitComplete = 10;
  static const int pointsPerWorkoutComplete = 50;
  static const int pointsPerStreakDay = 5;
  static const int streakBonusMultiplier = 2;
}

// ==================== App Strings ====================
// TODO: Move to ARB files for localization
abstract class AppStrings {
  // Auth
  static const String login = 'Iniciar Sesión';
  static const String register = 'Registrarse';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String confirmPassword = 'Confirmar Contraseña';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';

  // Navigation
  static const String home = 'Inicio';
  static const String exercises = 'Ejercicios';
  static const String habits = 'Hábitos';
  static const String health = 'Salud';
  static const String settings = 'Ajustes';

  // Common
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String add = 'Agregar';
  static const String search = 'Buscar';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String success = 'Éxito';
  static const String retry = 'Reintentar';
  static const String noData = 'Sin datos';
  static const String offline = 'Sin conexión';

  // Errors
  static const String errorGeneric = 'Ha ocurrido un error';
  static const String errorNetwork = 'Error de conexión';
  static const String errorAuth = 'Error de autenticación';
  static const String errorNotFound = 'No encontrado';
}
