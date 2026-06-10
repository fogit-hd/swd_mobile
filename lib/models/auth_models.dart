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

enum AppRole {
  panel('Panel', 'EvaluationPanel', 'Hội đồng chấm'),
  moderator('Moderator', 'Moderator', 'Điều phối viên'),
  lecturer('Lecturer', 'Lecturer', 'Giảng viên'),
  student('Student', 'Student', 'Sinh viên'),
  admin('Admin', 'SystemAdministrator', 'Quản trị viên');

  const AppRole(this.value, this.apiValue, this.labelVi);

  final String value;
  final String apiValue;
  final String labelVi;

  bool get isPanel => this == AppRole.panel;
  bool get isModerator => this == AppRole.moderator;
  bool get isLecturer => this == AppRole.lecturer;
  bool get isStudent => this == AppRole.student;
  bool get isAdmin => this == AppRole.admin;
  bool get isModeratorOrAdmin => isModerator || isAdmin;

  static const _aliases = <String, AppRole>{
    'EvaluationPanel': AppRole.panel,
    'Panel': AppRole.panel,
    'Moderator': AppRole.moderator,
    'TrainingDepartment': AppRole.moderator,
    'Lecturer': AppRole.lecturer,
    'Student': AppRole.student,
    'SystemAdministrator': AppRole.admin,
    'Admin': AppRole.admin,
    'Administrator': AppRole.admin,
  };

  static AppRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    for (final role in AppRole.values) {
      if (role.value == raw || role.apiValue == raw) return role;
    }

    return _aliases[raw];
  }
}
