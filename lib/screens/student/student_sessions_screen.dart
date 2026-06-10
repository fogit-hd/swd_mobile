import 'package:flutter/material.dart';

import '../../utils/review_filters.dart';
import '../review/review_sessions_screen.dart';

class StudentSessionsScreen extends StatelessWidget {
  const StudentSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewSessionsScreen(
      title: 'Lịch review của nhóm',
      subtitle: 'Xem kết quả review sau khi giảng viên đã gửi nhận xét',
      emptyMessage: 'Chưa có phiên review nào cho nhóm của bạn.',
      readOnly: true,
      filter: submittedReviewOnly,
    );
  }
}
