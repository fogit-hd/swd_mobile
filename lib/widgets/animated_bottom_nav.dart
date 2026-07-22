import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../theme/app_animations.dart';
import '../theme/app_theme.dart';
import 'scale_tap.dart';

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({IconData icon, String label})> tabs;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.white.withValues(alpha: 0.90),
            border: Border(
              top: BorderSide(
                color: AppTheme.accent.withValues(alpha: 0.18),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final selected = i == currentIndex;
                  final tab = tabs[i];
                  return Expanded(
                    child: ScaleTap(
                      scale: 0.92,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: AppAnimations.fast,
                        curve: AppAnimations.curve,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.12 : 1,
                              duration: AppAnimations.fast,
                              curve: AppAnimations.curve,
                              child: AnimatedContainer(
                                duration: AppAnimations.fast,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: selected
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF2563EB),
                                            Color(0xFF4F46E5),
                                          ],
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF2563EB)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  tab.icon,
                                  size: 22,
                                  color: selected
                                      ? AppTheme.white
                                      : AppTheme.mediumGray,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: AppAnimations.fast,
                              curve: AppAnimations.curve,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? AppTheme.accent
                                    : AppTheme.mediumGray,
                              ),
                              child: Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

