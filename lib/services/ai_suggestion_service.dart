import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' show Response;

import '../models/project_suggestion.dart';
import '../models/review_submission.dart';
import 'api_client.dart';

/// Gợi ý AI hỗ trợ GV — POST /api/project-suggestions/summary (role Lecturer).
class AiSuggestionService {
  AiSuggestionService(this._client);

  final ApiClient _client;

  static const int maxProjectNameLength = 200;
  static const int maxProjectContentLength = 20000;

  /// Gemini trên Render thường mất 20–50s.
  static const Duration _aiTimeout = Duration(seconds: 90);

  /// Gọi Gemini qua BE.
  Future<ProjectSuggestion?> generateSummary({
    required String projectName,
    required String projectContent,
  }) async {
    final name = projectName.trim();
    final content = projectContent.trim();
    if (name.isEmpty || content.isEmpty) {
      throw const AiSuggestionException(
        'Thiếu tên hoặc nội dung đồ án để tạo gợi ý AI.',
      );
    }

    late final Response response;
    try {
      response = await _client
          .post(
            '/api/project-suggestions/summary',
            body: {
              'projectName': _clip(name, maxProjectNameLength),
              'projectContent': _clip(content, maxProjectContentLength),
            },
          )
          .timeout(_aiTimeout);
    } on TimeoutException {
      throw const AiSuggestionException(
        'AI phản hồi quá lâu (>90 giây). Đợi khoảng 1 phút rồi thử lại.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const AiSuggestionException(
          'Phản hồi AI không hợp lệ. Thử lại sau.',
        );
      }
      final suggestion = ProjectSuggestion.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (suggestion.isEmpty) {
        throw const AiSuggestionException(
          'AI không trả về nội dung gợi ý. Thử lại sau.',
        );
      }
      return suggestion;
    }

    throw AiSuggestionException(
      _messageForFailure(response.statusCode, response.body),
    );
  }

  /// Build request từ submission review (checklist + metadata).
  Future<ProjectSuggestion?> generateFromSubmission(
    ReviewSubmission submission, {
    String? fallbackProjectName,
  }) async {
    final name = (submission.projectName?.trim().isNotEmpty == true)
        ? submission.projectName!.trim()
        : (fallbackProjectName?.trim().isNotEmpty == true)
        ? fallbackProjectName!.trim()
        : (submission.groupCode?.trim().isNotEmpty == true)
        ? submission.groupCode!.trim()
        : 'Đồ án #${submission.groupId}';

    final content = buildProjectContent(submission);
    if (content.trim().isEmpty) {
      throw const AiSuggestionException(
        'Chưa có đủ nội dung checklist để AI phân tích.',
      );
    }
    return generateSummary(projectName: name, projectContent: content);
  }

  /// Ghép nội dung checklist thành `projectContent` cho BE.
  static String buildProjectContent(ReviewSubmission submission) {
    final buf = StringBuffer();
    if (submission.groupCode != null &&
        submission.groupCode!.trim().isNotEmpty) {
      buf.writeln('Mã nhóm: ${submission.groupCode}');
    }
    if (submission.type != null && submission.type!.trim().isNotEmpty) {
      buf.writeln('Loại review: ${submission.type}');
    }
    if (submission.workProductVersion != null &&
        submission.workProductVersion!.trim().isNotEmpty) {
      buf.writeln('Phiên bản: ${submission.workProductVersion}');
    }
    if (submission.workProductSize != null &&
        submission.workProductSize!.trim().isNotEmpty) {
      buf.writeln('Quy mô: ${submission.workProductSize}');
    }
    if (submission.effortHours != null) {
      buf.writeln('Effort (giờ): ${submission.effortHours}');
    }

    final checklist = submission.items.where((i) => !i.isSection).toList();
    if (checklist.isNotEmpty) {
      buf.writeln();
      buf.writeln('Checklist:');
      for (final item in checklist) {
        final label = item.label ?? item.itemKey ?? 'Tiêu chí';
        final answer = item.answer?.label ?? 'chưa chấm';
        buf.writeln('- $label: $answer');
        if (item.description != null && item.description!.trim().isNotEmpty) {
          buf.writeln('  Mô tả: ${item.description}');
        }
        if (item.comment != null && item.comment!.trim().isNotEmpty) {
          buf.writeln('  Nhận xét: ${item.comment}');
        }
      }
    }

    if (submission.reviewerComment != null &&
        submission.reviewerComment!.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln('Nhận xét chung hiện có: ${submission.reviewerComment}');
    }
    if (submission.suggestion != null &&
        submission.suggestion!.trim().isNotEmpty) {
      buf.writeln('Gợi ý hiện có: ${submission.suggestion}');
    }

    var text = buf.toString().trim();
    if (text.isEmpty &&
        submission.projectName != null &&
        submission.projectName!.trim().isNotEmpty) {
      text = 'Đồ án: ${submission.projectName}';
    }
    return _clip(text, maxProjectContentLength);
  }

  static String _messageForFailure(int statusCode, String body) {
    final fromBody = _extractApiMessage(body);
    final localized = ApiClient.localizeMessage(fromBody ?? '');
    if (localized.isNotEmpty &&
        localized != 'An unexpected error occurred.' &&
        !localized.toLowerCase().contains('unexpected error')) {
      return localized;
    }

    switch (statusCode) {
      case 401:
        return 'Phiên đăng nhập hết hạn. Đăng nhập lại rồi thử AI gợi ý.';
      case 403:
        return 'Chỉ tài khoản giảng viên mới dùng được AI gợi ý.';
      case 429:
        return 'Bạn gọi AI quá nhanh (giới hạn ~5 lần/phút). Đợi 1 phút rồi thử lại.';
      case 502:
      case 503:
        return 'Gemini đang bận hoặc bị giới hạn tạm thời. '
            'Nếu vừa test Swagger, đợi khoảng 1 phút rồi thử lại trên app.';
      case 500:
      default:
        return 'Máy chủ AI đang lỗi. Thử lại sau ít phút.';
    }
  }

  static String? _extractApiMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final message = decoded['message'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
      final errors = decoded['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map && first['message'] is String) {
          return (first['message'] as String).trim();
        }
      }
    } catch (_) {}
    return null;
  }

  static String _clip(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}

class AiSuggestionException implements Exception {
  const AiSuggestionException(this.message);

  final String message;

  @override
  String toString() => message;
}
