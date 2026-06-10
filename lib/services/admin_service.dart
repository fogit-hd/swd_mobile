import 'dart:convert';

import '../models/account.dart';
import 'api_client.dart';

class AdminService {
  AdminService(this._client);

  final ApiClient _client;

  Future<List<Account>> fetchAccounts() async {
    final response = await _client.get('/api/accounts');
    _client.throwIfFailed(response, 'Tải danh sách tài khoản');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Account> updateAccountStatus({
    required int userId,
    required bool isActive,
    bool unlock = true,
  }) async {
    final response = await _client.patch(
      '/api/accounts/$userId/status',
      body: {'isActive': isActive, 'unlock': unlock},
    );
    _client.throwIfFailed(response, 'Cập nhật trạng thái tài khoản');

    return Account.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
