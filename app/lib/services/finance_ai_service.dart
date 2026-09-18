import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/models.dart';
import 'api_exception.dart';

/// Talks to the FastAPI backend (see api/main.py). Every method returns a
/// typed model and throws [ApiException] with a human-readable message on
/// any failure, so screens never need to know about HTTP status codes or
/// socket exceptions directly.
class FinanceAiService {
  final String baseUrl;
  final http.Client _client;

  FinanceAiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  Future<CategoryPrediction> predictCategory({
    required String merchant,
    required double amount,
    required String paymentMethod,
    String? date,
  }) async {
    final json = await _post('/predict-category', {
      'merchant': merchant,
      'amount': amount,
      'payment_method': paymentMethod,
      if (date != null) 'date': date,
    });
    return CategoryPrediction.fromJson(json);
  }

  Future<AnomalyResult> checkAnomaly({
    required int userId,
    required String category,
    required String merchant,
    required double amount,
    String? date,
  }) async {
    final json = await _post('/check-anomaly', {
      'user_id': userId,
      'category': category,
      'merchant': merchant,
      'amount': amount,
      if (date != null) 'date': date,
    });
    return AnomalyResult.fromJson(json);
  }

  Future<ClusterProfile> getUserCluster(int userId) async {
    final json = await _get('/user/$userId/cluster');
    return ClusterProfile.fromJson(json);
  }

  Future<ForecastResult> getUserForecast(int userId) async {
    final json = await _get('/user/$userId/forecast');
    return ForecastResult.fromJson(json);
  }

  Future<List<RecommendationItem>> getUserRecommendations(int userId) async {
    final json = await _get('/user/$userId/recommendations');
    final list = (json['recommendations'] as List? ?? []);
    return list
        .map((e) => RecommendationItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------- internal HTTP helpers ----------

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$path'))
          .timeout(ApiConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const ApiException(
          'Could not reach the server. Check that the backend is running '
          'and your phone is on the same Wi-Fi network as your computer.');
    } on http.ClientException {
      throw const ApiException(
          'Connection failed. Check the server address in ApiConfig and '
          'that the backend is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request timed out or failed: $e');
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const ApiException(
          'Could not reach the server. Check that the backend is running '
          'and your phone is on the same Wi-Fi network as your computer.');
    } on http.ClientException {
      throw const ApiException(
          'Connection failed. Check the server address in ApiConfig and '
          'that the backend is running.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Request timed out or failed: $e');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 404) {
      throw const ApiException('No data found for this user yet.');
    }
    if (response.statusCode == 422) {
      throw const ApiException('The server rejected the request (invalid input).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = response.body;
      try {
        final parsed = jsonDecode(response.body);
        detail = (parsed['detail'] ?? response.body).toString();
      } catch (_) {}
      throw ApiException('Server error (${response.statusCode}): $detail');
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }
}
