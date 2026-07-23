import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/screens/login_screen.dart';

void main() {
  testWidgets('Lecturer quick login follows the QA build flags', (
    tester,
  ) async {
    const enabled = bool.fromEnvironment('ENABLE_LECTURER_QUICK_LOGIN');
    const password = String.fromEnvironment('LECTURER_QUICK_PASSWORD');
    const shouldBeVisible = enabled && password != '';

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(
      find.byKey(const ValueKey('lecturer-quick-login-button')),
      shouldBeVisible ? findsOneWidget : findsNothing,
    );

    // Let every delayed entrance animation start, then dispose the login
    // screen so its repeating controller cannot leak into the test binding.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
