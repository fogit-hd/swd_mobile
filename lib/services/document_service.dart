import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/project_document.dart';
import '../models/project_suggestion.dart';
import 'api_client.dart';

/// API tài liệu đồ án — chỉ thao tác quyền Giảng viên (xem/tải/AI).
/// Không gọi POST /api/documents (upload dành cho Student).
class DocumentService {
  DocumentService(this._client);

  final ApiClient _client;

  static const Duration _aiTimeout = Duration(seconds: 90);

  Future<List<ProjectDocument>> listByGroup(int groupId) async {
    final response = await _client.get('/api/documents/group/$groupId');
    _client.throwIfFailed(response, 'Tải danh sách tài liệu');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProjectDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tải file về thư mục tạm của máy, trả đường dẫn local.
  Future<File> downloadToTemp(ProjectDocument document) async {
    final bytes = await _client.download(
      '/api/documents/${document.id}/download',
    );

    final dir = await getTemporaryDirectory();
    final safeName = _safeFileName(document.fileName ?? 'document_${document.id}');
    final file = File('${dir.path}/${document.id}_$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// POST /api/documents/{id}/suggestions — Lecturer only.
  Future<ProjectSuggestion> analyzeWithAi(int documentId) async {
    late final http.Response response;
    try {
      response = await _client
          .post('/api/documents/$documentId/suggestions')
          .timeout(_aiTimeout);
    } on TimeoutException {
      throw ApiException(
        'AI phân tích quá lâu (>90 giây). Đợi rồi thử lại.',
        statusCode: 408,
      );
    }

    if (response.statusCode >= 400) {
      _client.throwIfFailed(response, 'AI phân tích tài liệu');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw ApiException('Phản hồi AI không hợp lệ.', statusCode: response.statusCode);
    }
    final suggestion = ProjectSuggestion.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    if (suggestion.isEmpty) {
      throw ApiException('AI không trả về nội dung phân tích.');
    }
    return suggestion;
  }

  static String _safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'document.bin' : cleaned;
  }
}
