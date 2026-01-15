import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'notification_service.dart';

class UpdateChecker {
  static const String url = "https://sybauu.com/version.json";

  static Future<void> check() async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final remote = data["version_code"];

      final info = await PackageInfo.fromPlatform();
      final local = int.parse(info.buildNumber);

      if (remote > local) {
        NotificationService.showUpdate();
      }
    } catch (_) {}
  }
}
