import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
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
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.35),
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
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: AppAnimations.stagger(1),
                          child: const Text(
                            'CPM System',
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
                            'Đăng nhập tài khoản',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.mediumGray,
                              fontSize: 15,
                            ),
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
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nhập mật khẩu'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeSlideIn(
                          delay: AppAnimations.stagger(5),
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
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delay: AppAnimations.stagger(6),
                          child: Column(
                            children: [
                              const Divider(),
                              const SizedBox(height: 12),
                              const Text(
                                'Hoặc xem UI với dữ liệu mẫu (không cần API)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.mediumGray,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _loading ? null : _enterDemo,
                                icon: const Icon(Icons.science_outlined),
                                label: const Text('Vào chế độ Demo'),
                              ),
                            ],
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
      ),
    );
  }

  void _enterDemo() {
    AuthScope.of(context).enterDemoMode();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
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
