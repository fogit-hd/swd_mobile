import 'dart:convert';

import '../models/create_review_session.dart';
import '../models/review_availability.dart';
import '../models/review_enums.dart';
import '../models/review_scheduling.dart';
import '../models/review_session.dart';
import '../models/review_submission.dart';
import 'api_client.dart';

class ReviewService {
  ReviewService(this._client);

  final ApiClient _client;

  Future<List<ReviewSession>> fetchMySessions() async {
    final response = await _client.get('/api/review-sessions/my');
    _client.throwIfFailed(response, 'Tải lịch review');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReviewSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewAvailabilityWeek> fetchAvailabilityWeek({
    required int semesterId,
    required String weekStart,
  }) async {
    final response = await _client.get(
      '/api/review-availability/week',
      query: {
        'semesterId': semesterId.toString(),
        'weekStart': weekStart,
      },
    );
    _client.throwIfFailed(response, 'Tải đăng ký slot');

    return ReviewAvailabilityWeek.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewAvailabilityWeek> saveAvailabilityWeek({
    required int semesterId,
    required String weekStart,
    required List<AvailabilitySlot> slots,
  }) async {
    final response = await _client.put(
      '/api/review-availability/week',
      query: {
        'semesterId': semesterId.toString(),
        'weekStart': weekStart,
      },
      body: {'slots': slots.map((s) => s.toJson()).toList()},
    );
    _client.throwIfFailed(response, 'Lưu đăng ký slot');

    return ReviewAvailabilityWeek.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewSchedulingBoard> fetchSchedulingBoard({
    required int semesterId,
    required String reviewType,
    required String weekStart,
  }) async {
    final response = await _client.get(
      '/api/review-scheduling/board',
      query: {
        'semesterId': semesterId.toString(),
        'reviewType': reviewType,
        'weekStart': weekStart,
      },
    );
    _client.throwIfFailed(response, 'Tải bảng xếp lịch');

    return ReviewSchedulingBoard.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewSessionResponse> createSession(
    CreateReviewSessionRequest request,
  ) async {
    final response = await _client.post(
      '/api/review-sessions',
      body: request.toJson(),
    );
    _client.throwIfFailed(response, 'Tạo phiên review');

    return ReviewSessionResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> bulkAssignSessions(List<SchedulingSession> sessions) async {
    final response = await _client.post(
      '/api/review-sessions/bulk-assign',
      body: {
        'sessions': sessions.map((s) => s.toBulkAssignJson()).toList(),
      },
    );
    _client.throwIfFailed(response, 'Lưu xếp lịch');
  }

  Future<void> updateSession(SchedulingSession session) async {
    final response = await _client.patch(
      '/api/review-sessions/${session.id}',
      body: session.toUpdateJson(),
    );
    _client.throwIfFailed(response, 'Cập nhật phiên review');
  }

  Future<ReviewSchedulePublishResult> publishSchedule(
    PublishReviewScheduleRequest request,
  ) async {
    final response = await _client.post(
      '/api/review-schedules/publish',
      body: request.toJson(),
    );
    _client.throwIfFailed(response, 'Công bố lịch');

    return ReviewSchedulePublishResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewSubmission> fetchSubmission(int submissionId) async {
    final response = await _client.get('/api/review-submissions/$submissionId');
    _client.throwIfFailed(response, 'Tải form review');

    return ReviewSubmission.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewSubmission> saveDraft(
    int submissionId,
    ReviewSubmission submission,
  ) async {
    final response = await _client.put(
      '/api/review-submissions/$submissionId/draft',
      body: submission.toDraftJson(),
    );
    _client.throwIfFailed(response, 'Lưu nháp review');

    return ReviewSubmission.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewSubmission> submitReview(int submissionId) async {
    final response = await _client.post(
      '/api/review-submissions/$submissionId/submit',
    );
    _client.throwIfFailed(response, 'Gửi review');

    return ReviewSubmission.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<int>> exportSubmissionXlsx(int submissionId) =>
      _client.download('/api/review-submissions/$submissionId/export.xlsx');

  Future<List<int>> exportSubmissionsZip({
    required int semesterId,
    required String reviewType,
  }) =>
      _client.download(
        '/api/review-submissions/export.zip',
        query: {
          'semesterId': semesterId.toString(),
          'reviewType': reviewType,
        },
      );

  static String defaultReviewType() => ReviewType.defaultType.apiValue;
}
