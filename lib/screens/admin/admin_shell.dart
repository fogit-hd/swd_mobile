import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../widgets/animated_shell_body.dart';
import '../../widgets/role_guard.dart';
import '../login_screen.dart';
import '../moderator/moderator_create_account_screen.dart';
import 'admin_accounts_screen.dart';
import 'admin_semester_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.people_outline, label: 'Tài khoản'),
    (icon: Icons.school_outlined, label: 'Học kỳ'),
    (icon: Icons.person_add_outlined, label: 'Tạo TK'),
  ];

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              _tabs[_index].label,
              key: ValueKey(_tabs[_index].label),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () => logout(context),
            ),
          ],
        ),
        body: AnimatedShellBody(
          index: _index,
          children: const [
            AdminAccountsScreen(),
            AdminSemesterScreen(),
            ModeratorCreateAccountScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          items: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            return BottomNavigationBarItem(
              icon: AnimatedNavIcon(icon: tab.icon, selected: _index == i),
              label: tab.label,
            );
          }),
        ),
      ),
    );
  }
}
