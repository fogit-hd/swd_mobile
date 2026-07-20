class ReviewAttendanceList {
  const ReviewAttendanceList({
    required this.sessionId,
    this.sessionCode,
    required this.groupId,
    this.groupCode,
    this.groupStatus,
    this.sessionDate,
    this.slot,
    this.room,
    this.students = const [],
  });

  factory ReviewAttendanceList.fromJson(Map<String, dynamic> json) {
    final students = json['students'] as List<dynamic>? ?? [];
    return ReviewAttendanceList(
      sessionId: json['sessionId'] as int? ?? 0,
      sessionCode: json['sessionCode'] as String?,
      groupId: json['groupId'] as int? ?? 0,
      groupCode: json['groupCode'] as String?,
      groupStatus: json['groupStatus'] as String?,
      sessionDate: json['sessionDate'] != null
          ? DateTime.tryParse(json['sessionDate'] as String)
          : null,
      slot: json['slot'] as int?,
      room: json['room'] as String?,
      students: students
          .map((e) => AttendanceStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int sessionId;
  final String? sessionCode;
  final int groupId;
  final String? groupCode;
  final String? groupStatus;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final List<AttendanceStudent> students;

  bool get isGroupCompleted => groupStatus == 'Completed';
}

class AttendanceStudent {
  const AttendanceStudent({
    required this.studentId,
    this.studentCode,
    this.fullName,
    this.isPresent,
    this.note,
  });

  factory AttendanceStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceStudent(
      studentId: json['studentId'] as int? ?? 0,
      studentCode: json['studentCode'] as String?,
      fullName: json['fullName'] as String?,
      isPresent: json['isPresent'] as bool?,
      note: json['note'] as String?,
    );
  }

  final int studentId;
  final String? studentCode;
  final String? fullName;
  final bool? isPresent;
  final String? note;

  Map<String, dynamic> toEntryJson() => {
        'studentId': studentId,
        'isPresent': isPresent ?? false,
        if (note != null && note!.isNotEmpty) 'note': note,
      };
}

class ReviewComment {
  const ReviewComment({
    required this.id,
    required this.authorUserId,
    this.authorName,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory ReviewComment.fromJson(Map<String, dynamic> json) {
    return ReviewComment(
      id: json['id'] as int? ?? 0,
      authorUserId: json['authorUserId'] as int? ?? 0,
      authorName: json['authorName'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  final int id;
  final int authorUserId;
  final String? authorName;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
