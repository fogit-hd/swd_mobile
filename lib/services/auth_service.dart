import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/mock_account_store.dart';
import '../data/mock_data.dart';
import '../models/auth_models.dart';
import '../routes/app_routes.dart';

class AuthService extends ChangeNotifier {
  String? _accessToken;
  AppRole? _role;
  String? _username;

  String? get accessToken => _accessToken;
  String? get username => _username;
  AppRole? get role => _role;

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty && _role != null;

  bool _demoMode = false;
  bool get isDemoMode => _demoMode;

  String? get homeRoute {
    return switch (_role) {
      AppRole.panel => AppRoutes.panel,
      AppRole.moderator => AppRoutes.moderator,
      null => null,
    };
  }

  Future<void> login({
    required String username,
    required String password,
    String? examinerCode,
  }) async {
    if (ApiConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final role = MockAccountStore.instance.loginRole(
        username.trim(),
        password,
      );
      if (role == null) {
        throw AuthException(
          'Sai tài khoản hoặc mật khẩu. Thử: panel / moderator + mật khẩu ${MockData.demoPassword}',
        );
      }
      _applySession(username: username.trim().toLowerCase(), role: role);
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        LoginRequest(
          username: username,
          password: password,
          examinerCode: examinerCode,
        ).toJson(),
      ),
    );

    if (response.statusCode >= 400) {
      throw AuthException(_parseError(response));
    }

    final token = TokenResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    if (token.accessToken.isEmpty) {
      throw AuthException('Không nhận được token đăng nhập.');
    }

    final role = _parseRoleFromToken(token.accessToken);
    if (role == null) {
      throw AuthException(
        'Tài khoản không thuộc Panel hoặc Moderator. App chỉ hỗ trợ 2 role này.',
      );
    }

    _accessToken = token.accessToken;
    _username = username;
    _role = role;
    notifyListeners();
  }

  void enterDemoMode({required AppRole role}) {
    _demoMode = true;
    _accessToken = 'demo';
    _username = 'demo_${role.value}';
    _role = role;
    notifyListeners();
  }

  void _applySession({required String username, required AppRole role}) {
    _demoMode = false;
    _accessToken = 'mock-token';
    _username = username;
    _role = role;
    notifyListeners();
  }

  void logout() {
    _demoMode = false;
    _accessToken = null;
    _username = null;
    _role = null;
    notifyListeners();
  }

  AppRole? _parseRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;

      const roleKeys = [
        'role',
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role',
        'roles',
      ];

      for (final key in roleKeys) {
        final value = payload[key];
        if (value is String) {
          return AppRole.tryParse(value);
        }
        if (value is List && value.isNotEmpty) {
          return AppRole.tryParse(value.first as String?);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
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
    return 'Yêu cầu thất bại. Vui lòng thử lại.';
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
