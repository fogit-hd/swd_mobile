import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Thẻ trắng có đổ bóng mờ và viền gradient tinh tế — phong cách Stripe Enterprise SaaS.
class EduCard extends StatefulWidget {
  const EduCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<EduCard> createState() => _EduCardState();
}

class _EduCardState extends State<EduCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: _isHovered ? 1.0 : 0.97),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isHovered
              ? AppTheme.accent.withValues(alpha: 0.45)
              : AppTheme.accent.withValues(alpha: 0.14),
          width: _isHovered ? 1.5 : 1.2,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                ...AppTheme.cardShadow,
              ]
            : AppTheme.cardShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (hover) => setState(() => _isHovered = hover),
        onHighlightChanged: (highlight) => setState(() => _isHovered = highlight),
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
          child: card,
        ),
      ),
    );
  }
}

