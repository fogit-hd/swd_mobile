import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../../widgets/animated_shell_body.dart';
import 'moderator_create_account_screen.dart';
import 'moderator_schedule_screen.dart';
import 'moderator_session_screen.dart';

class ModeratorShell extends StatefulWidget {
  const ModeratorShell({super.key});

  @override
  State<ModeratorShell> createState() => _ModeratorShellState();
}

class _ModeratorShellState extends State<ModeratorShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.calendar_today_outlined, label: 'Lịch'),
    (icon: Icons.play_circle_outline, label: 'Điều phối'),
    (icon: Icons.person_add_outlined, label: 'Tạo TK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ModeratorScheduleScreen(),
          ModeratorSessionScreen(),
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
    );
  }
}
