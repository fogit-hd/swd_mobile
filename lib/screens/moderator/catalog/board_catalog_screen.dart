import 'package:flutter/material.dart';

import '../../../widgets/placeholder_page.dart';

class BoardCatalogScreen extends StatelessWidget {
  const BoardCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      sections: [
        PlaceholderSection(
          title: 'Danh sách hội đồng',
          icon: Icons.view_list_outlined,
        ),
        PlaceholderSection(
          title: 'Tạo hội đồng',
          icon: Icons.add_circle_outline,
        ),
        PlaceholderSection(
          title: 'Phân công & vai trò',
          icon: Icons.badge_outlined,
        ),
      ],
    );
  }
}
