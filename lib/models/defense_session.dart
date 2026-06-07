import 'schedule_item.dart';

class DefenseSessionAssignment {
  const DefenseSessionAssignment({
    required this.id,
    required this.groupId,
    this.code,
    this.councilCode,
    this.groupCode,
    this.sessionDate,
    this.slot,
    this.room,
    this.startedAt,
    this.endedAt,
    this.isLocked = false,
  });

  factory DefenseSessionAssignment.fromJson(Map<String, dynamic> json) {
    return DefenseSessionAssignment(
      id: json['id'] as int? ?? 0,
      groupId: json['groupId'] as int? ?? 0,
      code: json['code'] as String?,
      councilCode: json['councilCode'] as String?,
      groupCode: json['groupCode'] as String?,
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'] as String)
          : null,
      slot: json['slot'] as int?,
      room: json['room'] as String?,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  final int id;
  final int groupId;
  final String? code;
  final String? councilCode;
  final String? groupCode;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isLocked;

  ScheduleItem toScheduleItem() {
    final status = endedAt != null
        ? SessionStatus.completed
        : startedAt != null
            ? SessionStatus.inProgress
            : SessionStatus.waiting;

    final timeLabel = sessionDate != null
        ? '${sessionDate!.hour.toString().padLeft(2, '0')}:${sessionDate!.minute.toString().padLeft(2, '0')}'
            '${slot != null ? ' • Ca $slot' : ''}'
        : slot != null
            ? 'Ca $slot'
            : '—';

    return ScheduleItem(
      sessionId: id,
      groupId: groupId,
      groupName: groupCode ?? 'Nhóm $groupId',
      projectTitle: code ?? 'Phiên bảo vệ',
      timeSlot: timeLabel,
      room: room ?? '—',
      status: status,
      councilCode: councilCode,
    );
  }
}

enum ScoreType {
  baoVe('BaoVe', 'Điểm bảo vệ'),
  nguoi('Nguoi', 'Điểm cá nhân');

  const ScoreType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
