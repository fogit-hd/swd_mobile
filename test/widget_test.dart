import 'package:flutter_test/flutter_test.dart';

import 'package:swd_mobile/app/capstone_eval_app.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(CapstoneEvalApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('CPMS Mobile'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
  });
}
