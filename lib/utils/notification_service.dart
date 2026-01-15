import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final uri = Uri.parse(response.payload!);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  /* ===================== 🔔 MISE À JOUR ===================== */

  static Future<void> showUpdate() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'update_channel',
        'Mises à jour',
        channelDescription: 'Notification de mise à jour de l’application',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      999,
      "⬆️ Mise à jour disponible",
      "Une nouvelle version est prête. Appuie pour installer.",
      details,
      payload: "https://sybauu.com",
    );
  }

  /* ===================== 📖 VERSET 09H ===================== */

  static Future<void> scheduleDailyVerse() async {
    await _plugin.zonedSchedule(
      101,
      "📖 Verset du jour",
      "Découvre le verset du jour",
      _nextInstance(hour: 9),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'verse_channel',
          'Verset du jour',
          channelDescription: 'Notification quotidienne – verset',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /* ===================== 🕌 HADITH 18H ===================== */

  static Future<void> scheduleDailyHadith() async {
    await _plugin.zonedSchedule(
      102,
      "🕌 Hadith du jour",
      "Lis le hadith du jour",
      _nextInstance(hour: 18),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'hadith_channel',
          'Hadith du jour',
          channelDescription: 'Notification quotidienne – hadith',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /* ===================== ⏰ UTILS ===================== */

  static tz.TZDateTime _nextInstance({required int hour}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
