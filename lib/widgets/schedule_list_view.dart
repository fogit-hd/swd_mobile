import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../config/api_config.dart';
import '../data/mock_session_store.dart';
import '../data/session_repository.dart';
import '../models/schedule_item.dart';
import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/mock_schedule_builder.dart';
import '../widgets/schedule_card.dart';

class ScheduleListView extends StatefulWidget {
  const ScheduleListView({super.key, this.highlightInProgress = true});

  final bool highlightInProgress;

  @override
  State<ScheduleListView> createState() => _ScheduleListViewState();
}

class _ScheduleListViewState extends State<ScheduleListView> {
  List<ScheduleItem>? _items;
  bool _loading = true;
  late SessionRepository _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = SessionRepository(AuthScope.of(context));
    if (!ApiConfig.useMockData && _items == null) {
      _loadApi();
    }
  }

  Future<void> _loadApi() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.fetchSchedule();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _buildList(List<ScheduleItem> items) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        FadeSlideIn(
          child: const Text(
            'Lịch hội đồng hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        FadeSlideIn(
          delay: AppAnimations.stagger(1),
          child: Text(
            items.isEmpty
                ? 'Chưa có phiên nào'
                : '${items.first.councilCode ?? 'Hội đồng'} • ${items.length} nhóm',
            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 14),
          ),
        ),
        if (ApiConfig.useMockData) ...[
          const SizedBox(height: 8),
          FadeSlideIn(
            delay: AppAnimations.stagger(2),
            child: const Text(
              'Dữ liệu đồng bộ giữa Hội đồng chấm ↔ Điều phối',
              style: TextStyle(color: AppTheme.accent, fontSize: 12),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (items.isEmpty)
          FadeSlideIn(
            delay: AppAnimations.stagger(3),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Không có lịch hội đồng.',
                  style: TextStyle(color: AppTheme.mediumGray),
                ),
              ),
            ),
          )
        else
          ...items.map(
            (item) => ScheduleCard(
              key: ValueKey('schedule-${item.sessionId}'),
              item: item,
              highlight: widget.highlightInProgress &&
                  item.status == SessionStatus.inProgress,
              evaluationResult:
                  MockSessionStore.instance.evaluationFor(item.sessionId),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ApiConfig.useMockData) {
      return MockScheduleBuilder(
        builder: (context, items) => RefreshIndicator(
          onRefresh: () async {},
          color: AppTheme.primary,
          child: _buildList(items),
        ),
      );
    }

    if (_loading && (_items == null || _items!.isEmpty)) {
      return const AppLoadingIndicator(message: 'Đang tải lịch...');
    }

    return RefreshIndicator(
      onRefresh: _loadApi,
      color: AppTheme.primary,
      child: _buildList(_items ?? []),
    );
  }
}
