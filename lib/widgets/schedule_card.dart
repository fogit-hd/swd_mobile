import 'package:flutter/material.dart';



import '../models/evaluation_result.dart';

import '../models/schedule_item.dart';

import '../theme/app_animations.dart';

import '../theme/app_theme.dart';



class ScheduleCard extends StatefulWidget {

  const ScheduleCard({

    super.key,

    required this.item,

    this.trailing,

    this.onTap,

    this.highlight = false,

    this.evaluationResult,

    this.animationIndex = 0,

  });



  final ScheduleItem item;

  final Widget? trailing;

  final VoidCallback? onTap;

  final bool highlight;

  final EvaluationResult? evaluationResult;

  final int animationIndex;



  @override

  State<ScheduleCard> createState() => _ScheduleCardState();

}



class _ScheduleCardState extends State<ScheduleCard>

    with SingleTickerProviderStateMixin {

  bool _pressed = false;

  AnimationController? _pulseController;

  Animation<double>? _pulse;



  bool get _interactive => widget.onTap != null;



  @override

  void initState() {

    super.initState();

    _setupPulse();

  }



  @override

  void didUpdateWidget(ScheduleCard oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (oldWidget.highlight != widget.highlight) {

      _setupPulse();

    }

  }



  void _setupPulse() {

    if (widget.highlight) {

      _pulseController ??= AnimationController(

        vsync: this,

        duration: const Duration(milliseconds: 1400),

      )..repeat(reverse: true);

      _pulse = Tween<double>(begin: 0.06, end: 0.16).animate(

        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),

      );

    } else {

      _pulseController?.dispose();

      _pulseController = null;

      _pulse = null;

    }

  }



  @override

  void dispose() {

    _pulseController?.dispose();

    super.dispose();

  }



  Color get _borderColor {

    if (_pressed && _interactive) return AppTheme.primary;

    if (widget.highlight) return AppTheme.accent;

    return AppTheme.lightGray;

  }



  double get _borderWidth {

    if (_pressed && _interactive) return 2;

    if (widget.highlight) return 2;

    return 1;

  }



  Widget _buildCard(double pulseAlpha) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: AnimatedContainer(

        duration: AppAnimations.fast,

        curve: AppAnimations.curve,

        decoration: BoxDecoration(

          color: AppTheme.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: _borderColor, width: _borderWidth),

          boxShadow: [

            BoxShadow(

              color: widget.highlight

                  ? AppTheme.accent.withValues(alpha: pulseAlpha)

                  : AppTheme.primary.withValues(alpha: _pressed ? 0.14 : 0.06),

              blurRadius: widget.highlight ? 12 : (_pressed ? 8 : 4),

              offset: Offset(0, widget.highlight ? 4 : (_pressed ? 3 : 2)),

            ),

          ],

        ),

        child: Material(

          color: Colors.transparent,

          borderRadius: BorderRadius.circular(11),

          clipBehavior: Clip.antiAlias,

          child: InkWell(

            onTap: widget.onTap,

            onHighlightChanged: _interactive

                ? (pressed) => setState(() => _pressed = pressed)

                : null,

            splashColor: AppTheme.primary.withValues(alpha: 0.14),

            highlightColor: AppTheme.accent.withValues(alpha: 0.1),

            borderRadius: BorderRadius.circular(11),

            child: Padding(

              padding: const EdgeInsets.all(16),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(

                          children: [

                            Text(

                              widget.item.groupName,

                              style: const TextStyle(

                                fontWeight: FontWeight.w700,

                                fontSize: 16,

                              ),

                            ),

                            const SizedBox(width: 8),

                            _StatusBadge(status: widget.item.status),

                            if (widget.evaluationResult != null) ...[

                              const SizedBox(width: 8),

                              _EvaluationBadge(result: widget.evaluationResult!),

                            ],

                          ],

                        ),

                        const SizedBox(height: 6),

                        Text(

                          widget.item.projectTitle,

                          style: const TextStyle(

                            color: AppTheme.darkGray,

                            fontSize: 14,

                          ),

                        ),

                        const SizedBox(height: 10),

                        Row(

                          children: [

                            const Icon(Icons.schedule,

                                size: 16, color: AppTheme.mediumGray),

                            const SizedBox(width: 4),

                            Text(

                              widget.item.timeSlot,

                              style: const TextStyle(

                                color: AppTheme.mediumGray,

                                fontSize: 13,

                              ),

                            ),

                            const SizedBox(width: 16),

                            const Icon(Icons.meeting_room_outlined,

                                size: 16, color: AppTheme.mediumGray),

                            const SizedBox(width: 4),

                            Text(

                              widget.item.room,

                              style: const TextStyle(

                                color: AppTheme.mediumGray,

                                fontSize: 13,

                              ),

                            ),

                          ],

                        ),

                      ],

                    ),

                  ),

                  if (widget.trailing != null) ...[

                    const SizedBox(width: 8),

                    AnimatedSlide(

                      offset: _pressed ? const Offset(0.15, 0) : Offset.zero,

                      duration: AppAnimations.fast,

                      curve: AppAnimations.curve,

                      child: widget.trailing!,

                    ),

                  ],

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final card = _pulse != null

        ? AnimatedBuilder(

            animation: _pulse!,

            builder: (_, _) => _buildCard(_pulse!.value),

          )

        : _buildCard(0.06);



    return card;

  }

}



class _StatusBadge extends StatelessWidget {

  const _StatusBadge({required this.status});



  final SessionStatus status;



  @override

  Widget build(BuildContext context) {

    final (label, bg, fg) = switch (status) {

      SessionStatus.waiting => ('Chờ', AppTheme.lightGray, AppTheme.darkGray),

      SessionStatus.inProgress => ('Đang chấm', AppTheme.accent, AppTheme.white),

      SessionStatus.completed => ('Xong', AppTheme.primary, AppTheme.white),

    };



    return AnimatedContainer(

      duration: AppAnimations.fast,

      curve: AppAnimations.curve,

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

      decoration: BoxDecoration(

        color: bg,

        borderRadius: BorderRadius.circular(4),

      ),

      child: Text(

        label,

        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),

      ),

    );

  }

}



class _EvaluationBadge extends StatelessWidget {

  const _EvaluationBadge({required this.result});



  final EvaluationResult result;



  @override

  Widget build(BuildContext context) {

    final (bg, fg) = result == EvaluationResult.pass

        ? (AppTheme.success, AppTheme.white)

        : (AppTheme.error, AppTheme.white);



    return AnimatedContainer(

      duration: AppAnimations.normal,

      curve: AppAnimations.curve,

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

      decoration: BoxDecoration(

        color: bg,

        borderRadius: BorderRadius.circular(4),

      ),

      child: Text(

        result.label,

        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),

      ),

    );

  }

}

