import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../../widgets/animated_bottom_nav.dart';
import '../../widgets/animated_shell_body.dart';
import '../schedule/lecturer_schedule_list_screen.dart';
import '../slot/slot_registration_screen.dart';
import 'lecturer_notifications_screen.dart';
import 'lecturer_review_projects_screen.dart';

/// Shell chính Giảng viên — tập trung đầy đủ vào luồng review checkpoint.
class LecturerShell extends StatefulWidget {
  const LecturerShell({super.key});

  @override
  State<LecturerShell> createState() => _LecturerShellState();
}

class _LecturerShellState extends State<LecturerShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _meshController;

  static const _tabs = [
    (icon: Icons.calendar_month_outlined, label: 'Lịch review'),
    (icon: Icons.rate_review_outlined, label: 'Nhận xét'),
    (icon: Icons.grid_view_rounded, label: 'Đăng ký Slot'),
  ];

  @override
  void initState() {
    super.initState();
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _meshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.isAuthenticated) {
      return const _RedirectToLogin();
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppTheme.white.withValues(alpha: 0.90),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                const SizedBox.expand(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 2.5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF06B6D4),
                          Color(0xFF4F46E5),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Thông báo',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LecturerNotificationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.primary),
            tooltip: 'Đăng xuất',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Điểm nhấn 1: Nền Ambient Mesh Orbs trôi dạt phía sau các trang
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, child) {
              final t = _meshController.value;
              final angle = t * 2 * math.pi;

              return Stack(
                children: [
                  Align(
                    alignment: Alignment(
                      -0.85 + 0.3 * math.sin(angle),
                      -0.7 + 0.2 * math.cos(angle),
                    ),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2563EB).withValues(alpha: 0.12),
                            const Color(0xFF2563EB).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      0.85 - 0.25 * math.cos(angle),
                      0.5 + 0.25 * math.sin(angle),
                    ),
                    child: Container(
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF06B6D4).withValues(alpha: 0.10),
                            const Color(0xFF06B6D4).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      0.1 + 0.35 * math.sin(angle * 1.3),
                      -0.2 + 0.3 * math.cos(angle * 1.3),
                    ),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6366F1).withValues(alpha: 0.09),
                            const Color(0xFF6366F1).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: const SizedBox.expand(),
                  ),
                ],
              );
            },
          ),
          // Điểm nhấn 2: Nội dung nguyên bản không thay đổi logic/layout
          AnimatedShellBody(
            index: _index,
            children: const [
              LecturerScheduleListScreen(),
              LecturerReviewProjectsScreen(),
              LecturerSlotRegistrationScreen(),
            ],
          ),
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
