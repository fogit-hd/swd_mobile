import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../utils/review_slot_schedule.dart';
import '../../utils/week_utils.dart';

/// Một ô trong ma trận 6 ngày × 5 slot.
/// - AnimatedContainer đổi màu mượt 200ms
/// - GestureDetector + scale 0.95 khi nhấn (phản hồi vật lý)
/// - Kích thước tối thiểu 44×44 (Apple HIG)
class SlotMatrixCell extends StatefulWidget {
  const SlotMatrixCell({
    super.key,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.occupiedCount,
    this.maxOccupancy = 3,
    this.showOccupancy = false,
  });

  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  /// Số nhóm đã đăng ký (chế độ sinh viên).
  final int? occupiedCount;
  final int maxOccupancy;
  final bool showOccupancy;

  @override
  State<SlotMatrixCell> createState() => _SlotMatrixCellState();
}

class _SlotMatrixCellState extends State<SlotMatrixCell> {
  bool _pressed = false;

  bool get _isFull {
    final count = widget.occupiedCount;
    return widget.showOccupancy &&
        count != null &&
        count >= widget.maxOccupancy;
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onTap != null && !_isFull;

    return GestureDetector(
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
      onTap: canTap ? widget.onTap : null,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
          _pressed ? 0.94 : 1.0,
          _pressed ? 0.94 : 1.0,
          1.0,
        ),
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: 56,
        ),
        decoration: BoxDecoration(
          color: widget.selected
              ? null
              : _isFull
              ? AppTheme.errorLight
              : null,
          gradient: widget.selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                )
              : _isFull
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                ),
          borderRadius: BorderRadius.circular(14),
          border: widget.selected
              ? null
              : Border.all(
                  color: _isFull
                      ? AppTheme.error.withValues(alpha: 0.4)
                      : const Color(0xFFDBEAFE),
                  width: 1.0,
                ),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.42),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                widget.selected
                    ? Icons.check_rounded
                    : (_isFull
                          ? Icons.lock_outline_rounded
                          : Icons.add_rounded),
                key: ValueKey(
                  widget.selected ? 'check' : (_isFull ? 'full' : 'add'),
                ),
                size: 20,
                color: widget.selected
                    ? AppTheme.white
                    : _isFull
                    ? AppTheme.error
                    : const Color(0xFF3B82F6),
              ),
            ),
            if (widget.showOccupancy && widget.occupiedCount != null) ...[
              const SizedBox(height: 3),
              Text(
                '${widget.occupiedCount}/${widget.maxOccupancy}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.selected
                      ? AppTheme.white.withValues(alpha: 0.95)
                      : _isFull
                      ? AppTheme.error
                      : const Color(0xFF1E40AF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ma trận cố định 6 ngày (T2–T7) × 5 slot review.
class SlotRegistrationMatrix extends StatelessWidget {
  const SlotRegistrationMatrix({
    super.key,
    required this.selectedKeys,
    required this.onToggle,
    this.enabled = true,
    this.occupancyMap,
    this.showOccupancy = false,
    this.dayCount = 6,
    this.slotCount = 5,
  });

  /// Key dạng "dayOfWeek-slot" ví dụ "1-3".
  final Set<String> selectedKeys;
  final void Function(int dayOfWeek, int slot) onToggle;
  final bool enabled;
  final Map<String, int>? occupancyMap;
  final bool showOccupancy;
  final int dayCount;
  final int slotCount;

  static String cellKey(int day, int slot) => '$day-$slot';

  static const _slotLabels = ['Slot 1', 'Slot 2', 'Slot 3', 'Slot 4', 'Slot 5'];

  @override
  Widget build(BuildContext context) {
    final days = List.generate(dayCount, (i) => i + 1);

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        // 1. Kill the Borders: border-0 floating card separated purely by ultra-soft elevated drop shadows
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: 6 cột ngày với badge hiện đại dark navy
          Row(
            children: [
              const SizedBox(width: 72),
              ...days.map(
                (d) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabel(d),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 2. Maximize Breathing Room: larger gaps between header and matrix rows
          const SizedBox(height: 18),
          // 5 hàng slot
          ...List.generate(slotCount, (slotIndex) {
            final slot = slotIndex + 1;
            final label = slotIndex < _slotLabels.length
                ? _slotLabels[slotIndex]
                : 'Slot $slot';
            final time = ReviewSlotSchedule.timeOf(slot);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...days.map((day) {
                    final key = cellKey(day, slot);
                    final occupied = occupancyMap?[key] ?? 0;
                    return Expanded(
                      child: Padding(
                        // Generous whitespace between columns
                        padding: const EdgeInsets.all(5),
                        child: SlotMatrixCell(
                          selected: selectedKeys.contains(key),
                          enabled: enabled,
                          showOccupancy: showOccupancy,
                          occupiedCount: showOccupancy ? occupied : null,
                          onTap: () => onToggle(day, slot),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
