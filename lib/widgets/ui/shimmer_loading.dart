import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Hiệu ứng Shimmer tự build — không cần package ngoài.
/// Dùng khi danh sách slot/sinh viên đang tải.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 72,
  });

  final int itemCount;
  final double itemHeight;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: List.generate(widget.itemCount, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ShimmerBar(
                progress: (_controller.value + i * 0.12) % 1.0,
                height: widget.itemHeight,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.progress, required this.height});

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.statusPendingBg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final shimmerWidth = width * 0.45;
            final left = (width + shimmerWidth) * progress - shimmerWidth;
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: shimmerWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.white.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Shimmer cho ma trận 6×5 ô vuông.
class ShimmerSlotMatrix extends StatelessWidget {
  const ShimmerSlotMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(itemCount: 5, itemHeight: 56);
  }
}
