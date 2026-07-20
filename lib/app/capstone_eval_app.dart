import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../routes/app_routes.dart';
import '../screens/lecturer/lecturer_shell.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class CapstoneEvalApp extends StatefulWidget {
  const CapstoneEvalApp({super.key, this.authService});

  final AuthService? authService;

  @override
  State<CapstoneEvalApp> createState() => _CapstoneEvalAppState();
}

class _CapstoneEvalAppState extends State<CapstoneEvalApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _authService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authService: _authService,
      child: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) {
          if (!_authService.isRestored) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          final startScreen = _authService.isAuthenticated
              ? const LecturerShell()
              : const LoginScreen();

          return MaterialApp(
            title: 'CPM System',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: startScreen,
            routes: {
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.home: (_) => const LecturerShell(),
            },
            onUnknownRoute: (settings) =>
                MaterialPageRoute<void>(builder: (_) => startScreen),
          );
        },
      ),
    );
  }
}
