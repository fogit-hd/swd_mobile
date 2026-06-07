import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../data/session_repository.dart';
import '../../models/evaluation_result.dart';
import '../../models/schedule_item.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/scale_tap.dart';

class PanelScoringDetailScreen extends StatefulWidget {
  const PanelScoringDetailScreen({super.key, required this.item});

  final ScheduleItem item;

  @override
  State<PanelScoringDetailScreen> createState() =>
      _PanelScoringDetailScreenState();
}

class _PanelScoringDetailScreenState extends State<PanelScoringDetailScreen> {
  EvaluationResult? _selected;
  bool _submitting = false;
  bool _initialized = false;
  late SessionRepository _repo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _repo = SessionRepository(AuthScope.of(context));
    _selected = _repo.savedEvaluation(widget.item.sessionId);
  }

  Future<void> _submit() async {
    if (_selected == null) return;

    setState(() => _submitting = true);

    try {
      await _repo.submitEvaluation(
        sessionId: widget.item.sessionId,
        groupId: widget.item.groupId,
        result: _selected!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu ${widget.item.groupName}: ${_selected!.label}',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chấm ${widget.item.groupName}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FadeSlideIn(
                  child: Text(
                    widget.item.projectTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: AppAnimations.stagger(1),
                  child: Text(
                    '${widget.item.timeSlot} • ${widget.item.room}',
                    style: const TextStyle(color: AppTheme.mediumGray, fontSize: 13),
                  ),
                ),
                const Divider(height: 32),
                FadeSlideIn(
                  delay: AppAnimations.stagger(2),
                  child: const Text(
                    'Kết quả chấm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: AppAnimations.stagger(3),
                  child: const Text(
                    'Chọn PASS hoặc FAIL cho nhóm này',
                    style: TextStyle(color: AppTheme.mediumGray, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: AppAnimations.stagger(4),
                  child: _ResultOption(
                    result: EvaluationResult.pass,
                    selected: _selected == EvaluationResult.pass,
                    onTap: () => setState(() => _selected = EvaluationResult.pass),
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: AppAnimations.stagger(5),
                  child: _ResultOption(
                    result: EvaluationResult.fail,
                    selected: _selected == EvaluationResult.fail,
                    onTap: () => setState(() => _selected = EvaluationResult.fail),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: const Border(top: BorderSide(color: AppTheme.lightGray)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ScaleTap(
                  onTap: _selected != null && !_submitting ? _submit : null,
                  child: AnimatedContainer(
                    duration: AppAnimations.normal,
                    curve: AppAnimations.curve,
                    child: ElevatedButton(
                      onPressed: _selected != null && !_submitting ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == EvaluationResult.fail
                            ? AppTheme.error
                            : AppTheme.accent,
                      ),
                      child: AnimatedSwitcher(
                        duration: AppAnimations.fast,
                        child: _submitting
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.white,
                                ),
                              )
                            : Text(
                                key: ValueKey(_selected?.label ?? 'none'),
                                _selected == null
                                    ? 'Chọn kết quả'
                                    : 'Lưu ${_selected!.label}',
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultOption extends StatefulWidget {
  const _ResultOption({
    required this.result,
    required this.selected,
    required this.onTap,
  });

  final EvaluationResult result;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ResultOption> createState() => _ResultOptionState();
}

class _ResultOptionState extends State<_ResultOption> {
  bool _pressed = false;

  bool get _isPass => widget.result == EvaluationResult.pass;

  Color get _activeColor => _isPass ? AppTheme.success : AppTheme.error;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.selected
        ? _activeColor
        : (_pressed ? AppTheme.primary : AppTheme.lightGray);

    return AnimatedScale(
      scale: widget.selected ? 1.02 : 1,
      duration: AppAnimations.normal,
      curve: AppAnimations.curve,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.curve,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: widget.selected || _pressed ? 2 : 1,
          ),
          color: widget.selected
              ? _activeColor.withValues(alpha: 0.08)
              : AppTheme.white,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            splashColor: _activeColor.withValues(alpha: 0.2),
            highlightColor: _activeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Icon(
                    _isPass ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: widget.selected ? _activeColor : AppTheme.mediumGray,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.label,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                widget.selected ? _activeColor : AppTheme.black,
                          ),
                        ),
                        Text(
                          _isPass ? 'Đạt yêu cầu bảo vệ' : 'Không đạt yêu cầu',
                          style: const TextStyle(
                            color: AppTheme.mediumGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppAnimations.fast,
                    child: widget.selected
                        ? Icon(
                            key: const ValueKey('on'),
                            Icons.radio_button_checked,
                            color: _activeColor,
                          )
                        : const Icon(
                            key: ValueKey('off'),
                            Icons.radio_button_off,
                            color: AppTheme.lightGray,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
