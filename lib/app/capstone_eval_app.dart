import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../models/auth_models.dart';
import '../routes/app_routes.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/lecturer/lecturer_shell.dart';
import '../screens/login_screen.dart';
import '../screens/moderator/moderator_shell.dart';
import '../screens/panel/panel_shell.dart';
import '../screens/student/student_shell.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CapstoneEvalApp extends StatelessWidget {
  CapstoneEvalApp({super.key, AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authService: authService,
      child: ListenableBuilder(
        listenable: authService,
        builder: (context, _) {
          return MaterialApp(
            title: 'CPMS Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            initialRoute: authService.isAuthenticated
                ? (authService.homeRoute ?? AppRoutes.login)
                : AppRoutes.login,
            routes: {
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.panel: (_) => const PanelShell(),
              AppRoutes.moderator: (_) => const ModeratorShell(),
              AppRoutes.lecturer: (_) => const LecturerShell(),
              AppRoutes.student: (_) => const StudentShell(),
              AppRoutes.admin: (_) => const AdminShell(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == null ||
                  AppRoutes.shellRoutes.contains(settings.name) ||
                  settings.name == AppRoutes.login) {
                return null;
              }
              return MaterialPageRoute<void>(
                builder: (_) => authService.isAuthenticated
                    ? _shellForRole(authService.role)
                    : const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _shellForRole(AppRole? role) {
    return switch (role) {
      AppRole.panel => const PanelShell(),
      AppRole.moderator => const ModeratorShell(),
      AppRole.lecturer => const LecturerShell(),
      AppRole.student => const StudentShell(),
      AppRole.admin => const ModeratorShell(),
      null => const LoginScreen(),
    };
  }
}
