import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi notifikasi
  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings);
  }

  /// Jadwal pengingat harian
  static Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1001,
      'CashQ',
      'Jangan lupa catat pengeluaran hari ini!',
      schedule,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cashq_daily',
          'Daily Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Tampilkan notifikasi sekali (misalnya alert budget)
  static Future<void> showBudgetAlert(String message) async {
    await _plugin.show(
      2001,
      'Peringatan Budget',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cashq_alerts',
          'Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
