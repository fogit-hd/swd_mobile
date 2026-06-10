import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/auth_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_bottom_nav.dart';
import '../../widgets/animated_shell_body.dart';
import '../../widgets/role_guard.dart';
import '../login_screen.dart';
import 'student_defense_schedule_screen.dart';
import 'student_review_results_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.calendar_month_outlined, label: 'Lịch bảo vệ'),
    (icon: Icons.rate_review_outlined, label: 'Kết quả review'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final isGuest = auth.isDemoGuest;

    return RoleGuard(
      allowedRole: AppRole.student,
      child: Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              _tabs[_index].label,
              key: ValueKey(_tabs[_index].label),
            ),
          ),
          actions: [
            if (isGuest)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Chip(
                  label: Text('Guest', style: TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.white,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
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
            StudentDefenseScheduleScreen(),
            StudentReviewResultsScreen(),
          ],
        ),
        bottomNavigationBar: AnimatedBottomNavBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          tabs: _tabs,
        ),
      ),
    );
  }
}
