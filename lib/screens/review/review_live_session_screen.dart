import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../data/mock_sample_data.dart';
import '../../models/project_review_status.dart';
import '../../models/project_suggestion.dart';
import '../../models/review_attendance.dart';
import '../../services/api_client.dart';
import '../../services/ai_suggestion_service.dart';
import '../../services/review_attendance_service.dart';
import '../../services/review_service.dart';
import '../../services/semester_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/ai_suggestion_popover.dart';
import '../../widgets/ui/pulse_gradient_button.dart';
import '../../widgets/ui/shimmer_loading.dart';
import '../../widgets/ui/status_badge.dart';
import '../lecturer/lecturer_group_documents_screen.dart';
import 'review_submission_screen.dart';

/// Buổi review trực tiếp — điểm danh E360, ghi chú, AI gợi ý, kết thúc review.
class ReviewLiveSessionScreen extends StatefulWidget {
  const ReviewLiveSessionScreen({
    super.key,
    required this.sessionId,
    this.groupId,
    this.groupCode,
    this.submissionId,
    this.initialStatus,
    this.aiSummary,
  });

  final int sessionId;
  final int? groupId;
  final String? groupCode;
  final int? submissionId;
  /// Trạng thái hiển thị từ danh sách lịch (tránh luôn hiện "Đang chấm").
  final ProjectReviewStatus? initialStatus;
  /// Gợi ý AI truyền sẵn (demo / override). Null → gọi BE.
  final ProjectSuggestion? aiSummary;

  @override
  State<ReviewLiveSessionScreen> createState() => _ReviewLiveSessionScreenState();
}

class _ReviewLiveSessionScreenState extends State<ReviewLiveSessionScreen> {
  ReviewAttendanceList? _data;
  final _noteController = TextEditingController();
  final Set<int> _absentIds = {};
  late ProjectReviewStatus _groupStatus;
  bool _loading = true;
  bool _completing = false;
  String? _error;
  ProjectSuggestion? _aiSuggestion;
  int? _resolvedGroupId;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _groupStatus = widget.initialStatus ?? ProjectReviewStatus.inProgress;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Ưu tiên groupId truyền vào; nếu thiếu thì suy ra từ submission / mã nhóm.
  Future<int?> _resolveGroupId(ApiClient client) async {
    final direct = widget.groupId;
    if (direct != null && direct > 0) return direct;

    final submissionId = widget.submissionId;
    if (submissionId != null && submissionId > 0) {
      try {
        final submission =
            await ReviewService(client).fetchSubmission(submissionId);
        if (submission.groupId > 0) return submission.groupId;
      } catch (_) {}
    }

    try {
      final summaries = await ReviewService(client).fetchMySubmissions();
      final code = widget.groupCode?.trim().toLowerCase();
      for (final s in summaries) {
        if (s.sessionId != widget.sessionId || s.groupId <= 0) continue;
        if (code == null || code.isEmpty) return s.groupId;
        // Khớp theo submissionId nếu có.
        if (submissionId != null &&
            submissionId > 0 &&
            s.id == submissionId) {
          return s.groupId;
        }
      }
      // Fallback: lấy submission cùng session (khi chỉ có 1).
      final sameSession = summaries
          .where((s) => s.sessionId == widget.sessionId && s.groupId > 0)
          .toList();
      if (sameSession.length == 1) return sameSession.first.groupId;
      if (submissionId != null && submissionId > 0) {
        for (final s in sameSession) {
          if (s.id == submissionId) return s.groupId;
        }
      }
    } catch (_) {}

    final code = widget.groupCode?.trim();
    if (code != null && code.isNotEmpty) {
      try {
        final semesterService = SemesterService(client);
        final semester = await semesterService.getActiveSemester();
        final groups = await semesterService.fetchGroups(semester.id);
        for (final g in groups) {
          if (g.code != null &&
              g.code!.toLowerCase() == code.toLowerCase()) {
            return g.id;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (auth.isDemoMode) {
      final absent = <int>{};
      final data = MockSampleData.attendanceList;
      for (final s in data.students) {
        if (s.isPresent == false) absent.add(s.studentId);
      }
      setState(() {
        _data = data;
        _resolvedGroupId = data.groupId;
        _groupStatus = widget.initialStatus ?? _groupStatus;
        _absentIds
          ..clear()
          ..addAll(absent);
        _aiSuggestion = widget.aiSummary ?? MockSampleData.aiSuggestion;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      // Giữ badge từ list trong lúc tải — tránh flash "Đang chấm".
      _groupStatus = widget.initialStatus ?? _groupStatus;
    });
    try {
      final client = ApiClient(auth);
      final attendanceService = ReviewAttendanceService(client);
      final groupId = await _resolveGroupId(client);
      if (groupId == null || groupId <= 0) {
        if (!mounted) return;
        setState(() {
          _error =
              'Không xác định được nhóm cần điểm danh. Quay lại lịch chấm và chọn lại nhóm.';
          _loading = false;
        });
        return;
      }

      final data = await attendanceService.fetchAttendance(
        widget.sessionId,
        groupId: groupId,
      );
      final comments = await attendanceService.fetchComments(
        widget.sessionId,
        groupId: data.groupId > 0 ? data.groupId : groupId,
      );
      if (!mounted) return;
      final absent = <int>{};
      for (final s in data.students) {
        if (s.isPresent == false) absent.add(s.studentId);
      }
      // Prefill ghi chú bằng comment mới nhất (nếu có).
      if (comments.isNotEmpty) {
        _noteController.text = comments.last.content;
      }
      // Badge: giữ trạng thái từ danh sách lịch (source of truth khi mở màn).
      // Chỉ NÂNG cấp lên "Đã xong" khi API xác nhận — không bao giờ hạ xuống "Đang chấm".
      var status = widget.initialStatus ?? _groupStatus;
      final submissionId = widget.submissionId;
      if (submissionId != null && submissionId > 0) {
        try {
          final submission =
              await ReviewService(client).fetchSubmission(submissionId);
          if (submission.isSubmitted) {
            status = ProjectReviewStatus.completed;
          }
        } catch (_) {}
      }
      if (data.isGroupCompleted) {
        status = ProjectReviewStatus.completed;
      }

      if (!mounted) return;
      setState(() {
        _data = data;
        _resolvedGroupId = data.groupId > 0 ? data.groupId : groupId;
        _groupStatus = status;
        _absentIds
          ..clear()
          ..addAll(absent);
        _loading = false;
      });
      // AI: non-blocking sau attendance — POST /api/project-suggestions/summary.
      _loadAiSuggestion(client);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadAiSuggestion(ApiClient client) async {
    if (widget.aiSummary != null && widget.aiSummary!.isNotEmpty) {
      if (!mounted) return;
      setState(() => _aiSuggestion = widget.aiSummary);
      return;
    }

    final reviewService = ReviewService(client);
    final aiService = AiSuggestionService(client);

    // 1) Load submission → gọi BE AI (projectName + projectContent).
    final submissionId = widget.submissionId;
    if (submissionId != null && submissionId > 0) {
      try {
        final submission = await reviewService.fetchSubmission(submissionId);
        try {
          final ai = await aiService.generateFromSubmission(
            submission,
            fallbackProjectName: widget.groupCode,
          );
          if (ai != null && mounted) {
            setState(() => _aiSuggestion = ai);
            return;
          }
        } on AiSuggestionException {
          // Soft-fail: vẫn dùng text đã lưu trên form.
        }

        // 2) Fallback: text đã lưu trên form chấm.
        final text = submission.suggestion?.trim().isNotEmpty == true
            ? submission.suggestion
            : submission.reviewerComment;
        if (text != null && text.trim().isNotEmpty && mounted) {
          setState(
            () => _aiSuggestion = ProjectSuggestion.fromPlainText(text.trim()),
          );
          return;
        }
      } catch (_) {}
    }

    // 3) Không có submissionId — thử gợi ý tối thiểu theo mã nhóm / topic.
    final groupCode = widget.groupCode?.trim();
    if (groupCode != null && groupCode.isNotEmpty) {
      try {
        final ai = await aiService.generateSummary(
          projectName: groupCode,
          projectContent:
              'Buổi review session #${widget.sessionId}, nhóm $groupCode. '
              'Hãy tóm tắt hướng đánh giá và gợi ý cải thiện cho đồ án capstone.',
        );
        if (ai != null && mounted) {
          setState(() => _aiSuggestion = ai);
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _aiSuggestion = null);
  }

  /// E360: chạm tên SV → toggle vắng (nền đỏ nhạt).
  void _toggleAbsent(int studentId) {
    setState(() {
      if (_absentIds.contains(studentId)) {
        _absentIds.remove(studentId);
      } else {
        _absentIds.add(studentId);
      }
    });
  }

  List<AttendanceStudent> _buildEntries() {
    final students = _data?.students ?? [];
    return students
        .map(
          (s) => AttendanceStudent(
            studentId: s.studentId,
            studentCode: s.studentCode,
            fullName: s.fullName,
            isPresent: !_absentIds.contains(s.studentId),
            note: s.note,
          ),
        )
        .toList();
  }

  Future<void> _openGroupDocuments() async {
    final groupId = _resolvedGroupId ?? _data?.groupId ?? widget.groupId;
    if (groupId == null || groupId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa xác định được nhóm — không mở được tài liệu'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LecturerGroupDocumentsScreen(
          groupId: groupId,
          groupCode: widget.groupCode ?? _data?.groupCode,
        ),
      ),
    );
  }

  Future<void> _persistNoteIfAny(ReviewAttendanceService service) async {
    final note = _noteController.text.trim();
    final groupId = _data?.groupId;
    if (note.isEmpty || groupId == null || groupId <= 0) return;
    await service.addComment(
      widget.sessionId,
      groupId: groupId,
      content: note,
    );
  }

  Future<void> _saveAttendance() async {
    final groupId = _resolvedGroupId ?? _data?.groupId;
    if (groupId == null || groupId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được nhóm — không thể lưu điểm danh'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _completing = true);
    try {
      final auth = AuthScope.of(context);
      final service = ReviewAttendanceService(ApiClient(auth));
      final updated = await service.submitAttendance(
        widget.sessionId,
        groupId: groupId,
        entries: _buildEntries(),
      );
      await _persistNoteIfAny(service);
      if (!mounted) return;
      setState(() => _data = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu điểm danh')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _completeReview() async {
    final groupId = _resolvedGroupId ?? _data?.groupId;
    if (groupId == null || groupId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không xác định được nhóm — không thể hoàn tất review'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _completing = true);
    try {
      final auth = AuthScope.of(context);
      final client = ApiClient(auth);
      final service = ReviewAttendanceService(client);
      // Luôn lưu điểm danh trước — lỗi "chưa điểm danh" không còn khi user vừa lưu.
      await service.submitAttendance(
        widget.sessionId,
        groupId: groupId,
        entries: _buildEntries(),
      );
      await _persistNoteIfAny(service);

      // Kết thúc buổi còn yêu cầu mọi reviewer đã GỬI bài chấm checklist.
      final submissionId = widget.submissionId;
      if (submissionId != null && submissionId > 0) {
        final submission =
            await ReviewService(client).fetchSubmission(submissionId);
        if (!submission.isSubmitted) {
          if (!mounted) return;
          setState(() => _completing = false);
          final goFill = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Chưa gửi bài chấm'),
              content: const Text(
                'Điểm danh đã lưu. Để kết thúc buổi, bạn cần gửi bài chấm checklist '
                'ở form review (và các giảng viên được phân công khác cũng phải gửi).',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Để sau'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Mở form chấm'),
                ),
              ],
            ),
          );
          if (goFill == true && mounted) {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ReviewSubmissionScreen(
                  submissionId: submissionId,
                  sessionTitle: widget.groupCode ?? 'Bài chấm review',
                ),
              ),
            );
          }
          return;
        }
      }

      await service.completeGroupReview(
        sessionId: widget.sessionId,
        groupId: groupId,
      );
      if (!mounted) return;
      setState(() => _groupStatus = ProjectReviewStatus.completed);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hoàn tất review nhóm')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.groupCode ?? 'Buổi review'),
        actions: [
          IconButton(
            tooltip: 'Tài liệu nhóm',
            onPressed: _openGroupDocuments,
            icon: const Icon(Icons.folder_open_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: StatusBadge(status: _groupStatus, compact: true),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: AppSpacing.pagePadding,
        child: ShimmerLoading(itemCount: 5, itemHeight: 48),
      );
    }

    if (_error != null) {
      final error = _error ?? 'Đã xảy ra lỗi';
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.darkGray,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            160,
          ),
          children: [
            Text(
              '${data.groupCode ?? ''} • ${data.sessionCode ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (data.room != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  'Phòng ${data.room} • Ca ${data.slot ?? '—'}',
                  style: const TextStyle(
                    color: AppTheme.mediumGray,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _openGroupDocuments,
              icon: const Icon(Icons.folder_open_outlined, size: 18),
              label: const Text('Xem / tải tài liệu nhóm'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Điểm danh — chạm tên SV vắng mặt',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap + ChoiceChip — E360 attendance
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: data.students.map((s) {
                final absent = _absentIds.contains(s.studentId);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: ActionChip(
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: absent
                          ? AppTheme.error.withValues(alpha: 0.15)
                          : AppTheme.statusActiveBg,
                      child: Text(
                        (s.fullName ?? s.studentCode ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: absent ? AppTheme.error : AppTheme.primary,
                        ),
                      ),
                    ),
                    label: Text(s.fullName ?? s.studentCode ?? '—'),
                    backgroundColor:
                        absent ? AppTheme.errorLight : AppTheme.white,
                    side: BorderSide(
                      color: absent ? AppTheme.error : AppTheme.lightGray,
                    ),
                    // Vùng chạm ≥ 44pt
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    onPressed: _completing
                        ? null
                        : () => _toggleAbsent(s.studentId),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_aiSuggestion != null && _aiSuggestion!.isNotEmpty) ...[
              AiSuggestionPopover(suggestion: _aiSuggestion!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ghi chú / Nhận xét nhanh',
                alignLabelWithHint: true,
                hintText: 'Nhận xét tổng quan buổi review...',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _completing ? null : _saveAttendance,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Lưu điểm danh'),
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kết thúc khi đã điểm danh đủ và mọi giảng viên phân công đã gửi bài chấm.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.mediumGray,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PulseGradientButton(
                label: 'Kết thúc buổi review',
                loading: _completing,
                onPressed: _completeReview,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
