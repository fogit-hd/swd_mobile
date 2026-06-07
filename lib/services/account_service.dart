import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/mock_account_store.dart';
import '../models/create_account_models.dart';

class AccountService {
  Future<void> createUser(CreateUserRequest request) async {
    if (ApiConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      MockAccountStore.instance.createUser(request);
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/accounts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
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
