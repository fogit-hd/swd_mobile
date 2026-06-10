import 'package:flutter/material.dart';

import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import 'fade_slide_in.dart';

class PlaceholderSection {
  const PlaceholderSection({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    this.sections = const [],
  });

  final List<PlaceholderSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: sections.asMap().entries.map(
        (entry) => FadeSlideIn(
          delay: AppAnimations.stagger(entry.key),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SectionCard(section: entry.value),
          ),
        ),
      ).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final PlaceholderSection section;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primary.withValues(alpha: 0.08),
        highlightColor: AppTheme.accent.withValues(alpha: 0.06),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGray),
          ),
          child: Row(
            children: [
              Icon(section.icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
