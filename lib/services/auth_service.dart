import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../routes/app_routes.dart';

class AuthService extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  AppRole? _role;
  String? _username;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  AppRole? get role => _role;

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty && _role != null;

  bool hasRole(AppRole expected) => _role == expected;

  bool get isPanel => hasRole(AppRole.panel);
  bool get isModerator => hasRole(AppRole.moderator);
  bool get isLecturer => hasRole(AppRole.lecturer);
  bool get isStudent => hasRole(AppRole.student);
  bool get isAdmin => hasRole(AppRole.admin);
  bool get isModeratorOrAdmin => isModerator || isAdmin;
  bool get isDemoGuest => _accessToken == 'demo-guest';

  String? get homeRoute => AppRoutes.routeForRole(_role);

  /// Vào app không cần API — dùng cho demo UI (guest).
  void enterDemoAsGuest(AppRole role) {
    _accessToken = 'demo-guest';
    _refreshToken = null;
    _username = 'guest';
    _role = role;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
    String? examinerCode,
  }) async {
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
        'Tài khoản không được phép đăng nhập app. '
        'Chỉ hỗ trợ: Hội đồng chấm, Điều phối viên, Giảng viên, Sinh viên, Quản trị viên.',
      );
    }

    _accessToken = token.accessToken;
    _refreshToken = token.refreshToken;
    _username = username;
    _role = role;
    notifyListeners();
  }

  Future<void> refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      throw AuthException('Không có refresh token.');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': _refreshToken}),
    );

    if (response.statusCode >= 400) {
      throw AuthException(_parseError(response));
    }

    final token = TokenResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    if (token.accessToken.isEmpty) {
      throw AuthException('Không nhận được token mới.');
    }

    _accessToken = token.accessToken;
    _refreshToken = token.refreshToken ?? _refreshToken;
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
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

      final candidates = <String>[];
      for (final key in roleKeys) {
        final value = payload[key];
        if (value is String) {
          candidates.add(value);
        } else if (value is List) {
          for (final item in value) {
            if (item is String) candidates.add(item);
          }
        }
      }

      for (final raw in candidates) {
        final role = AppRole.tryParse(raw);
        if (role != null) return role;
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
