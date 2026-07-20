import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../login_screen.dart';
import '../../widgets/animated_bottom_nav.dart';
import '../../widgets/animated_shell_body.dart';
import '../schedule/lecturer_schedule_list_screen.dart';
import '../slot/slot_registration_screen.dart';
import 'lecturer_defense_sessions_screen.dart';
import 'lecturer_review_projects_screen.dart';

/// Shell chính Giảng viên — 4 tab theo flow nghiệp vụ review.
class LecturerShell extends StatefulWidget {
  const LecturerShell({super.key});

  @override
  State<LecturerShell> createState() => _LecturerShellState();
}

class _LecturerShellState extends State<LecturerShell> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.calendar_month_outlined, label: 'Lịch chấm'),
    (icon: Icons.rate_review_outlined, label: 'Dự án review'),
    (icon: Icons.grid_view_rounded, label: 'Đăng ký ca'),
    (icon: Icons.gavel_outlined, label: 'Bảo vệ'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.isAuthenticated) {
      return const _RedirectToLogin();
    }

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
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
          if (auth.isDemoMode)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Chip(
                label: Text('Chế độ demo', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
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
          LecturerScheduleListScreen(),
          LecturerReviewProjectsScreen(),
          LecturerSlotRegistrationScreen(),
          LecturerDefenseSessionsScreen(),
        ],
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        tabs: _tabs,
      ),
    );
  }
}

class _RedirectToLogin extends StatefulWidget {
  const _RedirectToLogin();

  @override
  State<_RedirectToLogin> createState() => _RedirectToLoginState();
}

class _RedirectToLoginState extends State<_RedirectToLogin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) logout(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
