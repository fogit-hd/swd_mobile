/// Dữ liệu hiển thị lịch đã chốt cho Sinh viên.
class StudentPublishedSchedule {
  const StudentPublishedSchedule({
    required this.groupCode,
    required this.groupName,
    required this.dayLabel,
    required this.slotLabel,
    required this.room,
    required this.reviewers,
    this.supervisorName,
    this.sessionDate,
    this.status = ProjectScheduleStatus.published,
  });

  final String groupCode;
  final String groupName;
  final String dayLabel;
  final String slotLabel;
  final String room;
  /// Giảng viên review — KHÔNG bao gồm GVHD (tránh conflict of interest).
  final List<ScheduleReviewer> reviewers;
  final String? supervisorName;
  final DateTime? sessionDate;
  final ProjectScheduleStatus status;
}

class ScheduleReviewer {
  const ScheduleReviewer({
    required this.name,
    this.department,
    this.isSupervisor = false,
  });

  final String name;
  final String? department;
  final bool isSupervisor;
}

/// Một slot chấm của Giảng viên — tối đa 3 nhóm/slot.
class LecturerReviewSlot {
  const LecturerReviewSlot({
    required this.dayLabel,
    required this.slotLabel,
    required this.room,
    required this.groups,
    this.sessionDate,
    this.sortKey = 0,
  });

  final String dayLabel;
  final String slotLabel;
  final String room;
  final List<LecturerReviewGroup> groups;
  final DateTime? sessionDate;
  final int sortKey;
}

class LecturerReviewGroup {
  const LecturerReviewGroup({
    required this.groupCode,
    required this.topicName,
    this.status = ProjectScheduleStatus.pending,
    this.sessionId,
    this.groupId,
    this.submissionId,
    this.hasAccessCode = false,
    this.isAccessVerified = false,
  });

  final String groupCode;
  final String topicName;
  final ProjectScheduleStatus status;
  final int? sessionId;
  final int? groupId;
  final int? submissionId;
  final bool hasAccessCode;
  final bool isAccessVerified;
}

enum ProjectScheduleStatus {
  pending,
  inProgress,
  published,
  completed,
}
