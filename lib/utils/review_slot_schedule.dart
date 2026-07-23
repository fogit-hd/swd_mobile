class ReviewSlotSchedule {
  const ReviewSlotSchedule._();

  /// Số ca trong một ngày (Slot 1–5).
  static const slotsPerDay = 5;

  /// Số ô tối đa Giảng viên được chọn mỗi đợt review.
  /// (Sinh viên bắt buộc đúng 5 ô theo BE; Giảng viên BE chưa enforce,
  /// mobile giới hạn để tránh đăng ký quá nhiều.)
  static const maxLecturerSelectedSlots = 5;

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
