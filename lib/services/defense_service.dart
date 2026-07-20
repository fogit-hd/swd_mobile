import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/defense.dart';
import 'api_client.dart';

class DefenseService {
  DefenseService(this._client);

  final ApiClient _client;

  Future<List<DefenseSessionAssignment>> fetchMyBoardSessions() async {
    final response =
        await _client.get('/api/defense-management/my-board-sessions');
    _client.throwIfFailed(response, 'Tải lịch hội đồng bảo vệ');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => DefenseSessionAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DefenseSessionState> resolveByCode(String code) async {
    final response = await _client.get(
      '/api/defense-sessions/resolve/${Uri.encodeComponent(code)}',
    );
    _client.throwIfFailed(response, 'Tra cứu phiên bảo vệ');

    return DefenseSessionState.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DefenseSessionState> startSession(int sessionId) async {
    final response =
        await _client.post('/api/defense-sessions/$sessionId/start');
    _client.throwIfFailed(response, 'Bắt đầu phiên bảo vệ');

    return DefenseSessionState.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DefenseSessionState> closeSession(int sessionId) async {
    final response =
        await _client.post('/api/defense-sessions/$sessionId/close');
    _client.throwIfFailed(response, 'Kết thúc phiên bảo vệ');

    return DefenseSessionState.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SubmittedScore> submitScore({
    required int sessionId,
    required int studentId,
    required String scoreType,
    required double scoreValue,
  }) async {
    final response = await _client.post(
      '/api/defense-sessions/$sessionId/scores',
      body: {
        'studentId': studentId,
        'scoreType': scoreType,
        'scoreValue': scoreValue,
      },
    );
    _client.throwIfFailed(response, 'Gửi điểm');

    return SubmittedScore.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<DefenseEvidence>> fetchEvidences(int sessionId) async {
    final response =
        await _client.get('/api/defense-sessions/$sessionId/evidences');
    _client.throwIfFailed(response, 'Tải minh chứng');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => DefenseEvidence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Upload ảnh minh chứng (multipart: `file` + `note` tùy chọn).
  Future<DefenseEvidence> uploadEvidence({
    required int sessionId,
    required List<int> bytes,
    required String fileName,
    String? note,
  }) async {
    final response = await _client.postMultipart(
      '/api/defense-sessions/$sessionId/evidences',
      files: [
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      ],
      fields: {
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    _client.throwIfFailed(response, 'Upload minh chứng');

    return DefenseEvidence.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
