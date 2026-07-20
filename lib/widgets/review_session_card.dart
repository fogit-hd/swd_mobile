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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: highlight ? AppTheme.accent : AppTheme.lightGray,
          width: highlight ? 2 : 1,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(label: session.statusLabel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (session.type != null)
                      Text(
                        session.type ?? '',
                        style: const TextStyle(
                          color: AppTheme.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    if (subtitleExtra != null && subtitleExtra!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleExtra!,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 16, color: AppTheme.mediumGray),
                        const SizedBox(width: 4),
                        Text(
                          session.timeLabel,
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.meeting_room_outlined,
                            size: 16, color: AppTheme.mediumGray),
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
              if (trailing != null) trailing!,
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
      child: Text(
        label,
        style: TextStyle(
          color: isSubmitted ? AppTheme.white : AppTheme.darkGray,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
