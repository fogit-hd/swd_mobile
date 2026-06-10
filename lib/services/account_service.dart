import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/create_account_models.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AccountService {
  AccountService(this._auth);

  final AuthService _auth;

  Future<void> createUser(CreateUserRequest request) async {
    final response = await ApiClient(_auth).post(
      '/api/accounts',
      body: request.toJson(),
    );

    if (response.statusCode >= 400) {
      throw AccountException(_parseError(response));
    }
  }

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        return body['message'] as String;
      }
      if (body is Map && body['title'] != null) {
        return body['title'] as String;
      }
    } catch (_) {}
    return 'Không tạo được tài khoản. Vui lòng thử lại.';
  }
}

class AccountException implements Exception {
  AccountException(this.message);

  final String message;

  @override
  String toString() => message;
}
