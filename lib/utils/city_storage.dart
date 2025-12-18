import 'package:shared_preferences/shared_preferences.dart';

class CityStorage {
  static const _key = "selected_city";

  static Future<void> save(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, city);
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
