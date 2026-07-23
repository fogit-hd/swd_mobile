import 'package:flutter/material.dart';

import '../models/review_session.dart';
import '../theme/app_theme.dart';

class ReviewSessionCard extends StatelessWidget {
  const ReviewSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.highlight = false,
    this.trailing,
    this.subtitleExtra,
  });

  final ReviewSession session;
  final VoidCallback? onTap;
  final bool highlight;
  final Widget? trailing;
  final String? subtitleExtra;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = session.statusLabel == 'Đã gửi';
    final accentColor = isSubmitted
        ? const Color(0xFF2563EB)
        : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? AppTheme.primary
              : accentColor.withValues(alpha: 0.22),
          width: highlight ? 1.8 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(label: session.statusLabel),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (session.type != null)
                        Text(
                          session.typeLabel,
                          style: const TextStyle(
                            color: AppTheme.darkGray,
                            fontSize: 13.5,
                          ),
                        ),
                      if (session.hasAccessCode) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.isAccessVerified
                              ? 'Đã xác thực mã truy cập'
                              : 'Cần mã truy cập để mở buổi',
                          style: TextStyle(
                            color: session.isAccessVerified
                                ? AppTheme.success
                                : const Color(0xFFD97706),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (session.reviewerCount != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${session.reviewerCount} giảng viên chấm',
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      if (subtitleExtra != null &&
                          subtitleExtra!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitleExtra!,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            iconColor: AppTheme.primary,
                            label: session.timeLabel,
                            expand: true,
                          ),
                          _MetaChip(
                            icon: Icons.meeting_room_rounded,
                            iconColor: AppTheme.accent,
                            label: session.room ?? '—',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.expand = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.darkGray,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    return Container(
      width: expand ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = label == 'Đã gửi';
    final fg = isSubmitted ? AppTheme.white : AppTheme.darkGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSubmitted ? AppTheme.primary : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
