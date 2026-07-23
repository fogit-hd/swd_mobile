import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/models/review_session.dart';
import 'package:swd_mobile/utils/review_schedule_filter.dart';

void main() {
  final now = DateTime(2026, 7, 23, 9);
  final sessions = [
    ReviewSession(
      sessionId: 1,
      submissionId: 1,
      sessionDate: DateTime(2026, 7, 22),
    ),
    ReviewSession(
      sessionId: 2,
      submissionId: 2,
      sessionDate: DateTime(2026, 7, 23),
    ),
    ReviewSession(
      sessionId: 3,
      submissionId: 3,
      sessionDate: DateTime(2026, 7, 24),
    ),
    const ReviewSession(sessionId: 4, submissionId: 4),
  ];

  test('review schedule scopes separate today, upcoming and all', () {
    expect(
      filterReviewSessions(
        sessions,
        ReviewScheduleScope.today,
        now: now,
      ).map((session) => session.sessionId),
      [2],
    );
    expect(
      filterReviewSessions(
        sessions,
        ReviewScheduleScope.upcoming,
        now: now,
      ).map((session) => session.sessionId),
      [3],
    );
    expect(
      filterReviewSessions(
        sessions,
        ReviewScheduleScope.all,
        now: now,
      ).map((session) => session.sessionId),
      [1, 2, 3, 4],
    );
  });
}
