import 'package:flutter/material.dart';

import '../../../widgets/placeholder_page.dart';

class StudentGroupCatalogScreen extends StatelessWidget {
  const StudentGroupCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      sections: [
        PlaceholderSection(
          title: 'Danh mục sinh viên & nhóm',
          icon: Icons.folder_shared_outlined,
        ),
        PlaceholderSection(
          title: 'Theo dõi trạng thái nộp bài',
          icon: Icons.upload_file_outlined,
        ),
        PlaceholderSection(
          title: 'Công bố kết quả Review',
          icon: Icons.campaign_outlined,
        ),
        PlaceholderSection(
          title: 'Mở khóa / Khóa nộp bài',
          icon: Icons.lock_outline,
        ),
      ],
    );
  }
}
