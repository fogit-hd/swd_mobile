import 'dart:convert';

import '../models/review_attendance.dart';
import 'api_client.dart';

class ReviewAttendanceService {
  ReviewAttendanceService(this._client);

  final ApiClient _client;

  Future<ReviewAttendanceList> fetchAttendance(
    int sessionId, {
    int? groupId,
  }) async {
    final response = await _client.get(
      '/api/review-attendance/$sessionId',
      query: {
        if (groupId != null) 'groupId': groupId.toString(),
      },
    );
    _client.throwIfFailed(response, 'Tải điểm danh');

    return ReviewAttendanceList.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewAttendanceList> submitAttendance(
    int sessionId, {
    required int groupId,
    required List<AttendanceStudent> entries,
  }) async {
    final response = await _client.post(
      '/api/review-attendance/$sessionId',
      body: {
        'groupId': groupId,
        'entries': entries.map((e) => e.toEntryJson()).toList(),
      },
    );
    _client.throwIfFailed(response, 'Lưu điểm danh');

    return ReviewAttendanceList.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ReviewComment>> fetchComments(
    int sessionId, {
    int? groupId,
  }) async {
    final response = await _client.get(
      '/api/review-attendance/$sessionId/comments',
      query: {
        if (groupId != null) 'groupId': groupId.toString(),
      },
    );
    _client.throwIfFailed(response, 'Tải nhận xét');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReviewComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewComment> addComment(
    int sessionId, {
    required int groupId,
    required String content,
  }) async {
    final response = await _client.post(
      '/api/review-attendance/$sessionId/comments',
      body: {
        'groupId': groupId,
        'content': content,
      },
    );
    _client.throwIfFailed(response, 'Thêm nhận xét');

    return ReviewComment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Khóa điểm danh / comment của nhóm sau khi kết thúc buổi review.
  Future<void> completeGroupReview({
    required int sessionId,
    required int groupId,
  }) async {
    final response = await _client.post(
      '/api/review-attendance/$sessionId/groups/$groupId/complete',
    );
    _client.throwIfFailed(response, 'Hoàn tất review nhóm');
  }
}
