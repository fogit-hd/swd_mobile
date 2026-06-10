import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_session.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/review_session_card.dart';
import 'review_results_screen.dart';
import 'review_submission_screen.dart';

class ReviewSessionsScreen extends StatefulWidget {
  const ReviewSessionsScreen({
    super.key,
    this.readOnly = false,
    this.title = 'Phiên review',
    this.subtitle = 'Chọn phiên để nhập nhận xét theo checklist',
    this.emptyMessage = 'Chưa có phiên review nào.',
    this.filter,
  });

  final bool readOnly;
  final String title;
  final String subtitle;
  final String emptyMessage;
  final bool Function(ReviewSession session)? filter;

  @override
  State<ReviewSessionsScreen> createState() => _ReviewSessionsScreenState();
}

class _ReviewSessionsScreenState extends State<ReviewSessionsScreen> {
  List<ReviewSession>? _sessions;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessions == null && _error == null) {
      _load();
    }
  }

  Future<void> _load() async {
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
        _sessions = sessions;
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    var sessions = _sessions ?? [];
    if (widget.filter != null) {
      sessions = sessions.where(widget.filter!).toList();
    }

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
            ...sessions.map(
              (session) => ReviewSessionCard(
                key: ValueKey('review-${session.sessionId}'),
                session: session,
                highlight: session.canEditReview,
                trailing: widget.readOnly
                    ? (session.canViewResults
                        ? const Icon(Icons.visibility_outlined)
                        : null)
                    : const Icon(Icons.chevron_right),
                onTap: () => _openSession(session),
              ),
            ),
        ],
      ),
    );
  }
}
