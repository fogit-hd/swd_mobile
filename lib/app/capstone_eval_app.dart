import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../routes/app_routes.dart';
import '../screens/login_screen.dart';
import '../screens/moderator/moderator_shell.dart';
import '../screens/panel/panel_shell.dart';
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
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppRoutes.login ||
                  settings.name == AppRoutes.panel ||
                  settings.name == AppRoutes.moderator) {
                return null;
              }
              return MaterialPageRoute<void>(
                builder: (_) => authService.isAuthenticated
                    ? (authService.homeRoute == AppRoutes.moderator
                        ? const ModeratorShell()
                        : const PanelShell())
                    : const LoginScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
