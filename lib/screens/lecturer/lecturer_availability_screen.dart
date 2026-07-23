import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_availability.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/review_slot_schedule.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/review_context_bar.dart';
import '../../widgets/week_slot_grid.dart';

class LecturerAvailabilityScreen extends StatefulWidget {
  const LecturerAvailabilityScreen({super.key});

  @override
  State<LecturerAvailabilityScreen> createState() =>
      _LecturerAvailabilityScreenState();
}

class _LecturerAvailabilityScreenState extends State<LecturerAvailabilityScreen> {
  ReviewContext? _context;
  Set<AvailabilitySlot> _selectedSlots = {};
  bool _loading = false;
  bool _saving = false;
  bool _submitting = false;
  String? _error;

  Future<void> _load() async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      final week = await ReviewService(ApiClient(auth)).fetchAvailabilityWeek(
        roundId: ctx.roundId,
      );
      if (!mounted) return;
      setState(() {
        _selectedSlots = week.slots.toSet();
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

  void _onContextChanged(ReviewContext ctx) {
    setState(() => _context = ctx);
    _load();
  }

  void _toggleSlot(int dayOfWeek, int slot) {
    final entry = AvailabilitySlot(dayOfWeek: dayOfWeek, slot: slot);
    if (_selectedSlots.contains(entry)) {
      setState(() => _selectedSlots.remove(entry));
      return;
    }
    if (_selectedSlots.length >= ReviewSlotSchedule.maxLecturerSelectedSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chỉ được chọn tối đa '
            '${ReviewSlotSchedule.maxLecturerSelectedSlots} Slot.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _selectedSlots.add(entry));
  }

  Future<void> _save() async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      await ReviewService(ApiClient(auth)).saveAvailabilityWeek(
        roundId: ctx.roundId,
        slots: _selectedSlots.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu đăng ký ca trống')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() => _submitting = true);
    try {
      final auth = AuthScope.of(context);
      await ReviewService(ApiClient(auth)).submitAvailabilityWeek(
        roundId: ctx.roundId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi đăng ký ca cho phòng đào tạo')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReviewContextBar(onChanged: _onContextChanged),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_context == null || (_loading && _selectedSlots.isEmpty && _error == null)) {
      return const AppLoadingIndicator(message: 'Đang tải đợt review...');
    }

    if (_error != null) {
      final error = _error ?? 'Đã xảy ra lỗi';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Đăng ký slot · ${_context!.round.displayName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        WeekSlotGrid(
          selectedSlots: _selectedSlots,
          onToggle: _toggleSlot,
          enabled: !_saving && !_submitting,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving || _submitting ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Lưu nháp (${_selectedSlots.length}/'
                    '${ReviewSlotSchedule.maxLecturerSelectedSlots} ca)',
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saving || _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Gửi đăng ký'),
          ),
        ),
      ],
    );
  }
}
