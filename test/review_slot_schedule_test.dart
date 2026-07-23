import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/utils/review_slot_schedule.dart';

void main() {
  test('five review slots use the approved timetable', () {
    expect(ReviewSlotSchedule.times, const <int, String>{
      1: '07:30 – 09:30',
      2: '09:45 – 11:45',
      3: '12:30 – 14:30',
      4: '14:45 – 16:45',
      5: '17:00 – 19:00',
    });
    expect(ReviewSlotSchedule.lunchBreak, 'Nghỉ trưa 11:45 – 12:30');
    expect(ReviewSlotSchedule.labelOf(5), 'Slot 5 · 17:00 – 19:00');
  });
}
