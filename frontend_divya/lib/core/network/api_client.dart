import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Thin HTTP wrapper for VidyaSetu FastAPI backend.
class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  String get baseUrl => _baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// GET request with optional query parameters.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// GET request returning a JSON list.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final res = await _client.get(uri, headers: _headers).timeout(AppConfig.requestTimeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// POST request with JSON body.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await _client
        .post(uri, headers: _headers, body: jsonEncode(body))
        .timeout(AppConfig.requestTimeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(res.statusCode, res.body);
  }

  /// Fast health check with short timeout.
  Future<Map<String, dynamic>> checkHealth() async {
    final uri = Uri.parse('$_baseUrl/health');
    try {
      final res = await _client.get(uri, headers: _headers).timeout(AppConfig.healthTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'unhealthy', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'disconnected', 'error': e.toString()};
    }
  }

  void dispose() => _client.close();
}

/// Exception for non-2xx API responses.
class ApiException implements Exception {
  final int statusCode;
  final String body;

  const ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
