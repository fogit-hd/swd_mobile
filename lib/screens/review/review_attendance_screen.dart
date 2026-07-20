import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_attendance.dart';
import '../../services/api_client.dart';
import '../../services/review_attendance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';

class ReviewAttendanceScreen extends StatefulWidget {
  const ReviewAttendanceScreen({
    super.key,
    required this.sessionId,
    this.sessionTitle,
  });

  final int sessionId;
  final String? sessionTitle;

  @override
  State<ReviewAttendanceScreen> createState() => _ReviewAttendanceScreenState();
}

class _ReviewAttendanceScreenState extends State<ReviewAttendanceScreen> {
  ReviewAttendanceList? _data;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      final data = await ReviewAttendanceService(ApiClient(auth))
          .fetchAttendance(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  void _togglePresent(int index, bool? value) {
    final data = _data;
    if (data == null) return;
    final students = List<AttendanceStudent>.from(data.students);
    final s = students[index];
    students[index] = AttendanceStudent(
      studentId: s.studentId,
      studentCode: s.studentCode,
      fullName: s.fullName,
      isPresent: value ?? false,
      note: s.note,
    );
    setState(() {
      _data = ReviewAttendanceList(
        sessionId: data.sessionId,
        sessionCode: data.sessionCode,
        groupId: data.groupId,
        groupCode: data.groupCode,
        sessionDate: data.sessionDate,
        slot: data.slot,
        room: data.room,
        students: students,
      );
    });
  }

  Future<void> _save() async {
    final data = _data;
    if (data == null) return;
    if (data.groupId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu groupId — không thể lưu điểm danh'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      final updated = await ReviewAttendanceService(ApiClient(auth))
          .submitAttendance(
        widget.sessionId,
        groupId: data.groupId,
        entries: data.students,
      );
      if (!mounted) return;
      setState(() {
        _data = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu điểm danh')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionTitle ?? 'Điểm danh'),
      ),
      body: _buildBody(),
      floatingActionButton: _data != null
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Lưu điểm danh'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingIndicator(message: 'Đang tải danh sách...');
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

    final data = _data;
    if (data == null) {
      return const Center(
        child: Text(
          'Không có dữ liệu điểm danh.',
          style: TextStyle(color: AppTheme.mediumGray),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${data.groupCode ?? 'Nhóm'} • ${data.sessionCode ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (data.room != null)
          Text(
            'Phòng ${data.room} • Ca ${data.slot ?? '—'}',
            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 13),
          ),
        const SizedBox(height: 16),
        ...List.generate(data.students.length, (i) {
          final s = data.students[i];
          return Card(
            child: CheckboxListTile(
              title: Text(s.fullName ?? s.studentCode ?? '—'),
              subtitle: Text(s.studentCode ?? ''),
              value: s.isPresent ?? false,
              tristate: true,
              onChanged: _saving ? null : (v) => _togglePresent(i, v),
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }
}
