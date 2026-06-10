import 'package:flutter/material.dart';

import '../../utils/review_filters.dart';
import '../review/review_sessions_screen.dart';

class PanelScheduleScreen extends StatelessWidget {
  const PanelScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewSessionsScreen(
      title: 'Lịch review đã công bố',
      subtitle: 'Các phiên review trong tuần',
      emptyMessage: 'Chưa có lịch review được công bố.',
      filter: publishedReviewOnly,
      readOnly: true,
    );
  }
}
