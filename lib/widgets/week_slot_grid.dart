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
            const SizedBox(width: 60),
            ...List.generate(
              maxSlot,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Ca ${i + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayLabel(day),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.white,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                ...List.generate(maxSlot, (index) {
                  final slot = index + 1;
                  final entry = AvailabilitySlot(dayOfWeek: day, slot: slot);
                  final selected = selectedSlots.contains(entry);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: InkWell(
                        onTap: enabled ? () => onToggle(day, slot) : null,
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 48,
                          decoration: BoxDecoration(
                            color: selected ? null : const Color(0xFFF8FAFC),
                            gradient: selected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                                  ),
                            borderRadius: BorderRadius.circular(10),
                            border: selected
                                ? null
                                : Border.all(
                                    color: const Color(0xFFDBEAFE),
                                    width: 1,
                                  ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.38),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            selected ? Icons.check_rounded : Icons.add_rounded,
                            size: 20,
                            color: selected
                                ? AppTheme.white
                                : const Color(0xFF3B82F6),
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
