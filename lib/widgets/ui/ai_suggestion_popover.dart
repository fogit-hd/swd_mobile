import 'package:flutter/material.dart';

import '../../models/project_suggestion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

/// Widget "AI Gợi ý" — popover hỗ trợ giảng viên (3 phần từ BE).
class AiSuggestionPopover extends StatefulWidget {
  const AiSuggestionPopover({
    super.key,
    required this.suggestion,
    this.initiallyExpanded = false,
  });

  final ProjectSuggestion suggestion;
  final bool initiallyExpanded;

  @override
  State<AiSuggestionPopover> createState() => _AiSuggestionPopoverState();
}

class _AiSuggestionPopoverState extends State<AiSuggestionPopover> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;
    if (suggestion.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppTheme.statusActiveBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: AppTheme.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI Gợi ý',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.xs),
                  if (suggestion.contentSummary.isNotEmpty)
                    _Section(
                      title: 'Tóm tắt',
                      body: suggestion.contentSummary,
                    ),
                  if (suggestion.strengthsSummary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Section(
                      title: 'Điểm mạnh',
                      body: suggestion.strengthsSummary,
                    ),
                  ],
                  if (suggestion.improvementSummary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _Section(
                      title: 'Cần cải thiện',
                      body: suggestion.improvementSummary,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppTheme.darkGray,
          ),
        ),
      ],
    );
  }
}
