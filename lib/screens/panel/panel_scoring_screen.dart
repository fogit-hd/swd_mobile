import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../config/api_config.dart';
import '../../data/mock_session_store.dart';
import '../../data/session_repository.dart';
import '../../models/schedule_item.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/mock_schedule_builder.dart';
import '../../widgets/schedule_card.dart';
import 'panel_scoring_detail_screen.dart';

class PanelScoringScreen extends StatefulWidget {
  const PanelScoringScreen({super.key});

  @override
  State<PanelScoringScreen> createState() => _PanelScoringScreenState();
}

class _PanelScoringScreenState extends State<PanelScoringScreen> {
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
    final scorable =
        items.where((i) => i.status != SessionStatus.waiting).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FadeSlideIn(
          child: const Text(
            'Chấm điểm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        FadeSlideIn(
          delay: AppAnimations.stagger(1),
          child: const Text(
            'Chọn nhóm để nhập điểm',
            style: TextStyle(color: AppTheme.mediumGray, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        if (scorable.isEmpty)
          FadeSlideIn(
            delay: AppAnimations.stagger(2),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Chưa có nhóm nào sẵn sàng chấm.\nVui lòng chờ điều phối viên bắt đầu phiên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mediumGray),
                ),
              ),
            ),
          )
        else
          ...scorable.map(
            (item) => ScheduleCard(
              key: ValueKey('score-${item.sessionId}'),
              item: item,
              highlight: item.status == SessionStatus.inProgress,
              evaluationResult:
                  MockSessionStore.instance.evaluationFor(item.sessionId),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.mediumGray,
              ),
              onTap: () {
                Navigator.push<void>(
                  context,
                  AppAnimations.fadeSlideRoute(
                    PanelScoringDetailScreen(item: item),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ApiConfig.useMockData) {
      return MockScheduleBuilder(builder: (_, items) => _buildList(items));
    }

    if (_loading && (_items == null || _items!.isEmpty)) {
      return const AppLoadingIndicator(message: 'Đang tải danh sách...');
    }

    return _buildList(_items ?? []);
  }
}
