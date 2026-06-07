import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../config/api_config.dart';
import '../data/mock_data.dart';
import '../models/auth_models.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/scale_tap.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _examinerCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _examinerCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = AuthScope.of(context);

    try {
      await auth.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        examinerCode: _examinerCodeController.text.trim(),
      );
      if (!mounted) return;
      final route = auth.homeRoute;
      if (route == null) {
        auth.logout();
        _showError('Không xác định được role Panel hoặc Moderator.');
        return;
      }
      Navigator.pushReplacementNamed(context, route);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Không kết nối được server. Kiểm tra mạng và thử lại.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _enterDemo(BuildContext context, String route) {
    final auth = AuthScope.of(context);
    auth.enterDemoMode(
      role: route == AppRoutes.moderator
          ? AppRole.moderator
          : AppRole.panel,
    );
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              AppTheme.primary.withValues(alpha: 0.07),
              AppTheme.accent.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideIn(
                        delay: AppAnimations.stagger(0),
                        offset: const Offset(0, -0.08),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.85, end: 1),
                            duration: AppAnimations.slow,
                            curve: Curves.elasticOut,
                            builder: (_, scale, child) =>
                                Transform.scale(scale: scale, child: child),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 40,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(1),
                        child: const Text(
                          'CPMS Mobile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(2),
                        child: const Text(
                          'Đăng nhập để chấm điểm Capstone',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.mediumGray, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(3),
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên đăng nhập',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập tên đăng nhập'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(4),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline),
                            helperText: ApiConfig.useMockData
                                ? 'Mock: panel / moderator — MK ${MockData.demoPassword}'
                                : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Nhập mật khẩu' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(5),
                        child: TextFormField(
                          controller: _examinerCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Mã giám khảo (tuỳ chọn)',
                            prefixIcon: Icon(Icons.badge_outlined),
                            helperText: 'Dùng cho tài khoản hội đồng chấm',
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(6),
                        child: ScaleTap(
                          onTap: _loading ? null : _submit,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: AnimatedSwitcher(
                              duration: AppAnimations.fast,
                              child: _loading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.white,
                                      ),
                                    )
                                  : const Text(
                                      key: ValueKey('label'),
                                      'Đăng nhập',
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(7),
                        child: const Divider(),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(8),
                        child: const Text(
                          'API đang lỗi? Vào demo không cần đăng nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(9),
                        child: ScaleTap(
                          onTap: _loading
                              ? null
                              : () => _enterDemo(context, AppRoutes.panel),
                          child: OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () => _enterDemo(context, AppRoutes.panel),
                            icon: const Icon(Icons.groups_outlined),
                            label: const Text('Vào Hội đồng chấm (demo)'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: AppAnimations.stagger(10),
                        child: ScaleTap(
                          onTap: _loading
                              ? null
                              : () => _enterDemo(context, AppRoutes.moderator),
                          child: OutlinedButton.icon(
                            onPressed: _loading
                                ? null
                                : () => _enterDemo(context, AppRoutes.moderator),
                            icon: const Icon(Icons.admin_panel_settings_outlined),
                            label: const Text('Vào Điều phối viên (demo)'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void logout(BuildContext context) {
  AuthScope.of(context).logout();
  Navigator.pushNamedAndRemoveUntil(
    context,
    AppRoutes.login,
    (_) => false,
  );
}
