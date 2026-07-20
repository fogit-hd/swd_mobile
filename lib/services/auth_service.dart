import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../data/mock_sample_data.dart';
import '../models/auth_models.dart';
import '../routes/app_routes.dart';

class AuthService extends ChangeNotifier {
  AuthService();

  static const _keyAccess = 'auth_access_token';
  static const _keyRefresh = 'auth_refresh_token';
  static const _keyUsername = 'auth_username';

  String? _accessToken;
  String? _refreshToken;
  String? _username;
  bool _restored = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get username => _username;
  bool get isRestored => _restored;

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty;

  bool get isDemoMode => _accessToken == MockSampleData.demoToken;

  String get homeRoute => AppRoutes.home;

  /// Vào app với dữ liệu mẫu — không cần API.
  void enterDemoMode() {
    _accessToken = MockSampleData.demoToken;
    _refreshToken = null;
    _username = 'demo.lecturer';
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_keyAccess);
    final refresh = prefs.getString(_keyRefresh);
    final username = prefs.getString(_keyUsername);

    if (access != null && access.isNotEmpty) {
      _accessToken = access;
      _refreshToken = refresh;
      _username = username;
    }
    _restored = true;
    notifyListeners();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
        LoginRequest(username: username, password: password).toJson(),
      ),
    );

    if (response.statusCode >= 400) {
      throw AuthException(_parseLoginError(response));
    }

    final token = TokenResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    if (token.accessToken.isEmpty) {
      throw AuthException('Không nhận được token đăng nhập.');
    }

    final role = _parseRoleFromToken(token.accessToken);
    if (role != AppRole.lecturer) {
      throw AuthException(
        'Tài khoản của bạn không có quyền truy cập ứng dụng này.',
      );
    }

    _accessToken = token.accessToken;
    _refreshToken = token.refreshToken;
    _username = username;
    await _persist();
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
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
    await prefs.remove(_keyUsername);
    notifyListeners();
  }

  Future<void> _persist() async {
    if (isDemoMode) return;
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_keyAccess, _accessToken!);
      if (_refreshToken != null) {
        await prefs.setString(_keyRefresh, _refreshToken!);
      }
      if (_username != null) {
        await prefs.setString(_keyUsername, _username!);
      }
    }
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

  String _parseLoginError(http.Response response) {
    final parsed = _parseError(response);
    if (response.statusCode == 401) {
      if (_isGenericUnauthorized(parsed)) {
        return 'Sai tên đăng nhập hoặc mật khẩu '
            '(hoặc tài khoản đang bị khóa tạm thời).';
      }
      return _localizeAuthError(parsed);
    }
    if (response.statusCode == 429) {
      return 'Thử đăng nhập quá nhiều lần. Vui lòng đợi khoảng 1 phút.';
    }
    return _localizeAuthError(parsed);
  }

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] != null) {
        return body['error'] as String;
      }
      if (body is Map && body['message'] != null) {
        return body['message'] as String;
      }
      if (body is Map && body['title'] != null) {
        return body['title'] as String;
      }
    } catch (_) {}
    return 'Yêu cầu thất bại. Vui lòng thử lại.';
  }

  static bool _isGenericUnauthorized(String message) {
    final normalized = message.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'unauthorized' ||
        normalized == 'yêu cầu thất bại. vui lòng thử lại.';
  }

  static String _localizeAuthError(String message) {
    switch (message.trim()) {
      case 'Invalid username or password.':
        return 'Sai tên đăng nhập hoặc mật khẩu.';
      case 'Username is required.':
        return 'Vui lòng nhập tên đăng nhập.';
      case 'Refresh token is invalid or expired.':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      default:
        return message;
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
