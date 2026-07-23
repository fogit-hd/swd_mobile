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
import '../../utils/review_slot_schedule.dart';

enum SlotRegistrationMode { lecturer, student }

/// Ma trận đăng ký 6 ngày × 5 slot — Giảng viên (nhiều ô) / SV trưởng nhóm (1 ô).
class SlotRegistrationScreen extends StatefulWidget {
  const SlotRegistrationScreen({
    super.key,
    this.mode = SlotRegistrationMode.lecturer,
    this.occupancyMap,
    this.maxRegistrationsPerSlot,
    this.initialSelection = const {},
    this.onSave,
    this.onSubmit,
    this.externalLoading = false,
    this.showContextBar = false,
    this.enabled = true,
    this.isSubmitted = false,
    this.roundStatusLabel,
  });

  final SlotRegistrationMode mode;
  final Map<String, int>? occupancyMap;
  final int? maxRegistrationsPerSlot;
  final Set<String> initialSelection;
  final Future<void> Function(Set<String> keys)? onSave;
  final Future<void> Function(Set<String> keys)? onSubmit;
  final bool externalLoading;
  final bool showContextBar;
  final bool enabled;
  final bool isSubmitted;
  final String? roundStatusLabel;

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
  bool _isSubmitted = false;
  bool _loading = false;
  String? _error;
  bool _initialized = false;
  Map<String, int> _slotRegistrationCounts = const {};
  int _maxRegistrationsPerSlot = 4;

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
        _slotRegistrationCounts = MockSampleData.lecturerRegistrationCounts;
        _maxRegistrationsPerSlot = 4;
        _isSubmitted = false;
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
      final service = ReviewService(ApiClient(auth));
      final week = await service.fetchAvailabilityWeek(roundId: ctx.roundId);
      if (!mounted) return;
      setState(() {
        _selected = week.slots
            .map((s) => SlotRegistrationMatrix.cellKey(s.dayOfWeek, s.slot))
            .toSet();
        _isSubmitted = week.isSubmitted;
        _slotRegistrationCounts = week.registrationCountMap;
        _maxRegistrationsPerSlot = week.maxRegistrationsPerSlot;
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
    return AvailabilitySlot(dayOfWeek: int.parse(p[0]), slot: int.parse(p[1]));
  }).toList();

  Future<bool> _persist(Set<String> keys) async {
    if (AuthScope.of(context).isDemoMode) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('[Chế độ demo] Đã lưu đăng ký Slot')),
      );
      return true;
    }

    final ctx = _context;
    if (ctx == null) return false;
    if (!ctx.round.isOpen) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đợt "${ctx.round.displayName}" đang ${ctx.round.statusLabel}. '
            'Chỉ đăng ký được khi đợt đang mở.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return false;
    }
    setState(() => _loading = true);
    try {
      final auth = AuthScope.of(context);
      final week = await ReviewService(
        ApiClient(auth),
      ).saveAvailabilityWeek(roundId: ctx.roundId, slots: _toSlots(keys));
      if (!mounted) return false;
      setState(() {
        _isSubmitted = week.isSubmitted;
        _slotRegistrationCounts = week.registrationCountMap;
        _maxRegistrationsPerSlot = week.maxRegistrationsPerSlot;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bản nháp đăng ký Slot')),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Set<String> keys) async {
    await _persist(keys);
  }

  Future<void> _submit(Set<String> keys) async {
    final saved = await _persist(keys);
    if (!saved) return;
    if (!mounted) return;
    final ctx = _context;
    if (ctx == null) return;
    final auth = AuthScope.of(context);
    setState(() => _loading = true);
    try {
      final week = await ReviewService(
        ApiClient(auth),
      ).submitAvailabilityWeek(roundId: ctx.roundId);
      if (!mounted) return;
      setState(() {
        _isSubmitted = week.isSubmitted;
        _slotRegistrationCounts = week.registrationCountMap;
        _maxRegistrationsPerSlot = week.maxRegistrationsPerSlot;
      });
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
          ReviewContextBar(
            onChanged: (c) {
              setState(() => _context = c);
              _load();
            },
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ReviewContextBar(
          onChanged: (c) {
            setState(() => _context = c);
            _load();
          },
        ),
        Expanded(
          child: SlotRegistrationScreen(
            mode: SlotRegistrationMode.lecturer,
            initialSelection: _selected,
            externalLoading: _loading,
            enabled: _context?.round.isOpen ?? false,
            isSubmitted: _isSubmitted,
            roundStatusLabel: _context?.round.statusLabel,
            occupancyMap: _slotRegistrationCounts,
            maxRegistrationsPerSlot: _maxRegistrationsPerSlot,
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

  Widget _buildLegendDot(Color color, String label, {Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    );
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 130),
                children: [
                  // Hero Gradient Header Banner: High contrast, royal blue/indigo depth & neon highlights
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1E3A8A),
                          Color(0xFF312E81),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1E40AF,
                          ).withValues(alpha: 0.35),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: AppTheme.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.bolt_rounded,
                                      color: AppTheme.black,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.mode == SlotRegistrationMode.lecturer
                                        ? 'GIẢNG VIÊN REVIEW'
                                        : 'NHÓM SINH VIÊN',
                                    style: const TextStyle(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF06B6D4,
                                ).withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: const Color(
                                    0xFF38BDF8,
                                  ).withValues(alpha: 0.6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF06B6D4,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đã chọn: ${_selected.length} Slot',
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.mode == SlotRegistrationMode.lecturer
                              ? 'Đăng Ký Slot Review'
                              : 'Đăng Ký Slot Review Nhóm',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.mode == SlotRegistrationMode.lecturer
                              ? 'Chọn các Slot bạn có thể tham gia. Phòng Đào tạo sẽ dùng bản đã nộp để xếp lịch.'
                              : 'Trưởng nhóm chọn Slot phù hợp với toàn bộ thành viên.',
                          style: TextStyle(
                            color: AppTheme.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Maximize Breathing Room: Push legend down
                  const SizedBox(height: 24),
                  // Legend bar styled inside a sleek Glassmorphic/elevated pill container
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildLegendDot(
                          const Color(0xFFF1F5F9),
                          'Có thể chọn',
                          border: const Color(0xFFCBD5E1),
                        ),
                        _buildLegendDot(const Color(0xFF2563EB), 'Đang chọn'),
                        _buildLegendDot(
                          const Color(0xFFEDE9FE),
                          widget.mode == SlotRegistrationMode.lecturer
                              ? 'Số Giảng viên đã đăng ký / ${widget.maxRegistrationsPerSlot ?? 4}'
                              : 'Số nhóm đã đăng ký / ${widget.maxRegistrationsPerSlot ?? 3}',
                          border: const Color(0xFF8B5CF6),
                        ),
                        _buildLegendDot(
                          const Color(0xFFE2E8F0),
                          'Đã đủ đăng ký',
                          border: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                  // Maximize Breathing Room: Big gap pushing grid away from legends
                  const SizedBox(height: 26),
                  Card(
                    color: widget.isSubmitted
                        ? AppTheme.statusActiveBg
                        : const Color(0xFFFFFBEB),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            widget.isSubmitted
                                ? Icons.verified_outlined
                                : Icons.edit_calendar_outlined,
                            color: widget.isSubmitted
                                ? AppTheme.success
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.enabled
                                  ? widget.isSubmitted
                                        ? 'Đã nộp chính thức. Bạn có thể chỉnh sửa và nộp lại khi đợt còn mở.'
                                        : 'Đang soạn bản đăng ký. ${ReviewSlotSchedule.lunchBreak}.'
                                  : 'Đợt review đang ${widget.roundStatusLabel ?? 'đóng'} — chỉ được xem các Slot đã đăng ký.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SlotRegistrationMatrix(
                    selectedKeys: _selected,
                    enabled: widget.enabled && !saving,
                    showOccupancy: true,
                    occupancyMap: widget.occupancyMap,
                    maxOccupancy:
                        widget.maxRegistrationsPerSlot ??
                        (widget.mode == SlotRegistrationMode.lecturer ? 4 : 3),
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
                    ? 'Lưu nháp (${_selected.length} Slot)'
                    : 'Xác nhận đăng ký',
                loading: saving,
                icon: Icons.save_outlined,
                secondaryLabel: widget.mode == SlotRegistrationMode.lecturer
                    ? widget.isSubmitted
                          ? 'Nộp lại'
                          : 'Nộp chính thức'
                    : null,
                onPressed: !widget.enabled || _selected.isEmpty || saving
                    ? null
                    : _handleSave,
                onSecondaryPressed:
                    !widget.enabled || _selected.isEmpty || saving
                    ? null
                    : _handleSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
