import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/app/auth_scope.dart';
import 'package:swd_mobile/screens/lecturer/lecturer_shell.dart';
import 'package:swd_mobile/services/auth_service.dart';
import 'package:swd_mobile/theme/app_theme.dart';
import 'package:swd_mobile/widgets/scale_tap.dart';

void main() {
  testWidgets('Lecturer review shell builds all tabs in demo mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final auth = AuthService()..enterDemoMode();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: AuthScope(authService: auth, child: const LecturerShell()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);

    await tester.tap(
      find.widgetWithIcon(ScaleTap, Icons.rate_review_outlined).last,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('review-scope-today')), findsOneWidget);
    expect(find.byKey(const ValueKey('review-scope-upcoming')), findsOneWidget);
    expect(find.byKey(const ValueKey('review-scope-all')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('review-scope-upcoming')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('review-scope-all')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.widgetWithIcon(ScaleTap, Icons.grid_view_rounded).last,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
