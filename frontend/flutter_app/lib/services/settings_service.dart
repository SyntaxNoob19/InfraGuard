import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _baseUrlKey = 'api_base_url';
  
  // Default to ngrok tunnel for hackathon
  static const String _defaultBaseUrl = 'https://flying-resemble-canopener.ngrok-free.dev';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String get baseUrl {
    return _prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    // Basic cleanup: remove trailing slash if present
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    await _prefs.setString(_baseUrlKey, url);
  }
}
