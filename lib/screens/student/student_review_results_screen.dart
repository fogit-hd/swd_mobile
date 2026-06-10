import 'package:flutter/material.dart';

import '../../widgets/placeholder_page.dart';

class StudentReviewResultsScreen extends StatelessWidget {
  const StudentReviewResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      sections: [
        PlaceholderSection(
          title: 'Checklist review',
          icon: Icons.checklist_outlined,
        ),
        PlaceholderSection(
          title: 'Kết quả review',
          icon: Icons.fact_check_outlined,
        ),
        PlaceholderSection(
          title: 'Nhận xét của Giảng viên',
          icon: Icons.comment_outlined,
        ),
      ],
    );
  }
}
