class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    this.refreshToken,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
    );
  }

  final String accessToken;
  final String? refreshToken;
}

enum AppRole {
  lecturer('Lecturer', 'Lecturer', 'Giảng viên');

  const AppRole(this.value, this.apiValue, this.labelVi);

  final String value;
  final String apiValue;
  final String labelVi;

  static const _aliases = <String, AppRole>{
    'Lecturer': AppRole.lecturer,
  };

  static AppRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    for (final role in AppRole.values) {
      if (role.value == raw || role.apiValue == raw) return role;
    }

    return _aliases[raw];
  }
}
