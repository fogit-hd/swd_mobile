import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../models/auth_models.dart';
import '../screens/login_screen.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    this.allowedRole,
    this.allowedRoles = const [],
    required this.child,
  });

  final AppRole? allowedRole;
  final List<AppRole> allowedRoles;
  final Widget child;

  List<AppRole> get _roles {
    if (allowedRoles.isNotEmpty) return allowedRoles;
    return [allowedRole!];
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.isAuthenticated) {
      return const _Redirecting(message: 'Đang chuyển về đăng nhập...');
    }

    final role = auth.role;
    if (role == null || !_roles.contains(role)) {
      return _Redirecting(
        message: 'Tài khoản ${role?.labelVi ?? 'không xác định'} '
            'không có quyền truy cập màn hình này.',
        onRedirect: () {
          final route = auth.homeRoute;
          if (route != null) {
            Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
          } else {
            logout(context);
          }
        },
      );
    }

    return child;
  }
}

class _Redirecting extends StatefulWidget {
  const _Redirecting({required this.message, this.onRedirect});

  final String message;
  final VoidCallback? onRedirect;

  @override
  State<_Redirecting> createState() => _RedirectingState();
}

class _RedirectingState extends State<_Redirecting> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.onRedirect != null) {
        widget.onRedirect!();
      } else {
        logout(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(widget.message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
