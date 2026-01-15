import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  /// 🔧 Initialisation (à appeler dans main)
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final uri = Uri.parse(response.payload!);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );

    // 🔔 Android 13+ permission
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  /// ⬆️ Notification de mise à jour (clic → sybauu.com)
  static Future<void> showUpdate() async {
    const androidDetails = AndroidNotificationDetails(
      'update_channel',
      'Mises à jour',
      channelDescription: 'Notification de mise à jour de l’application',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      999,
      "⬆️ Mise à jour disponible",
      "Une nouvelle version est prête. Appuie pour installer.",
      details,
      payload: "https://sybauu.com",
    );
  }
}
