class DefenseSessionAssignment {
  const DefenseSessionAssignment({
    required this.id,
    this.code,
    required this.defenseRoundId,
    required this.councilId,
    this.councilCode,
    required this.groupId,
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
      code: json['code'] as String?,
      defenseRoundId: json['defenseRoundId'] as int? ?? 0,
      councilId: json['councilId'] as int? ?? 0,
      councilCode: json['councilCode'] as String?,
      groupId: json['groupId'] as int? ?? 0,
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
  final String? code;
  final int defenseRoundId;
  final int councilId;
  final String? councilCode;
  final int groupId;
  final String? groupCode;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isLocked;

  String get title => groupCode ?? code ?? 'Phiên BV #$id';
  bool get isStarted => startedAt != null;
  bool get isEnded => endedAt != null;
}

class DefenseSessionState {
  const DefenseSessionState({
    required this.sessionId,
    this.sessionCode,
    required this.defenseRoundId,
    required this.councilId,
    this.councilCode,
    required this.groupId,
    this.sessionDate,
    this.slot,
    this.room,
    this.startedAt,
    this.endedAt,
    this.isLocked = false,
    this.isChairman = false,
  });

  factory DefenseSessionState.fromJson(Map<String, dynamic> json) {
    return DefenseSessionState(
      sessionId: json['sessionId'] as int? ?? 0,
      sessionCode: json['sessionCode'] as String?,
      defenseRoundId: json['defenseRoundId'] as int? ?? 0,
      councilId: json['councilId'] as int? ?? 0,
      councilCode: json['councilCode'] as String?,
      groupId: json['groupId'] as int? ?? 0,
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
      isChairman: json['isChairman'] as bool? ?? false,
    );
  }

  final int sessionId;
  final String? sessionCode;
  final int defenseRoundId;
  final int councilId;
  final String? councilCode;
  final int groupId;
  final DateTime? sessionDate;
  final int? slot;
  final String? room;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isLocked;
  final bool isChairman;
}

class DefenseEvidence {
  const DefenseEvidence({
    required this.id,
    required this.defenseSessionId,
    required this.capturedByLecturerId,
    this.fileName,
    this.filePath,
    this.contentType,
    this.fileSize,
    this.note,
    this.capturedAt,
  });

  factory DefenseEvidence.fromJson(Map<String, dynamic> json) {
    return DefenseEvidence(
      id: json['id'] as int? ?? 0,
      defenseSessionId: json['defenseSessionId'] as int? ?? 0,
      capturedByLecturerId: json['capturedByLecturerId'] as int? ?? 0,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
      contentType: json['contentType'] as String?,
      fileSize: json['fileSize'] as int?,
      note: json['note'] as String?,
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'] as String)
          : null,
    );
  }

  final int id;
  final int defenseSessionId;
  final int capturedByLecturerId;
  final String? fileName;
  final String? filePath;
  final String? contentType;
  final int? fileSize;
  final String? note;
  final DateTime? capturedAt;
}

class SubmittedScore {
  const SubmittedScore({
    required this.sessionId,
    required this.scoreId,
    required this.scorerId,
    required this.studentId,
    this.scoreType,
    this.scoreValue,
    this.submittedAt,
  });

  factory SubmittedScore.fromJson(Map<String, dynamic> json) {
    return SubmittedScore(
      sessionId: json['sessionId'] as int? ?? 0,
      scoreId: json['scoreId'] as int? ?? 0,
      scorerId: json['scorerId'] as int? ?? 0,
      studentId: json['studentId'] as int? ?? 0,
      scoreType: json['scoreType'] as String?,
      scoreValue: (json['scoreValue'] as num?)?.toDouble(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
    );
  }

  final int sessionId;
  final int scoreId;
  final int scorerId;
  final int studentId;
  final String? scoreType;
  final double? scoreValue;
  final DateTime? submittedAt;
}
