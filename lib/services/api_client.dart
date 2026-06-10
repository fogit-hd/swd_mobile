import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient(this._auth);

  final AuthService _auth;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_auth.accessToken != null)
          'Authorization': 'Bearer ${_auth.accessToken}',
      };

  Future<http.Response> get(String path, {Map<String, String>? query}) =>
      http.get(_uri(path, query), headers: _headers);

  Future<http.Response> post(String path, {Object? body}) => http.post(
        _uri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) =>
      http.put(
        _uri(path, query),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

  Future<http.Response> patch(String path, {Object? body}) => http.patch(
        _uri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

  Future<List<int>> download(String path, {Map<String, String>? query}) async {
    final response = await http.get(
      _uri(path, query),
      headers: {
        if (_auth.accessToken != null)
          'Authorization': 'Bearer ${_auth.accessToken}',
      },
    );
    throwIfFailed(response, 'Tải file');
    return response.bodyBytes;
  }

  void throwIfFailed(http.Response response, String action) {
    if (response.statusCode >= 400) {
      throw ApiException(
        '$action thất bại (${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => message;
}
