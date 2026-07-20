/// Bản tóm tắt từ GET /api/review-submissions/my (lecturer).
class ReviewSubmissionSummary {
  const ReviewSubmissionSummary({
    required this.id,
    required this.sessionId,
    required this.groupId,
    this.reviewType,
    this.status,
    this.result,
    this.score,
    this.notes,
    this.submittedAt,
  });

  factory ReviewSubmissionSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSubmissionSummary(
      id: json['id'] as int? ?? 0,
      sessionId: json['sessionId'] as int? ?? 0,
      groupId: json['groupId'] as int? ?? 0,
      reviewType: json['reviewType'] as String?,
      status: json['status'] as String?,
      result: json['result'] as String?,
      score: json['score'] as String?,
      notes: json['notes'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
    );
  }

  final int id;
  final int sessionId;
  final int groupId;
  final String? reviewType;
  final String? status;
  final String? result;
  final String? score;
  final String? notes;
  final DateTime? submittedAt;

  bool get isSubmitted => status == 'Submitted';
}
