class CreateReviewSessionRequest {
  const CreateReviewSessionRequest({
    required this.groupId,
    required this.type,
    this.code,
    this.groupPosition = 0,
    this.reviewer1Id,
    this.reviewer2Id,
    this.previousReviewerIds,
    this.slot,
    this.room,
    this.sessionDate,
  });

  final String? code;
  final int groupId;
  final int groupPosition;
  final String type;
  final int? reviewer1Id;
  final int? reviewer2Id;
  final List<int>? previousReviewerIds;
  final int? slot;
  final String? room;
  final DateTime? sessionDate;

  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        'groupId': groupId,
        'groupPosition': groupPosition,
        'type': type,
        if (reviewer1Id != null) 'reviewer1Id': reviewer1Id,
        if (reviewer2Id != null) 'reviewer2Id': reviewer2Id,
        if (previousReviewerIds != null)
          'previousReviewerIds': previousReviewerIds,
        if (slot != null) 'slot': slot,
        if (room != null) 'room': room,
        if (sessionDate != null) 'sessionDate': sessionDate!.toIso8601String(),
      };
}

class ReviewSessionResponse {
  const ReviewSessionResponse({
    required this.id,
    this.code,
    required this.groupId,
    this.groupCode,
    this.type,
    this.status,
    this.reviewerIds = const [],
    this.slot,
    this.room,
    this.sessionDate,
  });

  factory ReviewSessionResponse.fromJson(Map<String, dynamic> json) {
    return ReviewSessionResponse(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      groupId: json['groupId'] as int? ?? 0,
      groupCode: json['groupCode'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      reviewerIds: (json['reviewerIds'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      slot: json['slot'] as int?,
      room: json['room'] as String?,
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'] as String)
          : null,
    );
  }

  final int id;
  final String? code;
  final int groupId;
  final String? groupCode;
  final String? type;
  final String? status;
  final List<int> reviewerIds;
  final int? slot;
  final String? room;
  final DateTime? sessionDate;
}
