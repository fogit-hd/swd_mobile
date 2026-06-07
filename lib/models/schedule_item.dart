enum SessionStatus {
  waiting('Chờ'),
  inProgress('Đang chấm'),
  completed('Hoàn thành');

  const SessionStatus(this.label);

  final String label;
}

class ScheduleItem {
  const ScheduleItem({
    required this.sessionId,
    required this.groupId,
    required this.groupName,
    required this.projectTitle,
    required this.timeSlot,
    required this.room,
    required this.status,
    this.councilCode,
  });

  final int sessionId;
  final int groupId;
  final String groupName;
  final String projectTitle;
  final String timeSlot;
  final String room;
  final SessionStatus status;
  final String? councilCode;

  String get id => sessionId.toString();

  ScheduleItem copyWith({SessionStatus? status}) {
    return ScheduleItem(
      sessionId: sessionId,
      groupId: groupId,
      groupName: groupName,
      projectTitle: projectTitle,
      timeSlot: timeSlot,
      room: room,
      status: status ?? this.status,
      councilCode: councilCode,
    );
  }
}
