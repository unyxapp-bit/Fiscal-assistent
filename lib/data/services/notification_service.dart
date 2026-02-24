import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Serviço de notificações locais para alertas de pausa e escala.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const _androidChannel = AndroidNotificationDetails(
    'fiscal_alerts',
    'Alertas CISS',
    channelDescription: 'Alertas de pausa e escala do CISS Fiscal Assistant',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  static const _notifDetails = NotificationDetails(
    android: _androidChannel,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Exibe uma notificação imediata.
  Future<void> showImmediateAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.show(id, title, body, _notifDetails);
  }

  /// Agenda uma notificação para um horário futuro.
  Future<void> scheduleAlert({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (!_initialized) await initialize();
    final scheduled = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela uma notificação agendada pelo id.
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancela todas as notificações pendentes.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
