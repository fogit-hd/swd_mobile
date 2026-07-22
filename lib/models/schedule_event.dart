import '../utils/review_slot_schedule.dart';

class ScheduleEvent {
  const ScheduleEvent({
    required this.date,
    this.slot,
    required this.title,
    this.subtitle,
    this.room,
    this.type,
  });

  final DateTime date;
  final int? slot;
  final String title;
  final String? subtitle;
  final String? room;
  final String? type;

  String get slotLabel => slot != null ? ReviewSlotSchedule.labelOf(slot) : '';

  String get detail {
    final parts = <String>[
      if (room != null && room!.isNotEmpty) room!,
      if (slot != null) ReviewSlotSchedule.labelOf(slot),
      ?type,
    ];
    return parts.join(' • ');
  }
}
