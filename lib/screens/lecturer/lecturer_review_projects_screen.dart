import 'package:flutter/material.dart';

import '../review/review_sessions_screen.dart';

class LecturerReviewProjectsScreen extends StatelessWidget {
  const LecturerReviewProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewSessionsScreen(
      title: 'Dự án review',
      subtitle: 'Chọn phiên để nhập nhận xét hoặc điểm danh',
      emptyMessage: 'Chưa có phiên review nào được gán cho bạn.',
      showAttendance: true,
    );
  }
}
