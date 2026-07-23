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
    // MaterialApp phải ổn định — không recreate mỗi lần auth notify
    // (tránh InheritedWidget dispose khi còn dependents).
    return AuthScope(
      authService: _authService,
      child: MaterialApp(
        title: 'CPM System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AuthRoot(),
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.home: (_) => const LecturerShell(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => const _AuthRoot(),
          settings: settings,
        ),
      ),
    );
  }
}

/// Gate đăng nhập — rebuild qua AuthScope (InheritedNotifier), không thay MaterialApp.
class _AuthRoot extends StatelessWidget {
  const _AuthRoot();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    if (!auth.isRestored) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.isAuthenticated) {
      return const LecturerShell();
    }
    return const LoginScreen();
  }
}
