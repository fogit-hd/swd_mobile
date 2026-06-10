import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

class LecturerReviewProjectsScreen extends StatelessWidget {
  const LecturerReviewProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      sections: [
        PlaceholderSection(
          title: 'Danh sách dự án cần review',
          icon: Icons.folder_open_outlined,
        ),
        PlaceholderSection(
          title: 'Xem bài nộp của Sinh viên',
          icon: Icons.download_outlined,
        ),
        PlaceholderSection(
          title: 'Review theo Checklist',
          icon: Icons.checklist_outlined,
        ),
        PlaceholderSection(
          title: 'Ghi nhận xét review',
          icon: Icons.comment_outlined,
        ),
      ],
    );
  }
}
