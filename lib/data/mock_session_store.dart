import 'package:flutter/foundation.dart';

import '../models/evaluation_result.dart';
import '../models/schedule_item.dart';
import 'mock_data.dart';

/// Trạng thái phiên chấm in-memory — thay API khi server lỗi.
class MockSessionStore extends ChangeNotifier {
  MockSessionStore._();

  static final MockSessionStore instance = MockSessionStore._();

  List<ScheduleItem> _items = MockData.initialSchedule();
  final Map<int, EvaluationResult> _evaluations = {};

  List<ScheduleItem> get items => List.unmodifiable(_items);

  EvaluationResult? evaluationFor(int sessionId) => _evaluations[sessionId];

  List<ScheduleItem> snapshot() =>
      _items.map((e) => e.copyWith(status: e.status)).toList();

  void reset() {
    _items = MockData.initialSchedule();
    _evaluations.clear();
    notifyListeners();
  }

  void startSession(int sessionId) {
    final idx = _items.indexWhere((i) => i.sessionId == sessionId);
    if (idx < 0) return;
    _items[idx] = _items[idx].copyWith(status: SessionStatus.inProgress);
    notifyListeners();
  }

  void closeSession(int sessionId) {
    final idx = _items.indexWhere((i) => i.sessionId == sessionId);
    if (idx < 0) return;
    _items[idx] = _items[idx].copyWith(status: SessionStatus.completed);
    notifyListeners();
  }

  void saveEvaluation({
    required int sessionId,
    required EvaluationResult result,
  }) {
    _evaluations[sessionId] = result;
    notifyListeners();
  }
}
