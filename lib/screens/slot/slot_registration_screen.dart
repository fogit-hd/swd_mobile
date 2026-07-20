import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../data/mock_sample_data.dart';
import '../../models/review_availability.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/review_context_bar.dart';
import '../../widgets/ui/shimmer_loading.dart';
import '../../widgets/ui/slot_registration_matrix.dart';
import '../../widgets/ui/sticky_action_button.dart';

enum SlotRegistrationMode { lecturer, student }

/// Ma trận đăng ký 6 ngày × 5 slot — Giảng viên (nhiều ô) / SV trưởng nhóm (1 ô).
class SlotRegistrationScreen extends StatefulWidget {
  const SlotRegistrationScreen({
    super.key,
    this.mode = SlotRegistrationMode.lecturer,
    this.occupancyMap,
    this.initialSelection = const {},
    this.onSave,
    this.onSubmit,
    this.externalLoading = false,
    this.showContextBar = false,
  });

  final SlotRegistrationMode mode;
  final Map<String, int>? occupancyMap;
  final Set<String> initialSelection;
  final Future<void> Function(Set<String> keys)? onSave;
  final Future<void> Function(Set<String> keys)? onSubmit;
  final bool externalLoading;
  final bool showContextBar;

  @override
  State<SlotRegistrationScreen> createState() => _SlotRegistrationScreenState();
}

class LecturerSlotRegistrationScreen extends StatefulWidget {
  const LecturerSlotRegistrationScreen({super.key});

  @override
  State<LecturerSlotRegistrationScreen> createState() =>
      _LecturerSlotRegistrationScreenState();
}

class _LecturerSlotRegistrationScreenState
    extends State<LecturerSlotRegistrationScreen> {
  ReviewContext? _context;
  Set<String> _selected = {};
  bool _loading = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AuthScope.of(context).isDemoMode) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (auth.isDemoMode) {
      setState(() {
        _selected = Set.from(MockSampleData.preselectedSlotKeys);
        _loading = false;
      });
      return;
    }

    final ctx = _context;
    if (ctx == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final week = await ReviewService(ApiClient(auth)).fetchAvailabilityWeek(
        roundId: ctx.roundId,
      );
      if (!mounted) return;
      setState(() {
        _selected = week.slots
            .map((s) => SlotRegistrationMatrix.cellKey(s.dayOfWeek, s.slot))
            .toSet();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AvailabilitySlot> _toSlots(Set<String> keys) => keys.map((k) {
        final p = k.split('-');
        return AvailabilitySlot(
          dayOfWeek: int.parse(p[0]),
          slot: int.parse(p[1]),
        );
      }).toList();

  Future<void> _save(Set<String> keys) async {
    if (AuthScope.of(context).isDemoMode) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('[Demo] Đã lưu đăng ký slot')),
      );
      return;
    }

    final ctx = _context;
    if (ctx == null) return;
    if (!ctx.round.isOpen) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đợt "${ctx.round.displayName}" đang ${ctx.round.status ?? 'không Open'}. '
            'Chỉ đăng ký được khi đợt ở trạng thái Open.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = AuthScope.of(context);
      await ReviewService(ApiClient(auth)).saveAvailabilityWeek(
        roundId: ctx.roundId,
        slots: _toSlots(keys),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu đăng ký slot')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit(Set<String> keys) async {
    await _save(keys);
    if (!mounted) return;
    final ctx = _context;
    if (ctx == null) return;
    final auth = AuthScope.of(context);
    setState(() => _loading = true);
    try {
      await ReviewService(ApiClient(auth)).submitAvailabilityWeek(
        roundId: ctx.roundId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi đăng ký cho phòng đào tạo')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final error = _error ?? 'Đã xảy ra lỗi';
      return Column(
        children: [
          ReviewContextBar(onChanged: (c) {
            setState(() => _context = c);
            _load();
          }),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ReviewContextBar(onChanged: (c) {
          setState(() => _context = c);
          _load();
        }),
        Expanded(
          child: SlotRegistrationScreen(
            mode: SlotRegistrationMode.lecturer,
            initialSelection: _selected,
            externalLoading: _loading,
            onSave: _save,
            onSubmit: _submit,
          ),
        ),
      ],
    );
  }
}

class _SlotRegistrationScreenState extends State<SlotRegistrationScreen> {
  late Set<String> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelection);
  }

  @override
  void didUpdateWidget(SlotRegistrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection != widget.initialSelection) {
      _selected = Set.from(widget.initialSelection);
    }
  }

  void _toggle(int day, int slot) {
    final key = SlotRegistrationMatrix.cellKey(day, slot);
    setState(() {
      if (widget.mode == SlotRegistrationMode.student) {
        _selected = _selected.contains(key) ? {} : {key};
      } else if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
  }

  Future<void> _handleSave() async {
    final onSave = widget.onSave;
    if (onSave == null) return;
    setState(() => _saving = true);
    await onSave(_selected);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _handleSubmit() async {
    final onSubmit = widget.onSubmit;
    if (onSubmit == null) return;
    setState(() => _saving = true);
    await onSubmit(_selected);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.externalLoading && _selected.isEmpty;
    final saving = _saving;

    return ColoredBox(
      color: AppTheme.background,
      child: SafeArea(
        child: Stack(
          children: [
            if (loading)
              const Padding(
                padding: AppSpacing.pagePadding,
                child: ShimmerSlotMatrix(),
              )
            else
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  120,
                ),
                children: [
                  Text(
                    widget.mode == SlotRegistrationMode.lecturer
                        ? 'Đăng ký slot trống'
                        : 'Đăng ký slot review nhóm',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.mode == SlotRegistrationMode.lecturer
                        ? 'Chọn khung giờ bạn có thể đi chấm'
                        : 'Trưởng nhóm chọn 1 slot (tối đa 3 nhóm/slot)',
                    style: const TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SlotRegistrationMatrix(
                    selectedKeys: _selected,
                    enabled: !saving,
                    showOccupancy: widget.mode == SlotRegistrationMode.student,
                    occupancyMap: widget.occupancyMap,
                    onToggle: _toggle,
                  ),
                ],
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StickyActionButton(
                label: widget.mode == SlotRegistrationMode.lecturer
                    ? 'Lưu đăng ký (${_selected.length} slot)'
                    : 'Xác nhận đăng ký',
                loading: saving,
                icon: Icons.save_outlined,
                secondaryLabel: widget.mode == SlotRegistrationMode.lecturer
                    ? 'Gửi cho phòng đào tạo'
                    : null,
                onPressed: _selected.isEmpty || saving ? null : _handleSave,
                onSecondaryPressed:
                    _selected.isEmpty || saving ? null : _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
