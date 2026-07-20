import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/app/auth_scope.dart';
import 'package:swd_mobile/screens/lecturer/lecturer_shell.dart';
import 'package:swd_mobile/services/auth_service.dart';
import 'package:swd_mobile/theme/app_theme.dart';
import 'package:swd_mobile/widgets/scale_tap.dart';

void main() {
  testWidgets('Lecturer shell builds all tabs in demo mode', (tester) async {
    final auth = AuthService()..enterDemoMode();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: AuthScope(
          authService: auth,
          child: const LecturerShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithIcon(ScaleTap, Icons.rate_review_outlined).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithIcon(ScaleTap, Icons.grid_view_rounded).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithIcon(ScaleTap, Icons.gavel_outlined).last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
