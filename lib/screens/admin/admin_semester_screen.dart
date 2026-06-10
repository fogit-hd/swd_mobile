import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/create_semester.dart';
import '../../models/semester.dart';
import '../../services/api_client.dart';
import '../../services/semester_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';

class AdminSemesterScreen extends StatefulWidget {
  const AdminSemesterScreen({super.key});

  @override
  State<AdminSemesterScreen> createState() => _AdminSemesterScreenState();
}

class _AdminSemesterScreenState extends State<AdminSemesterScreen> {
  List<Semester>? _semesters;
  bool _loading = true;
  String? _error;

  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController(text: '2025-2026');
  final _startController = TextEditingController(text: '2026-01-01');
  final _endController = TextEditingController(text: '2026-06-30');
  bool _isActive = true;
  bool _creating = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _yearController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_semesters == null && _error == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthScope.of(context);
      final list = await SemesterService(ApiClient(auth)).fetchSemesters();
      if (!mounted) return;
      setState(() {
        _semesters = list;
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

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final auth = AuthScope.of(context);
      await SemesterService(ApiClient(auth)).createSemester(
        CreateSemesterRequest(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          academicYear: _yearController.text.trim(),
          startDate: _startController.text.trim(),
          endDate: _endController.text.trim(),
          isActive: _isActive,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo học kỳ')),
      );
      _codeController.clear();
      _nameController.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && (_semesters == null || _semesters!.isEmpty)) {
      return const AppLoadingIndicator(message: 'Đang tải học kỳ...');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Quản lý học kỳ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_semesters != null)
            ..._semesters!.map(
              (s) => Card(
                child: ListTile(
                  title: Text(s.displayName),
                  subtitle: Text(
                    '${s.code ?? '—'} • ${s.academicYear ?? '—'}'
                    '${s.isActive ? ' • Đang active' : ''}',
                  ),
                ),
              ),
            ),
          const Divider(height: 32),
          const Text(
            'Tạo học kỳ mới',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: 'Mã học kỳ'),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên học kỳ'),
          ),
          TextField(
            controller: _yearController,
            decoration: const InputDecoration(labelText: 'Năm học'),
          ),
          TextField(
            controller: _startController,
            decoration: const InputDecoration(labelText: 'Ngày bắt đầu (YYYY-MM-DD)'),
          ),
          TextField(
            controller: _endController,
            decoration: const InputDecoration(labelText: 'Ngày kết thúc (YYYY-MM-DD)'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tạo học kỳ'),
          ),
        ],
      ),
    );
  }
}
