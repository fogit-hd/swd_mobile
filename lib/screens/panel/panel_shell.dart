import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../../widgets/animated_shell_body.dart';
import 'panel_schedule_screen.dart';
import 'panel_scoring_screen.dart';

class PanelShell extends StatefulWidget {
  const PanelShell({super.key});

  @override
  State<PanelShell> createState() => _PanelShellState();
}

class _PanelShellState extends State<PanelShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.calendar_today_outlined, label: 'Lịch'),
    (icon: Icons.rate_review_outlined, label: 'Chấm điểm'),
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
          PanelScheduleScreen(),
          PanelScoringScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
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
