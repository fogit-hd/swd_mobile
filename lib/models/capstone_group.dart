class CapstoneGroupMember {
  const CapstoneGroupMember({
    required this.id,
    this.code,
    this.fullName,
    this.classCode,
    this.major,
    this.email,
    this.isLeader = false,
  });

  factory CapstoneGroupMember.fromJson(Map<String, dynamic> json) {
    return CapstoneGroupMember(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      fullName: json['fullName'] as String?,
      classCode: json['classCode'] as String?,
      major: json['major'] as String?,
      email: json['email'] as String?,
      isLeader: json['isLeader'] as bool? ?? false,
    );
  }

  final int id;
  final String? code;
  final String? fullName;
  final String? classCode;
  final String? major;
  final String? email;
  final bool isLeader;

  String get displayName => fullName ?? code ?? 'SV #$id';
}

class CapstoneGroup {
  const CapstoneGroup({
    required this.id,
    this.code,
    this.topicName,
    this.supervisorName,
    this.status,
    this.members = const [],
  });

  factory CapstoneGroup.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    return CapstoneGroup(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      topicName: json['topicName'] as String?,
      supervisorName: json['supervisorName'] as String?,
      status: json['status'] as String?,
      members: membersJson
          .map((e) => CapstoneGroupMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String? code;
  final String? topicName;
  final String? supervisorName;
  final String? status;
  final List<CapstoneGroupMember> members;
}
