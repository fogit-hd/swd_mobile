import 'package:flutter_test/flutter_test.dart';
import 'package:swd_mobile/models/review_submission_summary.dart';

void main() {
  test('parses the current lecturer submission summary contract', () {
    final summary = ReviewSubmissionSummary.fromJson({
      'id': 31,
      'sessionId': 12,
      'groupId': 8,
      'reviewType': 'Review2',
      'status': 'Submitted',
      'reviewerName': 'Nguyễn Văn Minh',
      'notes': 'Nhóm cần làm rõ phạm vi.',
      'submittedAt': '2026-07-23T09:30:00Z',
    });

    expect(summary.id, 31);
    expect(summary.sessionId, 12);
    expect(summary.groupId, 8);
    expect(summary.reviewerName, 'Nguyễn Văn Minh');
    expect(summary.notes, 'Nhóm cần làm rõ phạm vi.');
    expect(summary.isSubmitted, isTrue);
  });
}
