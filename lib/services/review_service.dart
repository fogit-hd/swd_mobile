import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/review_availability.dart';
import '../models/review_enums.dart';
import '../models/review_round.dart';
import '../models/review_session.dart';
import '../models/review_submission.dart';
import '../models/review_submission_summary.dart';
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

  /// Danh sách nhận xét mà giảng viên đã lưu hoặc gửi.
  Future<List<ReviewSubmissionSummary>> fetchMySubmissions() async {
    final response = await _client.get('/api/review-submissions/my');
    _client.throwIfFailed(response, 'Tải danh sách nhận xét review');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReviewSubmissionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Đợt review theo học kỳ — GV dùng để đăng ký availability (roundId).
  Future<List<ReviewRound>> fetchRounds({required int semesterId}) async {
    final response = await _client.get(
      '/api/review-scheduling/rounds',
      query: {'semesterId': semesterId.toString()},
    );
    _client.throwIfFailed(response, 'Tải đợt review');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ReviewRound.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewAvailabilityWeek> fetchAvailabilityWeek({
    required int roundId,
  }) async {
    final response = await _client.get(
      '/api/review-availability/week',
      query: {'roundId': roundId.toString()},
    );
    _client.throwIfFailed(response, 'Tải đăng ký slot');

    return ReviewAvailabilityWeek.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewAvailabilityWeek> submitAvailabilityWeek({
    required int roundId,
  }) async {
    final response = await _client.post(
      '/api/review-availability/week/submit',
      query: {'roundId': roundId.toString()},
    );
    _client.throwIfFailed(response, 'Gửi đăng ký slot');

    return ReviewAvailabilityWeek.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ReviewAvailabilityWeek> saveAvailabilityWeek({
    required int roundId,
    required List<AvailabilitySlot> slots,
  }) async {
    final response = await _client.put(
      '/api/review-availability/week',
      query: {'roundId': roundId.toString()},
      body: {'slots': slots.map((s) => s.toJson()).toList()},
    );
    _client.throwIfFailed(response, 'Lưu đăng ký slot');

    return ReviewAvailabilityWeek.fromJson(
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

  /// Xuất checklist review ra file Excel tạm trên máy (không phải tài liệu nhóm).
  Future<File> exportSubmissionXlsxToFile(int submissionId) async {
    final bytes = await exportSubmissionXlsx(submissionId);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/review_checklist_$submissionId.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String defaultReviewType() => ReviewType.defaultType.apiValue;
}
