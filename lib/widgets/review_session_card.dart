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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.schedule_rounded,
                                            size: 14,
                                            color: AppTheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              session.timeLabel,
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
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.meeting_room_rounded,
                                            size: 14,
                                            color: AppTheme.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            session.room ?? '—',
                                            style: const TextStyle(
                                              color: AppTheme.darkGray,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.timeLabel,
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.meeting_room_outlined,
                          size: 16,
                          color: AppTheme.mediumGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.room ?? '—',
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isSubmitted = label == 'Đã gửi';
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
              boxShadow: isSubmitted
                  ? [
                      BoxShadow(
                        color: AppTheme.white.withValues(alpha: 0.8),
                        blurRadius: 3,
                      ),
                    ]
                  : null,
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
