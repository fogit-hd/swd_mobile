/// Response từ POST /api/project-suggestions/summary (Lecturer).
class ProjectSuggestion {
  const ProjectSuggestion({
    required this.contentSummary,
    required this.strengthsSummary,
    required this.improvementSummary,
  });

  factory ProjectSuggestion.fromJson(Map<String, dynamic> json) {
    return ProjectSuggestion(
      contentSummary: (json['contentSummary'] as String?)?.trim() ?? '',
      strengthsSummary: (json['strengthsSummary'] as String?)?.trim() ?? '',
      improvementSummary: (json['improvementSummary'] as String?)?.trim() ?? '',
    );
  }

  /// Fallback khi chỉ có một chuỗi (demo / submission.suggestion).
  factory ProjectSuggestion.fromPlainText(String text) {
    final trimmed = text.trim();
    return ProjectSuggestion(
      contentSummary: trimmed,
      strengthsSummary: '',
      improvementSummary: '',
    );
  }

  final String contentSummary;
  final String strengthsSummary;
  final String improvementSummary;

  bool get isEmpty =>
      contentSummary.isEmpty &&
      strengthsSummary.isEmpty &&
      improvementSummary.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Text gộp để hiển thị / ghi chú nhanh.
  String get displayText {
    final parts = <String>[];
    if (contentSummary.isNotEmpty) {
      parts.add(contentSummary);
    }
    if (strengthsSummary.isNotEmpty) {
      parts.add('Điểm mạnh: $strengthsSummary');
    }
    if (improvementSummary.isNotEmpty) {
      parts.add('Cần cải thiện: $improvementSummary');
    }
    return parts.join('\n\n');
  }
}
