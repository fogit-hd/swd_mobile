import '../models/auth_models.dart';

class AppRoutes {
  static const login = '/login';
  static const panel = '/panel';
  static const moderator = '/moderator';
  static const lecturer = '/lecturer';
  static const student = '/student';
  static const admin = '/admin';

  static const shellRoutes = <String>{
    panel,
    moderator,
    lecturer,
    student,
    admin,
  };

  static String? routeForRole(AppRole? role) {
    return switch (role) {
      AppRole.panel => panel,
      AppRole.moderator => moderator,
      AppRole.admin => moderator,
      AppRole.lecturer => lecturer,
      AppRole.student => student,
      null => null,
    };
  }
}
