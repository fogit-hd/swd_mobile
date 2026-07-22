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
        const SnackBar(content: Text('[Chế độ demo] Đã lưu đăng ký ca')),
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
            'Đợt "${ctx.round.displayName}" đang ${ctx.round.statusLabel}. '
            'Chỉ đăng ký được khi đợt đang mở.',
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
        const SnackBar(content: Text('Đã lưu đăng ký ca')),
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
                  // Hero Gradient Header Banner: High contrast, royal blue/indigo depth
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E293B), Color(0xFF1E40AF), Color(0xFF312E81)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.28),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: AppTheme.white.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded, color: Color(0xFFFACC15), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.mode == SlotRegistrationMode.lecturer
                                        ? 'HỘI ĐỒNG ĐÁNH GIÁ'
                                        : 'NHÓM SINH VIÊN',
                                    style: const TextStyle(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'Đã chọn: ${_selected.length} ca',
                                style: const TextStyle(
                                  color: Color(0xFF6EE7B7),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          widget.mode == SlotRegistrationMode.lecturer
                              ? 'Đăng Ký Lịch Bảo Vệ & Chấm Điểm'
                              : 'Đăng Ký Ca Review Nhóm Đồ Án',
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
                              ? 'Vui lòng chọn các khung giờ bạn có thể tham gia chấm hội đồng. Lịch sẽ được tổng hợp tự động.'
                              : 'Trưởng nhóm chọn 1 ca bảo vệ phù hợp với lịch trình của toàn bộ thành viên trong nhóm.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendDot(const Color(0xFFF1F5F9), 'Khả dụng', border: const Color(0xFFCBD5E1)),
                        _buildLegendDot(const Color(0xFF2563EB), 'Đang chọn'),
                        _buildLegendDot(AppTheme.errorLight, 'Kín chỗ / Khóa', border: AppTheme.error.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                  // Maximize Breathing Room: Big gap pushing grid away from legends
                  const SizedBox(height: 26),
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
                    ? 'Lưu đăng ký (${_selected.length} ca)'
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
