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
          builder: (_) => ReviewResultsScreen(submissionId: session.submissionId),
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

    var sessions = _sessions ?? [];
    final filter = widget.filter;
    if (filter != null) {
      sessions = sessions.where(filter).toList();
    }

    final submittedSummaries =
        _submissions.where((s) => s.isSubmitted).toList();

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
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  widget.emptyMessage,
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
                        if (summary.result != null) 'KQ: ${summary.result}',
                        if (summary.score != null) 'Điểm: ${summary.score}',
                      ].join(' · '),
                onTap: () => _openSession(session),
              );
            }),
          if (submittedSummaries.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Kết quả đã gửi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...submittedSummaries.map(
              (s) => Card(
                child: ListTile(
                  title: Text(
                    '${s.reviewTypeLabel} · Nhóm #${s.groupId}',
                  ),
                  subtitle: Text(
                    [
                      if (s.result != null) 'Kết quả: ${s.result}',
                      if (s.score != null) 'Điểm: ${s.score}',
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
