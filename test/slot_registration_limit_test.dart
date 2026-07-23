import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/screens/slot/slot_registration_screen.dart';
import 'package:swd_mobile/theme/app_theme.dart';
import 'package:swd_mobile/utils/review_slot_schedule.dart';
import 'package:swd_mobile/widgets/ui/slot_registration_matrix.dart';

void main() {
  testWidgets('lecturer cannot select more than maxLecturerSelectedSlots', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final initial = {
      for (var i = 1; i <= ReviewSlotSchedule.maxLecturerSelectedSlots; i++)
        SlotRegistrationMatrix.cellKey(1, i),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: SlotRegistrationScreen(
            mode: SlotRegistrationMode.lecturer,
            initialSelection: initial,
            enabled: true,
            onSave: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Đã chọn: ${ReviewSlotSchedule.maxLecturerSelectedSlots}/'
        '${ReviewSlotSchedule.maxLecturerSelectedSlots} Slot',
      ),
      findsOneWidget,
    );

    final extra = find.byKey(const ValueKey('slot-cell-2-1'));
    await tester.ensureVisible(extra);
    await tester.pumpAndSettle();
    await tester.tap(extra);
    await tester.pump();

    expect(find.textContaining('Chỉ được chọn tối đa'), findsOneWidget);
    expect(
      find.textContaining(
        'Đã chọn: ${ReviewSlotSchedule.maxLecturerSelectedSlots}/'
        '${ReviewSlotSchedule.maxLecturerSelectedSlots} Slot',
      ),
      findsOneWidget,
    );
  });
}
