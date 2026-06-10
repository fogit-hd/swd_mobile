import 'package:flutter/material.dart';

import '../app/auth_scope.dart';
import '../models/review_enums.dart';
import '../models/semester.dart';
import '../services/api_client.dart';
import '../services/semester_service.dart';
import '../theme/app_theme.dart';
import '../utils/week_utils.dart';

class ReviewContext {
  const ReviewContext({
    required this.semester,
    required this.reviewType,
    required this.weekStart,
  });

  final Semester semester;
  final ReviewType reviewType;
  final String weekStart;
}

class ReviewContextBar extends StatefulWidget {
  const ReviewContextBar({
    super.key,
    required this.onChanged,
    this.allowWeekShift = true,
  });

  final ValueChanged<ReviewContext> onChanged;
  final bool allowWeekShift;

  @override
  State<ReviewContextBar> createState() => ReviewContextBarState();
}

class ReviewContextBarState extends State<ReviewContextBar> {
  List<Semester>? _semesters;
  Semester? _semester;
  ReviewType _reviewType = ReviewType.defaultType;
  String _weekStart = weekStartOf(DateTime.now());
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_semesters == null) _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    try {
      final auth = AuthScope.of(context);
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
      if (active != null) _notify();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _notify() {
    final semester = _semester;
    if (semester == null) return;
    widget.onChanged(
      ReviewContext(
        semester: semester,
        reviewType: _reviewType,
        weekStart: _weekStart,
      ),
    );
  }

  void _shiftWeek(int delta) {
    final monday = mondayOfWeek(DateTime.parse(_weekStart));
    setState(() {
      _weekStart = weekStartOf(monday.add(Duration(days: 7 * delta)));
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_semester == null || _semesters == null || _semesters!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('Chưa có học kỳ. Admin cần tạo học kỳ trước.'),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Semester>(
              value: _semester,
              decoration: const InputDecoration(
                labelText: 'Học kỳ',
                isDense: true,
              ),
              items: _semesters!
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _semester = value);
                _notify();
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReviewType>(
              value: _reviewType,
              decoration: const InputDecoration(
                labelText: 'Loại review',
                isDense: true,
              ),
              items: ReviewType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _reviewType = value);
                _notify();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.allowWeekShift)
                  IconButton(
                    onPressed: () => _shiftWeek(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                Expanded(
                  child: Text(
                    'Tuần $_weekStart',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
                if (widget.allowWeekShift)
                  IconButton(
                    onPressed: () => _shiftWeek(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
