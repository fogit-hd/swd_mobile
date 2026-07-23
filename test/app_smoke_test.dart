import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/app/auth_scope.dart';
import 'package:swd_mobile/screens/lecturer/lecturer_shell.dart';
import 'package:swd_mobile/services/auth_service.dart';
import 'package:swd_mobile/theme/app_theme.dart';
import 'package:swd_mobile/widgets/scale_tap.dart';

void main() {
  testWidgets('Lecturer review shell builds all tabs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = AuthService()
      ..setSessionForTesting(
        accessToken: 'test-session-token',
        username: 'test.lecturer',
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: AuthScope(authService: auth, child: const LecturerShell()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Lịch review'), findsWidgets);

    await tester.tap(
      find.widgetWithIcon(ScaleTap, Icons.rate_review_outlined).last,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Nhận xét'), findsWidgets);

    await tester.tap(
      find.widgetWithIcon(ScaleTap, Icons.grid_view_rounded).last,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Đăng ký Slot'), findsWidgets);
  });
}
