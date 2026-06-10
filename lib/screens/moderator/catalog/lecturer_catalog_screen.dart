import 'package:flutter/material.dart';

import '../../../widgets/placeholder_page.dart';

class LecturerCatalogScreen extends StatelessWidget {
  const LecturerCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      sections: [
        PlaceholderSection(
          title: 'Danh sách giảng viên',
          icon: Icons.list_alt_outlined,
        ),
        PlaceholderSection(
          title: 'Trạng thái tài khoản',
          icon: Icons.toggle_on_outlined,
        ),
        PlaceholderSection(
          title: 'Quyền hội đồng',
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}
