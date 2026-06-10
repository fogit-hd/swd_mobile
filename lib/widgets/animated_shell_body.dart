import 'package:flutter/material.dart';

import '../theme/app_animations.dart';

/// Giữ state tất cả tab, fade + slide theo hướng đổi tab.
class AnimatedShellBody extends StatefulWidget {
  const AnimatedShellBody({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<AnimatedShellBody> createState() => _AnimatedShellBodyState();
}

class _AnimatedShellBodyState extends State<AnimatedShellBody> {
  int _previousIndex = 0;

  @override
  void didUpdateWidget(AnimatedShellBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slideFromRight = widget.index >= _previousIndex;

    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final visible = i == widget.index;
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: AppAnimations.normal,
            curve: AppAnimations.curve,
            child: AnimatedSlide(
              offset: visible
                  ? Offset.zero
                  : Offset(slideFromRight ? -0.04 : 0.04, 0),
              duration: AppAnimations.normal,
              curve: AppAnimations.curve,
              child: TickerMode(
                enabled: visible,
                child: widget.children[i],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class AnimatedNavIcon extends StatelessWidget {
  const AnimatedNavIcon({
    super.key,
    required this.icon,
    required this.selected,
  });

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.12 : 1,
      duration: AppAnimations.fast,
      curve: AppAnimations.curve,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.curve,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
    );
  }
}
