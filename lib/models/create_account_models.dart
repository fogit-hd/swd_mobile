/// Role trong bảng User (backend CPMS).
enum SystemUserRole {
  student('Student', 'Sinh viên'),
  lecturer('Lecturer', 'Giảng viên'),
  evaluationPanel('EvaluationPanel', 'Hội đồng chấm'),
  trainingDepartment('TrainingDepartment', 'Phòng đào tạo'),
  systemAdministrator('SystemAdministrator', 'Quản trị hệ thống');

  const SystemUserRole(this.apiValue, this.labelVi);

  final String apiValue;
  final String labelVi;

  static SystemUserRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final role in SystemUserRole.values) {
      if (role.apiValue == raw) return role;
    }
    return null;
  }
}

class CreateUserRequest {
  const CreateUserRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.profile,
  });

  final String username;
  final String email;
  final String password;
  final SystemUserRole role;
  final RoleProfile profile;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        'role': role.apiValue,
        'isActive': true,
        ...profile.toJson(),
      };
}

sealed class RoleProfile {
  const RoleProfile();

  Map<String, dynamic> toJson();
}

class StudentProfile extends RoleProfile {
  const StudentProfile({
    required this.fullName,
    required this.studentCode,
    required this.batch,
    required this.major,
    this.groupId,
  });

  final String fullName;
  final String studentCode;
  final String batch;
  final String major;
  final int? groupId;

  @override
  Map<String, dynamic> toJson() => {
        'student': {
          'fullName': fullName,
          'studentCode': studentCode,
          'batch': batch,
          'major': major,
          if (groupId != null) 'groupId': groupId,
        },
      };
}

class LecturerProfile extends RoleProfile {
  const LecturerProfile({
    required this.fullName,
    required this.department,
    required this.maxGroups,
  });

  final String fullName;
  final String department;
  final int maxGroups;

  @override
  Map<String, dynamic> toJson() => {
        'lecturer': {
          'fullName': fullName,
          'department': department,
          'maxGroups': maxGroups,
        },
      };
}

class EvaluationPanelProfile extends RoleProfile {
  const EvaluationPanelProfile({
    required this.fullName,
    required this.department,
  });

  final String fullName;
  final String department;

  @override
  Map<String, dynamic> toJson() => {
        'evaluationPanel': {
          'fullName': fullName,
          'department': department,
        },
      };
}

class TrainingDepartmentProfile extends RoleProfile {
  const TrainingDepartmentProfile({
    required this.departmentName,
    required this.staffCode,
    required this.position,
  });

  final String departmentName;
  final String staffCode;
  final String position;

  @override
  Map<String, dynamic> toJson() => {
        'trainingDepartment': {
          'departmentName': departmentName,
          'staffCode': staffCode,
          'position': position,
        },
      };
}

class SystemAdministratorProfile extends RoleProfile {
  const SystemAdministratorProfile({
    required this.adminLevel,
    required this.permissionScope,
  });

  final String adminLevel;
  final String permissionScope;

  @override
  Map<String, dynamic> toJson() => {
        'systemAdministrator': {
          'adminLevel': adminLevel,
          'permissionScope': permissionScope,
        },
      };
}
