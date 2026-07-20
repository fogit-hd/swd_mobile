import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService authService,
    required super.child,
  }) : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found');
    final auth = scope?.notifier;
    if (auth == null) {
      throw FlutterError('AuthScope notifier is null');
    }
    return auth;
  }
}

class AppScope {
  static AuthService auth(BuildContext context) => AuthScope.of(context);
}
