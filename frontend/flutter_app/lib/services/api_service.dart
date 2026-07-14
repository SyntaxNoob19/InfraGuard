import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/app_state.dart';

/// REST client for the InfraGuard FastAPI backend.
/// Supports both direct localhost and ngrok tunnels.
class ApiService {
  static const String baseUrl =
      'https://your-ngrok-url.ngrok-free.dev';
  static const String apiKey = 'YOUR_API_KEY_HERE';

  /// Common headers — includes the ngrok browser-warning bypass header
  /// so the app does not receive the ngrok interstitial HTML page.
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'ngrok-skip-browser-warning': 'true',
      };

  static const Duration _timeout = Duration(seconds: 8);

  Future<AppStateModel?> fetchStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/status'), headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        return AppStateModel.fromJson(decoded);
      }

      developer.log(
        '[ApiService] fetchStatus failed: HTTP ${response.statusCode}',
        name: 'InfraGuard',
      );
      return null;
    } on Exception catch (e) {
      developer.log(
        '[ApiService] fetchStatus error: $e',
        name: 'InfraGuard',
      );
      return null;
    }
  }

  Future<bool> resolveIncident(String incidentId, String action) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/resolve'),
            headers: _headers,
            body: json.encode({'incident_id': incidentId, 'action': action}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) return true;

      developer.log(
        '[ApiService] resolveIncident failed: HTTP ${response.statusCode} — ${response.body}',
        name: 'InfraGuard',
      );
      return false;
    } on Exception catch (e) {
      developer.log(
        '[ApiService] resolveIncident error: $e',
        name: 'InfraGuard',
      );
      return false;
    }
  }
}
