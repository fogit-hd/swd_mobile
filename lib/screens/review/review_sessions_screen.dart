import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../data/mock_sample_data.dart';
import '../../models/project_review_status.dart';
import '../../models/review_session.dart';
import '../../models/review_submission_summary.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';
import '../../utils/review_schedule_filter.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/review_session_card.dart';
import 'review_live_session_screen.dart';
import 'review_results_screen.dart';
import 'review_submission_screen.dart';

class ReviewSessionsScreen extends StatefulWidget {
  const ReviewSessionsScreen({
    super.key,
    this.readOnly = false,
    this.showAttendance = false,
    this.title = 'Phiên review',
    this.subtitle = 'Chọn phiên để nhập nhận xét theo checklist',
    this.emptyMessage = 'Chưa có phiên review nào.',
    this.filter,
  });

  final bool readOnly;
  final bool showAttendance;
  final String title;
  final String subtitle;
  final String emptyMessage;
  final bool Function(ReviewSession session)? filter;

  @override
  State<ReviewSessionsScreen> createState() => _ReviewSessionsScreenState();
}

class _ReviewSessionsScreenState extends State<ReviewSessionsScreen> {
  List<ReviewSession>? _sessions;
  List<ReviewSubmissionSummary> _submissions = const [];
  bool _loading = true;
  String? _error;
  bool _loadStarted = false;
  ReviewScheduleScope _scope = ReviewScheduleScope.today;

  DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  int? _daysUntil(ReviewSession session) {
    final date = session.sessionDate;
    if (date == null) return null;
    return _dateOnly(date).difference(_dateOnly(DateTime.now())).inDays;
  }

  String _reminderLabel(ReviewSession session) {
    final days = _daysUntil(session) ?? 0;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Ngày mai';
    return 'Còn $days ngày';
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Chưa có ngày';
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _scopeTab({
    required ReviewScheduleScope scope,
    required String label,
    required IconData icon,
    required int count,
  }) {
    final selected = _scope == scope;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count phiên',
        child: InkWell(
          key: ValueKey('review-scope-${scope.name}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _scope = scope),
          child: AnimatedContainer(
            duration: AppAnimations.fast,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? AppTheme.primary : AppTheme.mediumGray,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppTheme.primary : AppTheme.mediumGray,
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primary : AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      if (auth.isDemoMode) {
        if (!mounted) return;
        setState(() {
          _sessions = MockSampleData.lecturerSessions;
          _submissions = const [];
          _loading = false;
        });
        return;
      }

      final service = ReviewService(ApiClient(auth));
      final sessions = await service.fetchMySessions();
      List<ReviewSubmissionSummary> submissions = const [];
      try {
        submissions = await service.fetchMySubmissions();
      } catch (_) {
        // sessions vẫn dùng được nếu submissions/my lỗi tạm thời
      }
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _submissions = submissions;
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

  ReviewSubmissionSummary? _summaryFor(ReviewSession session) {
    for (final s in _submissions) {
      if (s.id == session.submissionId || s.sessionId == session.sessionId) {
        return s;
      }
    }
    return null;
  }

  void _openSession(ReviewSession session) {
    if (widget.readOnly || session.canViewResults) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              ReviewResultsScreen(submissionId: session.submissionId),
        ),
      );
      return;
    }

    if (!session.canEditReview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phiên chưa công bố hoặc chưa sẵn sàng để review.'),
        ),
      );
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ReviewSubmissionScreen(
          submissionId: session.submissionId,
          sessionTitle: session.title,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && (_sessions == null || _sessions!.isEmpty)) {
      return const AppLoadingIndicator(message: 'Đang tải phiên review...');
    }

    if (_error != null && (_sessions == null || _sessions!.isEmpty)) {
      final error = _error ?? 'Đã xảy ra lỗi';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    var sessions = [...?_sessions];
    final filter = widget.filter;
    if (filter != null) {
      sessions = sessions.where(filter).toList();
    }
    sessions.sort((a, b) {
      final dateCompare = (a.sessionDate ?? DateTime(9999)).compareTo(
        b.sessionDate ?? DateTime(9999),
      );
      return dateCompare != 0
          ? dateCompare
          : (a.slot ?? 99).compareTo(b.slot ?? 99);
    });

    final allSessions = sessions;
    final todaySessions = filterReviewSessions(
      allSessions,
      ReviewScheduleScope.today,
    );
    final upcomingSessions = filterReviewSessions(
      allSessions,
      ReviewScheduleScope.upcoming,
    );
    final reminderSessions = allSessions.where((session) {
      final days = _daysUntil(session);
      return days != null && days >= 0 && days <= 3 && !session.isSubmitted;
    }).toList();
    if (widget.showAttendance) {
      sessions = filterReviewSessions(allSessions, _scope);
    }

    final submittedSummaries = _submissions
        .where((s) => s.isSubmitted)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 14),
          ),
          if (widget.showAttendance && reminderSessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFD97706),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nhắc lịch review sắp tới',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...reminderSessions.map(
                    (session) => Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFEF3C7),
                          child: Text(
                            '${session.slot ?? '—'}',
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          '${_reminderLabel(session)} · ${session.title}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${_dateLabel(session.sessionDate)} · ${session.timeLabel}'
                          '${session.room?.isNotEmpty == true ? ' · ${session.room}' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openSession(session),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (widget.showAttendance) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  _scopeTab(
                    scope: ReviewScheduleScope.today,
                    label: 'Hôm nay',
                    icon: Icons.today_outlined,
                    count: todaySessions.length,
                  ),
                  const SizedBox(width: 4),
                  _scopeTab(
                    scope: ReviewScheduleScope.upcoming,
                    label: 'Sắp tới',
                    icon: Icons.upcoming_outlined,
                    count: upcomingSessions.length,
                  ),
                  const SizedBox(width: 4),
                  _scopeTab(
                    scope: ReviewScheduleScope.all,
                    label: 'Tất cả',
                    icon: Icons.view_list_outlined,
                    count: allSessions.length,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  widget.showAttendance && _scope == ReviewScheduleScope.today
                      ? 'Hôm nay chưa có Slot review nào.'
                      : widget.showAttendance &&
                            _scope == ReviewScheduleScope.upcoming
                      ? 'Chưa có Slot review sắp tới.'
                      : widget.emptyMessage,
                  style: const TextStyle(color: AppTheme.mediumGray),
                ),
              ),
            )
          else
            ...sessions.map((session) {
              final summary = _summaryFor(session);
              return ReviewSessionCard(
                key: ValueKey('review-${session.sessionId}'),
                session: session,
                highlight: session.canEditReview,
                trailing: widget.readOnly
                    ? (session.canViewResults
                          ? const Icon(Icons.visibility_outlined)
                          : null)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.showAttendance)
                            IconButton(
                              icon: const Icon(Icons.how_to_reg_outlined),
                              tooltip: 'Điểm danh',
                              onPressed: () => Navigator.push<void>(
                                context,
                                AppAnimations.fadeSlideRoute(
                                  ReviewLiveSessionScreen(
                                    sessionId: session.sessionId,
                                    groupId: session.groupId,
                                    groupCode: session.title,
                                    submissionId: session.submissionId,
                                    initialStatus: session.isSubmitted
                                        ? ProjectReviewStatus.completed
                                        : session.canEditReview
                                        ? ProjectReviewStatus.inProgress
                                        : ProjectReviewStatus.notStarted,
                                  ),
                                ),
                              ),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                subtitleExtra: summary == null
                    ? null
                    : [
                        if (summary.reviewerName != null)
                          'Giảng viên: ${summary.reviewerName}',
                        if (summary.notes != null && summary.notes!.isNotEmpty)
                          summary.notes!,
                      ].join(' · '),
                onTap: () => _openSession(session),
              );
            }),
          if (submittedSummaries.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Nhận xét đã gửi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...submittedSummaries.map(
              (s) => Card(
                child: ListTile(
                  title: Text('${s.reviewTypeLabel} · Nhóm #${s.groupId}'),
                  subtitle: Text(
                    [
                      if (s.reviewerName != null)
                        'Giảng viên: ${s.reviewerName}',
                      if (s.notes != null && s.notes!.isNotEmpty) s.notes!,
                      'Trạng thái: ${s.statusLabel}',
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.visibility_outlined),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ReviewResultsScreen(submissionId: s.id),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
