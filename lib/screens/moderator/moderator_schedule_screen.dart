import 'package:flutter/material.dart';

import '../review/review_sessions_screen.dart';

class ModeratorScheduleScreen extends StatelessWidget {
  const ModeratorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewSessionsScreen(
      title: 'Lịch review',
      subtitle: 'Tổng quan các phiên review trong hệ thống',
      emptyMessage: 'Chưa có phiên review.',
      readOnly: true,
    );
  }
}
