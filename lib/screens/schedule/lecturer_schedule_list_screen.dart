import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../data/mock_sample_data.dart';
import '../../models/project_review_status.dart';
import '../../models/published_schedule.dart';
import '../../models/review_session.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../utils/display_labels.dart';
import '../../utils/week_utils.dart';
import '../../widgets/ui/edu_card.dart';
import '../../widgets/ui/shimmer_loading.dart';
import '../../widgets/ui/status_badge.dart';
import '../review/review_live_session_screen.dart';

/// Danh sách slot Giảng viên phải đi chấm — tối đa 3 nhóm/slot, sắp theo thời gian.
class LecturerScheduleListScreen extends StatefulWidget {
  const LecturerScheduleListScreen({super.key});

  @override
  State<LecturerScheduleListScreen> createState() =>
      _LecturerScheduleListScreenState();
}

class _LecturerScheduleListScreenState extends State<LecturerScheduleListScreen> {
  List<LecturerReviewSlot>? _slots;
  bool _loading = true;
  String? _error;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (auth.isDemoMode) {
      setState(() {
        _slots = _groupSessions(MockSampleData.lecturerSessions);
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthScope.of(context);
      final sessions =
          await ReviewService(ApiClient(auth)).fetchMySessions();
      if (!mounted) return;
      setState(() {
        _slots = _groupSessions(sessions);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<LecturerReviewSlot> _groupSessions(List<ReviewSession> sessions) {
    final published =
        sessions.where((s) => s.isPublished || s.canEditReview).toList();
    published.sort((a, b) {
      final da = a.sessionDate ?? DateTime(2100);
      final db = b.sessionDate ?? DateTime(2100);
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
      return (a.slot ?? 0).compareTo(b.slot ?? 0);
    });

    final map = <String, List<ReviewSession>>{};
    for (final s in published) {
      final date = s.sessionDate;
      final key = '${date?.toIso8601String().split('T').first}_${s.slot ?? 0}';
      map.putIfAbsent(key, () => []).add(s);
    }

    return map.entries.map((e) {
      final first = e.value.first;
      final date = first.sessionDate;
      final slot = first.slot ?? 0;
      return LecturerReviewSlot(
        dayLabel: date != null
            ? '${dayLabel(date.weekday)} ${date.day}/${date.month}'
            : '—',
        slotLabel: slot == 5 ? 'Ca Tối' : 'Ca $slot',
        room: first.room ?? '—',
        sessionDate: date,
        sortKey: date?.millisecondsSinceEpoch ?? 0,
        groups: e.value
            .map(
              (s) => LecturerReviewGroup(
                groupCode: s.groupCode ?? s.title,
                topicName: (s.topicName != null && s.topicName!.trim().isNotEmpty)
                    ? s.topicName!.trim()
                    : _reviewTypeLabel(s.type),
                status: s.isSubmitted
                    ? ProjectScheduleStatus.completed
                    : s.canEditReview
                        ? ProjectScheduleStatus.inProgress
                        : ProjectScheduleStatus.published,
                sessionId: s.sessionId,
                groupId: s.groupId,
                submissionId: s.submissionId,
              ),
            )
            .toList(),
      );
    }).toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
  }

  ProjectReviewStatus _statusOf(ProjectScheduleStatus s) => switch (s) {
        ProjectScheduleStatus.completed => ProjectReviewStatus.completed,
        ProjectScheduleStatus.inProgress => ProjectReviewStatus.inProgress,
        _ => ProjectReviewStatus.notStarted,
      };

  String _reviewTypeLabel(String? type) => DisplayLabels.reviewType(type);

  void _openGroup(LecturerReviewGroup group) {
    final sessionId = group.sessionId;
    if (sessionId == null) return;
    Navigator.push<void>(
      context,
      AppAnimations.fadeSlideRoute(
        ReviewLiveSessionScreen(
          sessionId: sessionId,
          groupId: group.groupId,
          groupCode: group.groupCode,
          submissionId: group.submissionId,
          initialStatus: _statusOf(group.status),
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: ShimmerLoading(itemCount: 4, itemHeight: 100),
        ),
      );
    }

    if (_error != null) {
      final error = _error ?? 'Đã xảy ra lỗi';
      return SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          ),
        ),
      );
    }

    final slots = _slots ?? [];
    if (slots.isEmpty) {
      return const SafeArea(
        child: Center(
          child: Text(
            'Chưa có lịch review được công bố.',
            style: TextStyle(color: AppTheme.mediumGray),
          ),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: ListView.separated(
          padding: AppSpacing.pagePadding,
          itemCount: slots.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final slot = slots[index];
            return EduCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_note, color: AppTheme.primary, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${slot.dayLabel} • ${slot.slotLabel}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        slot.room,
                        style: const TextStyle(
                          color: AppTheme.mediumGray,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${slot.groups.length} nhóm',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...slot.groups.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Material(
                        color: AppTheme.statusPendingBg,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _openGroup(g),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        g.groupCode,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        g.topicName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.mediumGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                  status: _statusOf(g.status),
                                  compact: true,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.mediumGray,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
