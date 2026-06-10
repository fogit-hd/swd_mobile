import 'package:flutter/material.dart';

import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import '../utils/week_utils.dart';
import 'scale_tap.dart';

/// Lịch tuần dọc: dãy chọn ngày phía trên + bảng 2 cột (ngày | slot).
/// Chưa gắn API — slot để trống.
class WeeklyVerticalSchedule extends StatefulWidget {
  const WeeklyVerticalSchedule({super.key});

  @override
  State<WeeklyVerticalSchedule> createState() => _WeeklyVerticalScheduleState();
}

class _WeeklyVerticalScheduleState extends State<WeeklyVerticalSchedule> {
  late DateTime _weekMonday;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _weekMonday = mondayOfWeek(DateTime.now());
    final today = DateTime.now();
    if (!today.isBefore(_weekMonday) &&
        !today.isAfter(_weekMonday.add(const Duration(days: 6)))) {
      _selectedDayIndex = today.weekday - 1;
    }
  }

  void _shiftWeek(int delta) {
    setState(() {
      _weekMonday = _weekMonday.add(Duration(days: 7 * delta));
      _selectedDayIndex = 0;
    });
  }

  List<DateTime> get _weekDays => List.generate(
        7,
        (i) => _weekMonday.add(Duration(days: i)),
      );

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekMonday.add(const Duration(days: 6));
    final monthLabel =
        '${_weekMonday.month}/${_weekMonday.year}';

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _WeekNavigator(
            monthLabel: monthLabel,
            rangeLabel:
                '${_weekMonday.day}/${_weekMonday.month} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}',
            onPrev: () => _shiftWeek(-1),
            onNext: () => _shiftWeek(1),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = _weekDays[index];
              final selected = index == _selectedDayIndex;
              return ScaleTap(
                scale: 0.94,
                onTap: () => setState(() => _selectedDayIndex = index),
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.curve,
                  width: 52,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary : AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.lightGray,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayLabel(day.weekday),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppTheme.white : AppTheme.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppTheme.white : AppTheme.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Column(
              children: List.generate(7, (index) {
                final day = _weekDays[index];
                final highlighted = index == _selectedDayIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScheduleRow(
                    day: day,
                    highlighted: highlighted,
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.monthLabel,
    required this.rangeLabel,
    required this.onPrev,
    required this.onNext,
  });

  final String monthLabel;
  final String rangeLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ScaleTap(
              onTap: onPrev,
              child: const Icon(Icons.chevron_left, color: AppTheme.primary),
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            ScaleTap(
              onTap: onNext,
              child: const Icon(Icons.chevron_right, color: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tuần: $rangeLabel',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mediumGray, fontSize: 12),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.day,
    required this.highlighted,
  });

  final DateTime day;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.curve,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppTheme.primary : AppTheme.lightGray,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppTheme.primary.withValues(alpha: 0.06)
                    : AppTheme.background,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(11),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel(day.weekday),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: highlighted ? AppTheme.primary : AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}/${day.month}',
                    style: const TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 3,
              color: highlighted ? AppTheme.primary : AppTheme.lightGray,
            ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerLeft,
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
