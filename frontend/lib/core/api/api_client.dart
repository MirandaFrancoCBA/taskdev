import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? accessToken;
  Future<bool> Function()? refreshAccessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<http.Response> _send(Future<http.Response> Function() request, {bool retry = true}) async {
    var response = await request();
    if (response.statusCode == 401 && retry && refreshAccessToken != null && await refreshAccessToken!()) {
      response = await request();
    }
    return response;
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body], {bool retry = true}) async {
    final response = await _send(() => _client.post(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers, body: jsonEncode(body ?? {})), retry: retry);
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _send(() => _client.get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers));
    return _decodeObject(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _send(() => _client.get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers));
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(response), statusCode: response.statusCode);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final response = await _send(() => _client.patch(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: _headers, body: jsonEncode(body)));
    return _decodeObject(response);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(response), statusCode: response.statusCode);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _message(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map && data['detail'] != null ? data['detail'].toString() : 'Request failed (${response.statusCode})';
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }
}
