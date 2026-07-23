import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../data/mock_sample_data.dart';
import '../models/review_round.dart';
import '../models/semester.dart';
import '../services/api_client.dart';
import '../services/review_service.dart';
import '../services/semester_service.dart';
import '../theme/app_theme.dart';

class ReviewContext {
  const ReviewContext({required this.semester, required this.round});

  final Semester semester;
  final ReviewRound round;

  int get roundId => round.id;
}

class ReviewContextBar extends StatefulWidget {
  const ReviewContextBar({super.key, required this.onChanged});

  final ValueChanged<ReviewContext> onChanged;

  @override
  State<ReviewContextBar> createState() => ReviewContextBarState();
}

class ReviewContextBarState extends State<ReviewContextBar> {
  List<Semester>? _semesters;
  Semester? _semester;
  List<ReviewRound>? _rounds;
  ReviewRound? _round;
  bool _loading = true;
  bool _loadingRounds = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSemesters();
    });
  }

  Future<void> _loadSemesters() async {
    try {
      final auth = AuthScope.of(context);
      if (auth.isDemoMode) {
        final semesters = MockSampleData.semesters;
        final rounds = MockSampleData.reviewRounds;
        final selectedSemester = semesters.isNotEmpty ? semesters.first : null;
        final selectedRound = rounds.isNotEmpty ? rounds.first : null;
        if (!mounted) return;
        setState(() {
          _semesters = semesters;
          _semester = selectedSemester;
          _rounds = rounds;
          _round = selectedRound;
          _loading = false;
        });
        if (selectedSemester != null && selectedRound != null) {
          widget.onChanged(
            ReviewContext(semester: selectedSemester, round: selectedRound),
          );
        }
        return;
      }

      final semesters = await SemesterService(ApiClient(auth)).fetchSemesters();
      if (!mounted) return;
      Semester? active;
      for (final s in semesters) {
        if (s.isActive) {
          active = s;
          break;
        }
      }
      active ??= semesters.isNotEmpty ? semesters.first : null;
      setState(() {
        _semesters = semesters;
        _semester = active;
        _loading = false;
      });
      if (active != null) {
        await _loadRounds(active.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRounds(int semesterId) async {
    setState(() {
      _loadingRounds = true;
      _rounds = null;
      _round = null;
    });

    try {
      final auth = AuthScope.of(context);
      final rounds = await ReviewService(
        ApiClient(auth),
      ).fetchRounds(semesterId: semesterId);
      if (!mounted) return;

      // Open trước, rồi các đợt còn lại (Closed/Draft không cho lưu slot).
      final ordered = [
        ...rounds.where((r) => r.isOpen),
        ...rounds.where((r) => !r.isOpen),
      ];
      final selected = ordered.isNotEmpty ? ordered.first : null;

      setState(() {
        _rounds = ordered;
        _round = selected;
        _loadingRounds = false;
      });
      if (selected != null) _notify();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rounds = const [];
        _round = null;
        _loadingRounds = false;
      });
    }
  }

  void _notify() {
    final semester = _semester;
    final round = _round;
    if (semester == null || round == null) return;
    widget.onChanged(ReviewContext(semester: semester, round: round));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    final semesters = _semesters;
    final semester = _semester;
    if (semester == null || semesters == null || semesters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Chưa có học kỳ. Phòng đào tạo cần tạo học kỳ trước.'),
      );
    }

    final rounds = _rounds ?? const <ReviewRound>[];

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFF2563EB).withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Semester>(
              key: ValueKey('semester-${semester.id}'),
              initialValue: semester,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Học kỳ',
                isDense: true,
              ),
              items: semesters
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _semester = value);
                _loadRounds(value.id);
              },
            ),
            const SizedBox(height: 12),
            if (_loadingRounds)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (rounds.isEmpty)
              const Text(
                'Chưa có đợt review. Phòng đào tạo cần mở đợt trước.',
                style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
              )
            else
              DropdownButtonFormField<ReviewRound>(
                key: ValueKey('round-${_round?.id ?? 0}'),
                initialValue: _round,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Đợt review',
                  isDense: true,
                ),
                items: rounds
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          '${r.displayName} · ${r.statusLabel}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _round = value);
                  _notify();
                },
              ),
          ],
        ),
      ),
    );
  }
}
