import '../utils/display_labels.dart';

/// Metadata tài liệu đồ án từ GET /api/documents/group/{groupId}.
class ProjectDocument {
  const ProjectDocument({
    required this.id,
    required this.groupId,
    this.docType,
    this.fileName,
    this.fileSize = 0,
    this.versionNo = 1,
    this.status,
    this.uploadedAt,
    this.uploadedById,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      id: json['id'] as int? ?? 0,
      groupId: json['groupId'] as int? ?? 0,
      docType: json['docType'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      versionNo: json['versionNo'] as int? ?? 1,
      status: json['status'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
      uploadedById: json['uploadedById'] as int?,
    );
  }

  final int id;
  final int groupId;
  final String? docType;
  final String? fileName;
  final int fileSize;
  final int versionNo;
  final String? status;
  final DateTime? uploadedAt;
  final int? uploadedById;

  String get title => fileName ?? 'Tài liệu #$id';

  String get docTypeLabel => DisplayLabels.documentType(docType);

  String get statusLabel => DisplayLabels.documentStatus(status);

  String get sizeLabel {
    if (fileSize <= 0) return '—';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get versionLabel => 'v$versionNo';

  bool get canAnalyzeWithAi {
    final name = (fileName ?? '').toLowerCase();
    return name.endsWith('.pdf') ||
        name.endsWith('.docx') ||
        name.endsWith('.txt');
  }
}
