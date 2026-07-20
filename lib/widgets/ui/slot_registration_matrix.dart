import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
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
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1.0),
        constraints: const BoxConstraints(
          minWidth: AppSpacing.minTouchTarget,
          minHeight: AppSpacing.minTouchTarget,
        ),
        decoration: BoxDecoration(
          color: widget.selected
              ? AppTheme.primary
              : _isFull
                  ? AppTheme.errorLight
                  : AppTheme.statusPendingBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.selected
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
            Icon(
              widget.selected ? Icons.check_rounded : Icons.add_rounded,
              size: 18,
              color: widget.selected
                  ? AppTheme.white
                  : _isFull
                      ? AppTheme.error
                      : AppTheme.mediumGray,
            ),
            if (widget.showOccupancy && widget.occupiedCount != null) ...[
              const SizedBox(height: 2),
              Text(
                '${widget.occupiedCount}/${widget.maxOccupancy}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: widget.selected
                      ? AppTheme.white.withValues(alpha: 0.9)
                      : AppTheme.mediumGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ma trận cố định 6 ngày (T2–T7) × 5 slot (Ca 1–4 + Ca Tối).
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

  static const _slotLabels = ['Ca 1', 'Ca 2', 'Ca 3', 'Ca 4', 'Ca Tối'];

  @override
  Widget build(BuildContext context) {
    final days = List.generate(dayCount, (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: 6 cột ngày
        Row(
          children: [
            const SizedBox(width: 52),
            ...days.map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    dayLabel(d),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // 5 hàng slot
        ...List.generate(slotCount, (slotIndex) {
          final slot = slotIndex + 1;
          final label = slotIndex < _slotLabels.length
              ? _slotLabels[slotIndex]
              : 'Ca $slot';

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
                ...days.map((day) {
                  final key = cellKey(day, slot);
                  final occupied = occupancyMap?[key] ?? 0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
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
    );
  }
}
