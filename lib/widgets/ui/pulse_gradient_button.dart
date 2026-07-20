import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Nút gradient với hiệu ứng pulse nhẹ — "Kết Thúc Review".
class PulseGradientButton extends StatefulWidget {
  const PulseGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.colors = const [Color(0xFF0284C7), Color(0xFF0369A1)],
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final List<Color> colors;

  @override
  State<PulseGradientButton> createState() => _PulseGradientButtonState();
}

class _PulseGradientButtonState extends State<PulseGradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1.0 + (_pulse.value * 0.015);
        return Transform.scale(
          scale: widget.loading ? 1.0 : scale,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.minTouchTarget + 4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.colors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.colors.first.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.loading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
