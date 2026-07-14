import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_state.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String apiKey = 'hackathon-secret-key';

  Future<AppStateModel?> fetchStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/status'));
      if (response.statusCode == 200) {
        return AppStateModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> resolveIncident(String incidentId, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/resolve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({'incident_id': incidentId, 'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
