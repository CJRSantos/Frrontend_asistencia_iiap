import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/birthday_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);

    // Solicitar permiso en Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // Notificación instantánea
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'iiap_asistencia_channel',
      'Asistencia IIAP',
      channelDescription: 'Canal de notificaciones y recordatorios del IIAP',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Notificación para recordar marcación
  static Future<void> notifyAttendanceReminder({
    required String shiftName,
    required bool isCheckIn,
  }) async {
    final typeStr = isCheckIn ? 'Ingreso' : 'Salida';
    final actionStr = isCheckIn ? 'marcar tu entrada' : 'marcar tu salida';
    
    await showNotification(
      id: isCheckIn ? 101 : 102,
      title: '⏰ Recordatorio de $typeStr ($shiftName)',
      body: 'Recuerda $actionStr en la Sede Central del IIAP.',
    );
  }

  // Notificación matutina de cumpleaños de compañeros
  static Future<void> checkAndNotifyBirthdays(List<BirthdayModel> todayBirthdays) async {
    if (todayBirthdays.isEmpty) return;

    final names = todayBirthdays.map((b) => b.fullName).join(', ');
    await showNotification(
      id: 201,
      title: '🎂 ¡Cumpleaños hoy en el IIAP!',
      body: 'Hoy celebra su día: $names. ¡No olvides felicitarlo!',
    );
  }
}
