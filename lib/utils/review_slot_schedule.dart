class ReviewSlotSchedule {
  const ReviewSlotSchedule._();

  static const times = <int, String>{
    1: '07:30 – 09:30',
    2: '09:45 – 11:45',
    3: '12:30 – 14:30',
    4: '14:45 – 16:45',
    5: '17:00 – 19:00',
  };

  static const lunchBreak = 'Nghỉ trưa 11:45 – 12:30';

  static String timeOf(int? slot) => times[slot] ?? 'Chưa xác định';

  static String labelOf(int? slot) =>
      slot == null ? 'Chưa xác định' : 'Slot $slot · ${timeOf(slot)}';
}
