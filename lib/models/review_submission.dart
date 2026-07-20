import 'review_enums.dart';

class ReviewSubmissionItem {
  const ReviewSubmissionItem({
    this.itemKey,
    this.label,
    this.description,
    this.priority,
    this.isSection = false,
    this.criteriaCode,
    this.answer,
    this.comment,
  });

  factory ReviewSubmissionItem.fromJson(Map<String, dynamic> json) {
    return ReviewSubmissionItem(
      itemKey: json['itemKey'] as String?,
      label: json['label'] as String?,
      description: json['description'] as String?,
      priority: json['priority'] as String?,
      isSection: json['isSection'] as bool? ?? false,
      criteriaCode: json['criteriaCode'] as String?,
      answer: ReviewChecklistAnswer.tryParse(json['answer'] as String?),
      comment: json['comment'] as String?,
    );
  }

  final String? itemKey;
  final String? label;
  final String? description;
  final String? priority;
  final bool isSection;
  final String? criteriaCode;
  final ReviewChecklistAnswer? answer;
  final String? comment;

  ReviewSubmissionItem copyWith({
    ReviewChecklistAnswer? answer,
    String? comment,
  }) {
    return ReviewSubmissionItem(
      itemKey: itemKey,
      label: label,
      description: description,
      priority: priority,
      isSection: isSection,
      criteriaCode: criteriaCode,
      answer: answer ?? this.answer,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toDraftJson() => {
        'itemKey': itemKey,
        if (answer != null) 'answer': answer!.apiValue,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}

class ReviewSubmission {
  const ReviewSubmission({
    required this.id,
    required this.sessionId,
    required this.groupId,
    this.groupCode,
    this.projectName,
    this.type,
    this.status,
    this.sessionStatus,
    this.sessionDate,
    this.slot,
    this.room,
    this.reviewerId,
    this.reviewerCode,
    this.reviewerName,
    this.workProductVersion,
    this.workProductSize,
    this.effortHours,
    this.reviewerComment,
    this.suggestion,
    this.resultText,
    this.lastSavedAt,
    this.submittedAt,
    this.items = const [],
  });

  factory ReviewSubmission.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return ReviewSubmission(
      id: json['id'] as int? ?? 0,
      sessionId: json['sessionId'] as int? ?? 0,
      groupId: json['groupId'] as int? ?? 0,
      groupCode: json['groupCode'] as String?,
      projectName: json['projectName'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      sessionStatus: json['sessionStatus'] as String?,
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'] as String)
          : null,
      slot: json['slot'] as int?,
      room: json['room'] as String?,
      reviewerId: json['reviewerId'] as int?,
      reviewerCode: json['reviewerCode'] as String?,
      reviewerName: json['reviewerName'] as String?,
      workProductVersion: json['workProductVersion'] as String?,
      workProductSize: json['workProductSize'] as String?,
      effortHours: (json['effortHours'] as num?)?.toDouble(),
      reviewerComment: json['reviewerComment'] as String?,
      suggestion: json['suggestion'] as String?,
      resultText: json['resultText'] as String?,
      lastSavedAt: json['lastSavedAt'] != null
          ? DateTime.tryParse(json['lastSavedAt'] as String)
          : null,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
      items: itemsJson
          .map((e) => ReviewSubmissionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final int sessionId;
  final int groupId;
  final String? groupCode;
  final String? projectName;
  final String? type;
  final String? status;
  final String? sessionStatus;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final int? reviewerId;
  final String? reviewerCode;
  final String? reviewerName;
  final String? workProductVersion;
  final String? workProductSize;
  final double? effortHours;
  final String? reviewerComment;
  final String? suggestion;
  final String? resultText;
  final DateTime? lastSavedAt;
  final DateTime? submittedAt;
  final List<ReviewSubmissionItem> items;

  bool get isSubmitted =>
      status?.toLowerCase() == 'submitted' || submittedAt != null;

  ReviewSubmission copyWith({
    String? workProductVersion,
    String? workProductSize,
    double? effortHours,
    String? reviewerComment,
    String? suggestion,
    String? resultText,
    List<ReviewSubmissionItem>? items,
  }) {
    return ReviewSubmission(
      id: id,
      sessionId: sessionId,
      groupId: groupId,
      groupCode: groupCode,
      projectName: projectName,
      type: type,
      status: status,
      sessionStatus: sessionStatus,
      sessionDate: sessionDate,
      slot: slot,
      room: room,
      reviewerId: reviewerId,
      reviewerCode: reviewerCode,
      reviewerName: reviewerName,
      workProductVersion: workProductVersion ?? this.workProductVersion,
      workProductSize: workProductSize ?? this.workProductSize,
      effortHours: effortHours ?? this.effortHours,
      reviewerComment: reviewerComment ?? this.reviewerComment,
      suggestion: suggestion ?? this.suggestion,
      resultText: resultText ?? this.resultText,
      lastSavedAt: lastSavedAt,
      submittedAt: submittedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toDraftJson() => {
        if (workProductVersion != null) 'workProductVersion': workProductVersion,
        if (workProductSize != null) 'workProductSize': workProductSize,
        if (effortHours != null) 'effortHours': effortHours,
        if (reviewerComment != null) 'reviewerComment': reviewerComment,
        if (suggestion != null) 'suggestion': suggestion,
        if (resultText != null) 'resultText': resultText,
        'items': items
            .where((item) => !item.isSection)
            .map((item) => item.toDraftJson())
            .toList(),
      };
}
