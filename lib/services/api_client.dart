import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  ApiClient(this._auth);

  final AuthService _auth;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.accessToken != null)
          'Authorization': 'Bearer ${_auth.accessToken}',
      };

  Future<http.Response> get(String path) =>
      http.get(_uri(path), headers: _headers);

  Future<http.Response> post(String path, {Object? body}) => http.post(
        _uri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

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
