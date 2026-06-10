class CreateSemesterRequest {
  const CreateSemesterRequest({
    required this.code,
    required this.name,
    required this.academicYear,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  final String code;
  final String name;
  final String academicYear;
  final String startDate;
  final String endDate;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'academicYear': academicYear,
        'startDate': startDate,
        'endDate': endDate,
        'isActive': isActive,
      };
}
