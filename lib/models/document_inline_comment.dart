class DocumentInlineComment {
  const DocumentInlineComment({
    required this.id,
    required this.documentId,
    required this.authorId,
    this.authorName,
    required this.content,
    this.reference,
    this.paragraphIndex,
    this.status,
    this.createdAt,
  });

  factory DocumentInlineComment.fromJson(Map<String, dynamic> json) {
    return DocumentInlineComment(
      id: json['id'] as int? ?? 0,
      documentId: json['documentId'] as int? ?? 0,
      authorId: json['authorId'] as int? ?? 0,
      authorName: json['authorName'] as String?,
      content: json['content'] as String? ?? '',
      reference: json['reference'] as String?,
      paragraphIndex: json['paragraphIndex'] as int?,
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  final int id;
  final int documentId;
  final int authorId;
  final String? authorName;
  final String content;
  final String? reference;
  final int? paragraphIndex;
  final String? status;
  final DateTime? createdAt;
}
