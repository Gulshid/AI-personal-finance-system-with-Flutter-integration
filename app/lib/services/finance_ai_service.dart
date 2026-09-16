// lib/services/finance_ai_service.dart
//
// Dart service class for calling the AI Personal Finance API from Flutter.
// Add to pubspec.yaml:  http: ^1.2.0
//
// IMPORTANT — base URL depends on where your API runs relative to the app:
//   - Android emulator:  http://10.0.2.2:8000       (special alias to host machine)
//   - iOS simulator:     http://localhost:8000       (works directly)
//   - Physical device:   http://<your-computer-LAN-IP>:8000   (e.g. http://192.168.1.20:8000)
//   - Deployed API:      https://your-deployed-domain.com
//
// Find your LAN IP with `ipconfig` (Windows) or `ifconfig`/`ip a` (Mac/Linux).
// Physical device and computer must be on the same Wi-Fi network.

import 'dart:convert';
import 'package:http/http.dart' as http;

class FinanceAiService {
  final String baseUrl;

  FinanceAiService({required this.baseUrl});

  Future<Map<String, dynamic>> predictCategory({
    required String merchant,
    required double amount,
    required String paymentMethod,
    String? date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict-category'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merchant': merchant,
        'amount': amount,
        'payment_method': paymentMethod,
        if (date != null) 'date': date,
      }),
    );
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkAnomaly({
    required int userId,
    required String category,
    required String merchant,
    required double amount,
    String? date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/check-anomaly'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'category': category,
        'merchant': merchant,
        'amount': amount,
        if (date != null) 'date': date,
      }),
    );
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUserCluster(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId/cluster'));
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUserForecast(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId/forecast'));
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getUserRecommendations(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$userId/recommendations'));
    _checkResponse(response);
    return jsonDecode(response.body);
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}

/* ---------------- Example usage in a widget ----------------

final financeApi = FinanceAiService(baseUrl: 'http://10.0.2.2:8000');

Future<void> loadDashboard() async {
  try {
    final recs = await financeApi.getUserRecommendations(1);
    final forecast = await financeApi.getUserForecast(1);
    final cluster = await financeApi.getUserCluster(1);
    setState(() {
      recommendations = recs['recommendations'];
      forecastData = forecast['forecast_next_month'];
      userCluster = cluster['cluster'];
    });
  } catch (e) {
    print('Failed to load dashboard: $e');
  }
}

------------------------------------------------------------- */
