import 'package:flutter/material.dart';

import '../models/review_availability.dart';
import '../theme/app_theme.dart';
import '../utils/week_utils.dart';

class WeekSlotGrid extends StatelessWidget {
  const WeekSlotGrid({
    super.key,
    required this.selectedSlots,
    required this.onToggle,
    this.maxSlot = 4,
    this.enabled = true,
  });

  final Set<AvailabilitySlot> selectedSlots;
  final void Function(int dayOfWeek, int slot) onToggle;
  final int maxSlot;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const days = [1, 2, 3, 4, 5];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 48),
            ...List.generate(
              maxSlot,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    'Ca ${i + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    dayLabel(day),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                ...List.generate(maxSlot, (index) {
                  final slot = index + 1;
                  final entry = AvailabilitySlot(dayOfWeek: day, slot: slot);
                  final selected = selectedSlots.contains(entry);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: enabled ? () => onToggle(day, slot) : null,
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.accent.withValues(alpha: 0.15)
                                : AppTheme.lightGray.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.accent
                                  : AppTheme.lightGray,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            selected ? Icons.check : Icons.add,
                            size: 18,
                            color: selected
                                ? AppTheme.accent
                                : AppTheme.mediumGray,
                          ),
                        ),
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
