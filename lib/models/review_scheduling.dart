import 'review_enums.dart';

class SchedulingLecturer {
  const SchedulingLecturer({
    required this.id,
    this.code,
    this.fullName,
    this.department,
    this.email,
  });

  factory SchedulingLecturer.fromJson(Map<String, dynamic> json) {
    return SchedulingLecturer(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      fullName: json['fullName'] as String?,
      department: json['department'] as String?,
      email: json['email'] as String?,
    );
  }

  final int id;
  final String? code;
  final String? fullName;
  final String? department;
  final String? email;

  String get displayName => fullName ?? code ?? 'GV $id';
}

class SchedulingGroup {
  const SchedulingGroup({
    required this.id,
    this.code,
    this.projectName,
    this.supervisorId,
    this.supervisorCode,
  });

  factory SchedulingGroup.fromJson(Map<String, dynamic> json) {
    return SchedulingGroup(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      projectName: json['projectName'] as String?,
      supervisorId: json['supervisorId'] as int?,
      supervisorCode: json['supervisorCode'] as String?,
    );
  }

  final int id;
  final String? code;
  final String? projectName;
  final int? supervisorId;
  final String? supervisorCode;
}

class SchedulingSession {
  const SchedulingSession({
    required this.id,
    this.code,
    required this.groupId,
    this.groupCode,
    this.type,
    this.status,
    this.reviewerIds = const [],
    this.sessionDate,
    this.dayOfWeek,
    this.slot,
    this.room,
  });

  factory SchedulingSession.fromJson(Map<String, dynamic> json) {
    return SchedulingSession(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      groupId: json['groupId'] as int? ?? 0,
      groupCode: json['groupCode'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      reviewerIds: (json['reviewerIds'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'] as String)
          : null,
      dayOfWeek: json['dayOfWeek'] as int?,
      slot: json['slot'] as int?,
      room: json['room'] as String?,
    );
  }

  final int id;
  final String? code;
  final int groupId;
  final String? groupCode;
  final String? type;
  final String? status;
  final List<int> reviewerIds;
  final DateTime? sessionDate;
  final int? dayOfWeek;
  final int? slot;
  final String? room;

  Map<String, dynamic> toBulkAssignJson() => {
        'code': code,
        'groupId': groupId,
        'groupPosition': 0,
        'type': type ?? ReviewType.defaultType.apiValue,
        'reviewerIds': reviewerIds,
        'previousReviewerIds': <int>[],
        'slot': slot ?? 0,
        'room': room,
        if (sessionDate != null) 'sessionDate': sessionDate!.toIso8601String(),
      };

  Map<String, dynamic> toUpdateJson() => {
        'code': code,
        'reviewerIds': reviewerIds,
        'previousReviewerIds': <int>[],
        'slot': slot,
        'room': room,
        if (sessionDate != null) 'sessionDate': sessionDate!.toIso8601String(),
        'status': status ?? 'Draft',
      };
}

class ReviewSchedulingBoard {
  const ReviewSchedulingBoard({
    required this.semesterId,
    this.reviewType,
    this.weekStart,
    this.lecturers = const [],
    this.availability = const [],
    this.groups = const [],
    this.sessions = const [],
  });

  factory ReviewSchedulingBoard.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key] as List<dynamic>? ?? [];
      return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return ReviewSchedulingBoard(
      semesterId: json['semesterId'] as int? ?? 0,
      reviewType: json['reviewType'] as String?,
      weekStart: json['weekStart'] as String?,
      lecturers: mapList('lecturers', SchedulingLecturer.fromJson),
      availability: mapList('availability', (e) {
        return AvailabilityEntry(
          lecturerId: e['lecturerId'] as int? ?? 0,
          dayOfWeek: e['dayOfWeek'] as int? ?? 0,
          slot: e['slot'] as int? ?? 0,
        );
      }),
      groups: mapList('groups', SchedulingGroup.fromJson),
      sessions: mapList('sessions', SchedulingSession.fromJson),
    );
  }

  final int semesterId;
  final String? reviewType;
  final String? weekStart;
  final List<SchedulingLecturer> lecturers;
  final List<AvailabilityEntry> availability;
  final List<SchedulingGroup> groups;
  final List<SchedulingSession> sessions;
}

class AvailabilityEntry {
  const AvailabilityEntry({
    required this.lecturerId,
    required this.dayOfWeek,
    required this.slot,
  });

  final int lecturerId;
  final int dayOfWeek;
  final int slot;
}

class PublishReviewScheduleRequest {
  const PublishReviewScheduleRequest({
    required this.semesterId,
    required this.reviewType,
    required this.weekStart,
    this.subject,
    this.message,
  });

  final int semesterId;
  final String reviewType;
  final String weekStart;
  final String? subject;
  final String? message;

  Map<String, dynamic> toJson() => {
        'semesterId': semesterId,
        'reviewType': reviewType,
        'weekStart': weekStart,
        if (subject != null && subject!.isNotEmpty) 'subject': subject,
        if (message != null && message!.isNotEmpty) 'message': message,
      };
}

class ReviewSchedulePublishResult {
  const ReviewSchedulePublishResult({
    required this.publicationId,
    required this.publishedSessionCount,
    required this.sentEmailCount,
    required this.failedEmailCount,
  });

  factory ReviewSchedulePublishResult.fromJson(Map<String, dynamic> json) {
    return ReviewSchedulePublishResult(
      publicationId: json['publicationId'] as int? ?? 0,
      publishedSessionCount: json['publishedSessionCount'] as int? ?? 0,
      sentEmailCount: json['sentEmailCount'] as int? ?? 0,
      failedEmailCount: json['failedEmailCount'] as int? ?? 0,
    );
  }

  final int publicationId;
  final int publishedSessionCount;
  final int sentEmailCount;
  final int failedEmailCount;
}
