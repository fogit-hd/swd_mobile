import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Nút sticky cố định đáy màn hình — Accent amber cho hành động chính.
class StickyActionButton extends StatelessWidget {
  const StickyActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secondaryLabel != null) ...[
            SizedBox(
              width: double.infinity,
              height: AppSpacing.minTouchTarget,
              child: OutlinedButton(
                onPressed: loading ? null : onSecondaryPressed,
                child: Text(secondaryLabel ?? ''),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: (onPressed != null && !loading)
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      )
                    : null,
                color: (onPressed == null || loading)
                    ? AppTheme.lightGray
                    : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: (onPressed != null && !loading)
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.38),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : onPressed,
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: AppTheme.white),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
