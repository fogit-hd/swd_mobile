import 'package:flutter/material.dart';

import '../review/review_sessions_screen.dart';

class LecturerReviewProjectsScreen extends StatelessWidget {
  const LecturerReviewProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewSessionsScreen(
      title: 'Dự án review',
      subtitle: 'Mở dự án để xem tài liệu, điểm danh và gửi nhận xét',
      emptyMessage: 'Chưa có phiên review nào được gán cho bạn.',
      showAttendance: true,
    );
  }
}
