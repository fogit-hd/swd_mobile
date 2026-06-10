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
    return Material(
      elevation: 8,
      color: AppTheme.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
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
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: selected ? AppTheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.1 : 1,
                          duration: AppAnimations.fast,
                          curve: AppAnimations.curve,
                          child: AnimatedContainer(
                            duration: AppAnimations.fast,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              tab.icon,
                              size: 22,
                              color: selected
                                  ? AppTheme.primary
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
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? AppTheme.primary
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
    );
  }
}
