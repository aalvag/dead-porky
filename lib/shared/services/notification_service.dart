import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Notification Service for local and push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Navigate based on payload
    }
  }

  /// Request permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dead_porky_channel',
      'Dead Porky',
      channelDescription: 'Notificaciones de Dead Porky',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dead_porky_scheduled',
      'Dead Porky Programadas',
      channelDescription: 'Notificaciones programadas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule daily habit reminder
  Future<void> scheduleHabitReminder({
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    final id = habitName.hashCode;

    await _plugin.zonedSchedule(
      id,
      'Recordatorio: $habitName',
      'No olvides completar tu hábito hoy',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dead_porky_habits',
          'Recordatorios de Hábitos',
          channelDescription: 'Recordatorios diarios',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'habit_$habitName',
    );
  }

  /// Schedule rest timer notification
  Future<void> scheduleRestTimer({required int seconds}) async {
    final scheduledDate = DateTime.now().add(Duration(seconds: seconds));

    await showNotification(
      id: 9999,
      title: '¡Descanso terminado!',
      body: 'Es hora de la siguiente serie 💪',
      payload: 'rest_timer',
    );
  }

  /// Schedule workout reminder
  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      1000,
      '¡Hora de entrenar! 💪',
      'No olvides tu entrenamiento de hoy',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dead_porky_workouts',
          'Recordatorios de Entrenamiento',
          channelDescription: 'Recordatorios de ejercicio',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'workout_reminder',
    );
  }

  /// Schedule water reminder
  Future<void> scheduleWaterReminder({int intervalHours = 2}) async {
    for (int i = 0; i < 8; i++) {
      final scheduledDate = DateTime.now().add(
        Duration(hours: intervalHours * (i + 1)),
      );
      if (scheduledDate.hour >= 7 && scheduledDate.hour <= 22) {
        await scheduleNotification(
          id: 2000 + i,
          title: '💧 Hidratación',
          body: 'Recuerda beber agua',
          scheduledDate: scheduledDate,
        );
      }
    }
  }

  /// Get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Cancel notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
