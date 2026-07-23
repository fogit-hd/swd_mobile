import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../services/auth_service.dart';
import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const _enableQuickLogin = bool.fromEnvironment(
    'ENABLE_LECTURER_QUICK_LOGIN',
  );
  static const _quickLoginUsername = String.fromEnvironment(
    'LECTURER_QUICK_USERNAME',
    defaultValue: 'minhnd.gv24001@fpt.edu.vn',
  );
  static const _quickLoginPassword = String.fromEnvironment(
    'LECTURER_QUICK_PASSWORD',
  );

  static const _showQuickLogin =
      kDebugMode && _enableQuickLogin && _quickLoginPassword != '';

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  late final AnimationController _animController;
  late final AnimationController _tiltController;
  late Animation<double> _tiltXAnimation;
  late Animation<double> _tiltYAnimation;

  double _tiltX = 0.0;
  double _tiltY = 0.0;
  Offset? _pointerPos;
  late final List<_ConstellationParticle> _particles;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _particles = List.generate(32, (index) => _ConstellationParticle.random());
  }

  @override
  void dispose() {
    _animController.dispose();
    _tiltController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset position, Size screenSize) {
    _pointerPos = position;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final dx = (position.dx - center.dx) / (screenSize.width / 2);
    final dy = (position.dy - center.dy) / (screenSize.height / 2);

    setState(() {
      _tiltY = dx * 0.08; // Max 0.08 radians horizontal tilt
      _tiltX = -dy * 0.08; // Max 0.08 radians vertical tilt
    });
  }

  void _onPointerEnd() {
    _pointerPos = null;
    _tiltXAnimation = Tween<double>(begin: _tiltX, end: 0.0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutBack),
    );
    _tiltYAnimation = Tween<double>(begin: _tiltY, end: 0.0).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeOutBack),
    );

    _tiltController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _tiltX = 0.0;
          _tiltY = 0.0;
        });
      }
    });
    _tiltController.addListener(() {
      if (mounted && _tiltController.isAnimating) {
        setState(() {
          _tiltX = _tiltXAnimation.value;
          _tiltY = _tiltYAnimation.value;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await _authenticate(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _quickLogin() async {
    _usernameController.text = _quickLoginUsername;
    _passwordController.text = _quickLoginPassword;

    await _authenticate(
      username: _quickLoginUsername,
      password: _quickLoginPassword,
    );
  }

  Future<void> _authenticate({
    required String username,
    required String password,
  }) async {
    setState(() => _loading = true);
    final auth = AuthScope.of(context);

    try {
      await auth.login(username: username, password: password);
      // AuthRoot (home) tự chuyển sang LecturerShell khi auth notify.
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
    final size = MediaQuery.of(context).size;
    const activeColor = Color(0xFF2563EB);
    const activeGradient = [Color(0xFF2563EB), Color(0xFF4F46E5)];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: Listener(
          onPointerMove: (event) => _onPointerMove(event.position, size),
          onPointerHover: (event) => _onPointerMove(event.position, size),
          onPointerUp: (_) => _onPointerEnd(),
          child: Stack(
            children: [
              // 1. Base Ambient Dark Slate Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
              ),
              // 2. Animated Mesh Floating Spheres & Glassmorphic Backdrop
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final t = _animController.value;
                  final angle = t * 2 * math.pi;

                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment(
                          -0.8 + 0.35 * math.sin(angle),
                          -0.7 + 0.25 * math.cos(angle),
                        ),
                        child: Container(
                          width: 340,
                          height: 340,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                activeColor.withValues(alpha: 0.45),
                                activeColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(
                          0.85 - 0.3 * math.cos(angle),
                          0.65 + 0.2 * math.sin(angle),
                        ),
                        child: Container(
                          width: 380,
                          height: 380,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF06B6D4).withValues(alpha: 0.35),
                                const Color(0xFF06B6D4).withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                        child: const SizedBox.expand(),
                      ),
                      // 3. ĐỘC LẠ: Interactive AI Neural Constellation Canvas
                      CustomPaint(
                        size: size,
                        painter: _NeuralConstellationPainter(
                          particles: _particles,
                          animationValue: t,
                          pointerPos: _pointerPos,
                          accentColor: activeColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
              // 4. Main 3D Holographic Parallax Tilt Card Layout
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Transform(
                        alignment: FractionalOffset.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateX(_tiltX)
                          ..rotateY(_tiltY),
                        child: Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: AppTheme.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: activeColor.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.22),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.4),
                                blurRadius: 60,
                                offset: const Offset(0, 30),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ĐỘC LẠ: Animated Quantum AI Logo Emblem
                                FadeSlideIn(
                                  delay: AppAnimations.stagger(0),
                                  offset: const Offset(0, -0.08),
                                  child: Center(
                                    child: _QuantumLogoEmblem(
                                      animController: _animController,
                                      activeColor: activeColor,
                                      activeGradient: activeGradient,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FadeSlideIn(
                                  delay: AppAnimations.stagger(1),
                                  child: Text(
                                    'Đăng nhập cổng quản lý & đánh giá đồ án',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.darkGray.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 36),
                                FadeSlideIn(
                                  delay: AppAnimations.stagger(3),
                                  child: TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tên đăng nhập',
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: activeColor,
                                      ),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Nhập tên đăng nhập'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FadeSlideIn(
                                  delay: AppAnimations.stagger(4),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Mật khẩu',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                        color: activeColor,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
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
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: activeGradient,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: activeColor.withValues(
                                            alpha: 0.42,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: _loading ? null : _submit,
                                      child: AnimatedSwitcher(
                                        duration: AppAnimations.fast,
                                        child: _loading
                                            ? const SizedBox(
                                                key: ValueKey('loading'),
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: AppTheme.white,
                                                    ),
                                              )
                                            : const Text(
                                                key: ValueKey('label'),
                                                'Đăng nhập ngay',
                                                style: TextStyle(
                                                  color: AppTheme.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_showQuickLogin) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    key: const ValueKey(
                                      'lecturer-quick-login-button',
                                    ),
                                    onPressed: _loading ? null : _quickLogin,
                                    icon: const Icon(Icons.bolt_rounded),
                                    label: const Text(
                                      'Đăng nhập nhanh · Nguyễn Đức Minh',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _quickLoginUsername,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.mediumGray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstellationParticle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;

  _ConstellationParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });

  factory _ConstellationParticle.random() {
    final rnd = math.Random();
    return _ConstellationParticle(
      x: rnd.nextDouble(),
      y: rnd.nextDouble(),
      vx: (rnd.nextDouble() - 0.5) * 0.0012,
      vy: (rnd.nextDouble() - 0.5) * 0.0012,
      radius: 1.5 + rnd.nextDouble() * 2.0,
    );
  }

  void update() {
    x += vx;
    y += vy;
    if (x < 0) x = 1.0;
    if (x > 1.0) x = 0;
    if (y < 0) y = 1.0;
    if (y > 1.0) y = 0;
  }
}

class _NeuralConstellationPainter extends CustomPainter {
  final List<_ConstellationParticle> particles;
  final double animationValue;
  final Offset? pointerPos;
  final Color accentColor;

  _NeuralConstellationPainter({
    required this.particles,
    required this.animationValue,
    required this.pointerPos,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.update();
    }

    final particlePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final positions = particles
        .map((p) => Offset(p.x * size.width, p.y * size.height))
        .toList();

    for (int i = 0; i < particles.length; i++) {
      final posI = positions[i];
      canvas.drawCircle(posI, particles[i].radius, particlePaint);

      // Draw lines to nearby particles
      for (int j = i + 1; j < particles.length; j++) {
        final posJ = positions[j];
        final dist = (posI - posJ).distance;
        if (dist < 130) {
          final alpha = (1.0 - (dist / 130)) * 0.35;
          linePaint.color = accentColor.withValues(alpha: alpha);
          canvas.drawLine(posI, posJ, linePaint);
        }
      }

      // Draw interactive neon beam to pointer if close
      if (pointerPos != null) {
        final distToPointer = (posI - pointerPos!).distance;
        if (distToPointer < 160) {
          final alpha = (1.0 - (distToPointer / 160)) * 0.7;
          linePaint.color = const Color(0xFF38BDF8).withValues(alpha: alpha);
          linePaint.strokeWidth = 1.5;
          canvas.drawLine(posI, pointerPos!, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralConstellationPainter oldDelegate) => true;
}

class _QuantumLogoEmblem extends StatelessWidget {
  const _QuantumLogoEmblem({
    required this.animController,
    required this.activeColor,
    required this.activeGradient,
  });

  final AnimationController animController;
  final Color activeColor;
  final List<Color> activeGradient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final t = animController.value;
        final pulse = math.sin(t * 2 * math.pi);

        return SizedBox(
          width: 115,
          height: 115,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Quỹ đạo Photon Halo xoay 360 độ độc lạ
              CustomPaint(
                size: const Size(115, 115),
                painter: _QuantumHaloPainter(progress: t, color: activeColor),
              ),
              // 2. Thẻ Squircle 3D Holographic nổi ở trung tâm
              Transform.translate(
                offset: Offset(0, -4 * pulse),
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0F172A),
                        activeColor,
                        const Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.65),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(
                          alpha: 0.55 + 0.15 * pulse,
                        ),
                        blurRadius: 28 + 8 * pulse,
                        offset: Offset(0, 12 + 4 * pulse),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // AI Core Glow
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.white.withValues(alpha: 0.15),
                        ),
                      ),
                      // Icon Mũ Cử Nhân AI
                      const Icon(
                        Icons.school_rounded,
                        size: 42,
                        color: AppTheme.white,
                      ),
                      const Positioned(
                        right: 18,
                        top: 18,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Color(0xFFFACC15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuantumHaloPainter extends CustomPainter {
  _QuantumHaloPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = ui.Gradient.sweep(
        center,
        [
          color.withValues(alpha: 0.0),
          const Color(0xFF38BDF8).withValues(alpha: 0.85),
          color.withValues(alpha: 0.0),
        ],
        [0.0, 0.5, 1.0],
        TileMode.clamp,
        progress * 2 * math.pi,
        (progress + 1) * 2 * math.pi,
      );

    canvas.drawCircle(center, radius, ringPaint);

    // 3 Hạt Photon bay vòng quanh
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final angle = progress * 2 * math.pi + (i * 2 * math.pi / 3);
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);

      dotPaint.color = const Color(0xFF38BDF8);
      canvas.drawCircle(Offset(px, py), 3, dotPaint);

      dotPaint.color = const Color(0xFF38BDF8).withValues(alpha: 0.4);
      canvas.drawCircle(Offset(px, py), 7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumHaloPainter oldDelegate) => true;
}

void logout(BuildContext context) {
  // Đóng mọi route đã push (thông báo, chi tiết…) trước khi clear session,
  // rồi để AuthRoot đổi về LoginScreen — không recreate MaterialApp.
  final navigator = Navigator.of(context);
  navigator.popUntil((route) => route.isFirst);
  AuthScope.of(context).logout();
}
