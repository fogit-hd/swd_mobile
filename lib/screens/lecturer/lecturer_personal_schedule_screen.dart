import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_session.dart';
import '../../models/schedule_event.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../widgets/weekly_vertical_schedule.dart';

class LecturerPersonalScheduleScreen extends StatefulWidget {
  const LecturerPersonalScheduleScreen({super.key});

  @override
  State<LecturerPersonalScheduleScreen> createState() =>
      _LecturerPersonalScheduleScreenState();
}

class _LecturerPersonalScheduleScreenState
    extends State<LecturerPersonalScheduleScreen> {
  List<ScheduleEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _events.isEmpty && _error == null) {
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
      final client = ApiClient(auth);
      final reviewSessions = await ReviewService(client).fetchMySessions();

      final events = <ScheduleEvent>[
        ...reviewSessions.where((s) => s.sessionDate != null).map(_fromReview),
      ];

      if (!mounted) return;
      setState(() {
        _events = events;
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

  ScheduleEvent _fromReview(ReviewSession s) {
    final date = s.sessionDate;
    return ScheduleEvent(
      date: date ?? DateTime.now(),
      slot: s.slot,
      title: s.title,
      subtitle: s.typeLabel,
      room: s.room,
      type: 'Buổi review',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
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

    return WeeklyVerticalSchedule(
      events: _events,
      loading: _loading,
      emptyMessage: 'Không có lịch review trong tuần này.',
      onRefresh: _load,
    );
  }
}
