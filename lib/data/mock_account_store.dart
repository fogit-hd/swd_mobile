import '../models/auth_models.dart';
import '../models/create_account_models.dart';
import '../services/account_service.dart';
import 'mock_data.dart';

/// Tài khoản đăng nhập app (Panel / Moderator).
class MockAppAccount {
  const MockAppAccount({
    required this.username,
    required this.email,
    required this.password,
    required this.appRole,
  });

  final String username;
  final String email;
  final String password;
  final AppRole appRole;
}

/// User hệ thống được Moderator tạo (5 role backend).
class MockSystemUser {
  const MockSystemUser({
    required this.username,
    required this.email,
    required this.password,
    required this.systemRole,
    required this.profile,
  });

  final String username;
  final String email;
  final String password;
  final SystemUserRole systemRole;
  final RoleProfile profile;
}

class MockAccountStore {
  MockAccountStore._();

  static final MockAccountStore instance = MockAccountStore._();

  final Map<String, MockAppAccount> _appAccounts = {
    'panel': MockAppAccount(
      username: 'panel',
      email: 'panel@cpms.edu.vn',
      password: MockData.demoPassword,
      appRole: AppRole.panel,
    ),
    'moderator': MockAppAccount(
      username: 'moderator',
      email: 'moderator@cpms.edu.vn',
      password: MockData.demoPassword,
      appRole: AppRole.moderator,
    ),
  };

  final Map<String, MockSystemUser> _systemUsers = {};

  AppRole? loginRole(String username, String password) {
    final key = username.toLowerCase();
    final appAccount = _appAccounts[key];
    if (appAccount != null && appAccount.password == password) {
      return appAccount.appRole;
    }

    final systemUser = _systemUsers[key];
    if (systemUser != null &&
        systemUser.password == password &&
        systemUser.systemRole == SystemUserRole.evaluationPanel) {
      return AppRole.panel;
    }

    return null;
  }

  bool exists(String username) {
    final key = username.toLowerCase();
    return _appAccounts.containsKey(key) || _systemUsers.containsKey(key);
  }

  void createUser(CreateUserRequest request) {
    final key = request.username.toLowerCase();
    if (exists(key)) {
      throw AccountException('Tên đăng nhập đã tồn tại.');
    }
    _systemUsers[key] = MockSystemUser(
      username: key,
      email: request.email,
      password: request.password,
      systemRole: request.role,
      profile: request.profile,
    );
  }
}
