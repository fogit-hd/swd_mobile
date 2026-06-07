class LoginRequest {
  const LoginRequest({
    required this.username,
    required this.password,
    this.examinerCode,
  });

  final String username;
  final String password;
  final String? examinerCode;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        if (examinerCode != null && examinerCode!.isNotEmpty)
          'examinerCode': examinerCode,
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

/// Hai role duy nhất của app mobile: Panel và Moderator.
enum AppRole {
  panel('Panel', 'EvaluationPanel', 'Hội đồng chấm'),
  moderator('Moderator', 'Moderator', 'Điều phối viên');

  const AppRole(this.value, this.apiValue, this.labelVi);

  final String value;
  final String apiValue;
  final String labelVi;

  bool get isPanel => this == AppRole.panel;

  bool get isModerator => this == AppRole.moderator;

  static AppRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final role in AppRole.values) {
      if (role.value == raw || role.apiValue == raw) return role;
    }
    if (raw == 'EvaluationPanel') return AppRole.panel;
    return null;
  }
}
