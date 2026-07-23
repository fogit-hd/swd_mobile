import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/widgets/ui/slot_registration_matrix.dart';

void main() {
  testWidgets('full Lecturer slot shows 4/4 and blocks a new selection', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlotMatrixCell(
            selected: false,
            occupiedCount: 4,
            maxOccupancy: 4,
            showOccupancy: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('Đã đủ'), findsOneWidget);
    await tester.tap(find.byType(SlotMatrixCell));
    expect(taps, 0);
  });

  testWidgets('a selected full slot can still be deselected', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlotMatrixCell(
            selected: true,
            occupiedCount: 4,
            maxOccupancy: 4,
            showOccupancy: true,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SlotMatrixCell));
    expect(taps, 1);
  });

  testWidgets('Student slot shows remaining capacity out of three', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SlotMatrixCell(
            selected: false,
            occupiedCount: 2,
            maxOccupancy: 3,
            showOccupancy: true,
            onTap: null,
          ),
        ),
      ),
    );

    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Còn 1 chỗ'), findsOneWidget);
  });
}
