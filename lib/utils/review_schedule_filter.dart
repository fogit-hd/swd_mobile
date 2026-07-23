import '../models/review_session.dart';

enum ReviewScheduleScope { today, upcoming, all }

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<ReviewSession> filterReviewSessions(
  Iterable<ReviewSession> sessions,
  ReviewScheduleScope scope, {
  DateTime? now,
}) {
  if (scope == ReviewScheduleScope.all) return sessions.toList();

  final today = _dateOnly(now ?? DateTime.now());
  return sessions.where((session) {
    final date = session.sessionDate;
    if (date == null) return false;
    final difference = _dateOnly(date).difference(today).inDays;
    return switch (scope) {
      ReviewScheduleScope.today => difference == 0,
      ReviewScheduleScope.upcoming => difference > 0,
      ReviewScheduleScope.all => true,
    };
  }).toList();
}
