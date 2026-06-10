class ReviewSession {
  const ReviewSession({
    required this.sessionId,
    required this.submissionId,
    this.code,
    this.type,
    this.sessionStatus,
    this.groupCode,
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
      groupCode: json['groupCode'] as String?,
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
  final String? groupCode;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final String? submissionStatus;
  final DateTime? lastSavedAt;

  bool get isPublished => sessionStatus == 'Published';
  bool get isSubmitted => submissionStatus == 'Submitted';
  bool get canEditReview => isPublished && !isSubmitted && submissionId > 0;
  bool get canViewResults => isSubmitted && submissionId > 0;

  String get title => groupCode ?? code ?? 'Phiên review #$sessionId';

  String get timeLabel {
    if (sessionDate == null) {
      return slot != null ? 'Ca $slot' : '—';
    }
    final date = sessionDate!;
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return slot != null ? '$time • Ca $slot' : time;
  }

  String get statusLabel {
    if (isSubmitted) return 'Đã gửi';
    if (submissionStatus == 'Draft') return 'Đang soạn';
    if (isPublished) return 'Đã công bố';
    return sessionStatus ?? '—';
  }
}
