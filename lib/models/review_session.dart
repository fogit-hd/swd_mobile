import '../utils/display_labels.dart';
import '../utils/review_slot_schedule.dart';

class ReviewSession {
  const ReviewSession({
    required this.sessionId,
    required this.submissionId,
    this.code,
    this.type,
    this.sessionStatus,
    this.groupId,
    this.groupCode,
    this.topicName,
    this.sessionDate,
    this.slot,
    this.room,
    this.submissionStatus,
    this.lastSavedAt,
  });

  factory ReviewSession.fromJson(Map<String, dynamic> json) {
    return ReviewSession(
      sessionId: json['sessionId'] as int? ?? 0,
      submissionId: json['submissionId'] as int? ?? 0,
      code: json['code'] as String?,
      type: json['type'] as String?,
      sessionStatus: json['sessionStatus'] as String?,
      groupId: json['groupId'] as int?,
      groupCode: json['groupCode'] as String?,
      topicName: json['topicName'] as String?,
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'] as String)
          : null,
      slot: json['slot'] as int?,
      room: json['room'] as String?,
      submissionStatus: json['submissionStatus'] as String?,
      lastSavedAt: json['lastSavedAt'] != null
          ? DateTime.tryParse(json['lastSavedAt'] as String)
          : null,
    );
  }

  final int sessionId;
  final int submissionId;
  final String? code;
  final String? type;
  final String? sessionStatus;
  final int? groupId;
  final String? groupCode;
  final String? topicName;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final String? submissionStatus;
  final DateTime? lastSavedAt;

  bool get isPublished => sessionStatus?.toLowerCase() == 'published';
  bool get isSubmitted => submissionStatus?.toLowerCase() == 'submitted';
  bool get canEditReview => isPublished && !isSubmitted && submissionId > 0;
  bool get canViewResults => isSubmitted && submissionId > 0;

  String get title => groupCode ?? code ?? 'Phiên review #$sessionId';

  String get typeLabel => DisplayLabels.reviewType(type);

  String get timeLabel {
    return ReviewSlotSchedule.labelOf(slot);
  }

  String get statusLabel => DisplayLabels.reviewWorkflowStatus(
    submissionStatus: submissionStatus,
    sessionStatus: sessionStatus,
  );
}
