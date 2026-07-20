import 'package:flutter/material.dart';

import '../../models/project_review_status.dart';
import '../../models/published_schedule.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/edu_card.dart';
import '../../widgets/ui/shimmer_loading.dart';
import '../../widgets/ui/status_badge.dart';

/// Card lịch đã chốt cho Sinh viên — hiển thị nhóm, ngày, slot, phòng, GV review.
/// GV hướng dẫn được hiển thị riêng, KHÔNG nằm trong danh sách reviewer.
class StudentScheduleCardScreen extends StatelessWidget {
  const StudentScheduleCardScreen({
    super.key,
    required this.schedule,
    this.loading = false,
    this.onRefresh,
  });

  final StudentPublishedSchedule? schedule;
  final bool loading;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheduleData = schedule;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        color: AppTheme.primary,
        child: loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.pagePadding,
                children: const [
                  ShimmerLoading(itemCount: 3, itemHeight: 120),
                ],
              )
            : scheduleData == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    children: const [
                      SizedBox(height: 80),
                      Center(
                        child: Text(
                          'Chưa có lịch review được công bố.',
                          style: TextStyle(color: AppTheme.mediumGray),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: AppSpacing.pagePadding,
                    children: [
                      const Text(
                        'Lịch review của nhóm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ScheduleHeroCard(data: scheduleData),
                    ],
                  ),
      ),
    );
  }
}

class _ScheduleHeroCard extends StatelessWidget {
  const _ScheduleHeroCard({required this.data});

  final StudentPublishedSchedule data;

  @override
  Widget build(BuildContext context) {
    return EduCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.groupCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.black,
                  ),
                ),
              ),
              const StatusBadge(
                status: ProjectReviewStatus.inProgress,
                compact: true,
              ),
            ],
          ),
          if (data.groupName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              data.groupName,
              style: const TextStyle(color: AppTheme.mediumGray, fontSize: 14),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(icon: Icons.calendar_today_outlined, label: data.dayLabel),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.schedule_outlined, label: data.slotLabel),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.meeting_room_outlined, label: data.room),
          if (data.supervisorName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.statusPendingBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      size: 18, color: AppTheme.mediumGray),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'GVHD: ${data.supervisorName} (không tham gia chấm)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Hội đồng review',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...data.reviewers.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.statusActiveBg,
                    child: Text(
                      r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (r.department != null)
                          Text(
                            r.department ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
