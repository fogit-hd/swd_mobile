import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../config/api_config.dart';
import '../../data/session_repository.dart';
import '../../models/schedule_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/mock_schedule_builder.dart';
import '../../widgets/scale_tap.dart';
import '../../widgets/schedule_card.dart';

class ModeratorSessionScreen extends StatefulWidget {
  const ModeratorSessionScreen({super.key});

  @override
  State<ModeratorSessionScreen> createState() => _ModeratorSessionScreenState();
}

class _ModeratorSessionScreenState extends State<ModeratorSessionScreen> {
  bool _actionLoading = false;
  late SessionRepository _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = SessionRepository(AuthScope.of(context));
  }

  ScheduleItem? _currentItem(List<ScheduleItem> items) {
    for (final item in items) {
      if (item.status == SessionStatus.inProgress) return item;
    }
    return null;
  }

  ScheduleItem? _nextWaiting(List<ScheduleItem> items) {
    for (final item in items) {
      if (item.status == SessionStatus.waiting) return item;
    }
    return null;
  }

  Future<void> _startSession(ScheduleItem next) async {
    setState(() => _actionLoading = true);
    try {
      await _repo.startSession(next.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bắt đầu phiên chấm điểm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _endCurrentSession(ScheduleItem current) async {
    setState(() => _actionLoading = true);
    try {
      await _repo.closeSession(current.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kết thúc phiên chấm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Widget _buildContent(List<ScheduleItem> items) {
    final current = _currentItem(items);
    final next = _nextWaiting(items);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Điều phối hội đồng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bắt đầu hoặc kết thúc phiên chấm điểm',
          style: TextStyle(color: AppTheme.mediumGray, fontSize: 14),
        ),
        if (ApiConfig.useMockData) ...[
          const SizedBox(height: 8),
          const Text(
            'Thay đổi ở đây cập nhật ngay sang Hội đồng chấm',
            style: TextStyle(color: AppTheme.accent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        _SessionControlSection(
          key: ValueKey(
            'ctrl-${current?.sessionId ?? 0}-${next?.sessionId ?? 0}-$_actionLoading',
          ),
          current: current,
          next: next,
          actionLoading: _actionLoading,
          onStart: _startSession,
          onEnd: _endCurrentSession,
        ),
        const Divider(height: 32),
        const Text(
          'Toàn bộ lịch',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => ScheduleCard(
            key: ValueKey('schedule-${item.sessionId}'),
            item: item,
            highlight: item.status == SessionStatus.inProgress,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ApiConfig.useMockData) {
      return MockScheduleBuilder(builder: (_, items) => _buildContent(items));
    }

    return FutureBuilder<List<ScheduleItem>>(
      future: _repo.fetchSchedule(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingIndicator(message: 'Đang tải phiên...');
        }
        return _buildContent(snapshot.data!);
      },
    );
  }
}

class _SessionControlSection extends StatelessWidget {
  const _SessionControlSection({
    super.key,
    required this.current,
    required this.next,
    required this.actionLoading,
    required this.onStart,
    required this.onEnd,
  });

  final ScheduleItem? current;
  final ScheduleItem? next;
  final bool actionLoading;
  final Future<void> Function(ScheduleItem) onStart;
  final Future<void> Function(ScheduleItem) onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (current != null) ...[
          const Text(
            'Đang chấm',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ScheduleCard(
            key: ValueKey('current-${current!.sessionId}'),
            item: current!,
            highlight: true,
          ),
          const SizedBox(height: 12),
          ScaleTap(
            onTap: actionLoading ? null : () => onEnd(current!),
            child: OutlinedButton.icon(
              onPressed: actionLoading ? null : () => onEnd(current!),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Kết thúc phiên hiện tại'),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (next != null) ...[
          const Text(
            'Nhóm tiếp theo',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ScheduleCard(
            key: ValueKey('next-${next!.sessionId}'),
            item: next!,
          ),
          const SizedBox(height: 24),
          _StartButton(
            key: ValueKey('start-${next!.sessionId}'),
            enabled: current == null && !actionLoading,
            loading: actionLoading,
            onPressed: () => onStart(next!),
          ),
        ] else if (current == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Tất cả nhóm đã hoàn thành chấm điểm.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mediumGray),
              ),
            ),
          ),
      ],
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulse;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_StartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.loading != widget.loading) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.enabled && !widget.loading) {
      _pulseController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulse ??= Tween<double>(begin: 1, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    } else {
      _pulseController?.dispose();
      _pulseController = null;
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: ScaleTap(
        onTap: widget.enabled && !widget.loading ? widget.onPressed : null,
        child: ElevatedButton.icon(
          onPressed: widget.enabled && !widget.loading ? widget.onPressed : null,
          icon: widget.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.white,
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: Text(widget.enabled ? 'Start' : 'Đang có phiên'),
        ),
      ),
    );

    if (_pulse == null) return button;

    return AnimatedBuilder(
      animation: _pulse!,
      builder: (_, child) => Transform.scale(
        scale: _pulse!.value,
        child: child,
      ),
      child: button,
    );
  }
}
