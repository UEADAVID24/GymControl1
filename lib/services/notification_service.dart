import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final TimezoneInfo currentTimeZone =
          await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(
        tz.getLocation(currentTimeZone.identifier),
      );
    } catch (_) {
      // Zona horaria de Ecuador continental.
      tz.setLocalLocation(
        tz.getLocation('America/Guayaquil'),
      );
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    // Semana 14:
    // El permiso de notificaciones NO se solicita al iniciar la app.
    // Se solicitará únicamente cuando el usuario utilice
    // la funcionalidad de recordatorios.
  }

  Future<bool> requestNotificationPermission() async {
    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      return true;
    }

    final granted =
        await androidImplementation.requestNotificationsPermission();

    return granted ?? false;
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'gymcontrol_recordatorios',
      'Recordatorios GymControl',
      channelDescription:
          'Notificaciones de rutinas y entrenamientos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    await cancelNotification(id);

    final scheduledDate = _nextWeeklyDate(
      dayOfWeek: dayOfWeek,
      hour: hour,
      minute: minute,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'gymcontrol_recordatorios',
      'Recordatorios GymControl',
      channelDescription:
          'Notificaciones semanales de entrenamiento',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body.isEmpty
          ? 'Es momento de realizar tu entrenamiento.'
          : body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime,
      payload: 'recordatorio_$id',
    );
  }

  tz.TZDateTime _nextWeeklyDate({
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek ||
        !scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 1),
      );
    }

    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(
      id: id,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}