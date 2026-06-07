import '../config/api_config.dart';
import '../data/mock_session_store.dart';
import '../models/defense_session.dart';
import '../models/evaluation_result.dart';
import '../models/schedule_item.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/defense_service.dart';

class SessionRepository {
  SessionRepository(this._auth);

  final AuthService _auth;

  MockSessionStore get _store => MockSessionStore.instance;

  List<ScheduleItem> get scheduleSync {
    if (ApiConfig.useMockData) {
      return _store.snapshot();
    }
    return const [];
  }

  Future<List<ScheduleItem>> fetchSchedule() async {
    if (ApiConfig.useMockData) {
      return _store.snapshot();
    }

    final service = DefenseService(ApiClient(_auth));
    final sessions = await service.fetchMyBoardSessions();
    return sessions.map((s) => s.toScheduleItem()).toList();
  }

  Future<void> startSession(int sessionId) async {
    if (ApiConfig.useMockData) {
      _store.startSession(sessionId);
      return;
    }
    await DefenseService(ApiClient(_auth)).startSession(sessionId);
  }

  Future<void> closeSession(int sessionId) async {
    if (ApiConfig.useMockData) {
      _store.closeSession(sessionId);
      return;
    }
    await DefenseService(ApiClient(_auth)).closeSession(sessionId);
  }

  Future<void> submitEvaluation({
    required int sessionId,
    required int groupId,
    required EvaluationResult result,
  }) async {
    if (ApiConfig.useMockData) {
      _store.saveEvaluation(sessionId: sessionId, result: result);
      return;
    }

    await DefenseService(ApiClient(_auth)).submitScore(
      sessionId: sessionId,
      studentId: groupId,
      scoreType: ScoreType.baoVe,
      scoreValue: result == EvaluationResult.pass ? 10 : 0,
    );
  }

  EvaluationResult? savedEvaluation(int sessionId) =>
      _store.evaluationFor(sessionId);
}
