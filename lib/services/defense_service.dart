import 'dart:convert';

import '../models/defense_session.dart';
import 'api_client.dart';

class DefenseService {
  DefenseService(this._client);

  final ApiClient _client;

  Future<List<DefenseSessionAssignment>> fetchMyBoardSessions() async {
    final response = await _client.get('/api/defense-management/my-board-sessions');
    _client.throwIfFailed(response, 'Tải lịch hội đồng');

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => DefenseSessionAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> startSession(int sessionId) async {
    final response =
        await _client.post('/api/defense-sessions/$sessionId/start');
    _client.throwIfFailed(response, 'Bắt đầu phiên chấm');
  }

  Future<void> closeSession(int sessionId) async {
    final response =
        await _client.post('/api/defense-sessions/$sessionId/close');
    _client.throwIfFailed(response, 'Kết thúc phiên chấm');
  }

  Future<void> submitScore({
    required int sessionId,
    required int studentId,
    required ScoreType scoreType,
    required double scoreValue,
  }) async {
    final response = await _client.post(
      '/api/defense-sessions/$sessionId/scores',
      body: {
        'studentId': studentId,
        'scoreType': scoreType.apiValue,
        'scoreValue': scoreValue,
      },
    );
    _client.throwIfFailed(response, 'Gửi điểm');
  }
}
