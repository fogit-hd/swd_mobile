import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_availability.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
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
        semesterId: ctx.semester.id,
        weekStart: ctx.weekStart,
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
    setState(() {
      if (_selectedSlots.contains(entry)) {
        _selectedSlots.remove(entry);
      } else {
        _selectedSlots.add(entry);
      }
    });
  }

  Future<void> _save() async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      await ReviewService(ApiClient(auth)).saveAvailabilityWeek(
        semesterId: ctx.semester.id,
        weekStart: ctx.weekStart,
        slots: _selectedSlots.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu đăng ký slot trống')),
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
      return const AppLoadingIndicator(message: 'Đang tải tuần...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
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
        const Text(
          'Đăng ký slot trống',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'PUT /api/review-availability/week',
          style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
        ),
        const SizedBox(height: 16),
        WeekSlotGrid(
          selectedSlots: _selectedSlots,
          onToggle: _toggleSlot,
          enabled: !_saving,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Lưu (${_selectedSlots.length} slot)'),
          ),
        ),
      ],
    );
  }
}
