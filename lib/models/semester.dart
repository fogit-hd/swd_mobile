class Semester {
  const Semester({
    required this.id,
    this.code,
    this.name,
    this.academicYear,
    this.isActive = false,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String?,
      name: json['name'] as String?,
      academicYear: json['academicYear'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  final int id;
  final String? code;
  final String? name;
  final String? academicYear;
  final bool isActive;

  String get displayName => name ?? code ?? 'Học kỳ $id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Semester && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
