import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/create_review_session.dart';
import '../../models/review_scheduling.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/week_utils.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/review_context_bar.dart';

class ModeratorSchedulingScreen extends StatefulWidget {
  const ModeratorSchedulingScreen({super.key});

  @override
  State<ModeratorSchedulingScreen> createState() =>
      _ModeratorSchedulingScreenState();
}

class _ModeratorSchedulingScreenState extends State<ModeratorSchedulingScreen> {
  ReviewSchedulingBoard? _board;
  ReviewContext? _context;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  Future<void> _load() async {
    final reviewCtx = _context;
    if (reviewCtx == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      final board = await ReviewService(ApiClient(auth)).fetchSchedulingBoard(
        semesterId: reviewCtx.semester.id,
        reviewType: reviewCtx.reviewType.apiValue,
        weekStart: reviewCtx.weekStart,
      );
      if (!mounted) return;
      setState(() {
        _board = board;
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

  Future<void> _saveAssignments() async {
    final board = _board;
    if (board == null || board.sessions.isEmpty) return;

    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      final service = ReviewService(ApiClient(auth));
      for (final session in board.sessions) {
        if (session.id > 0) {
          await service.updateSession(session);
        }
      }
      await service.bulkAssignSessions(board.sessions);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu xếp lịch')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createSession(SchedulingGroup group) async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      await ReviewService(ApiClient(auth)).createSession(
        CreateReviewSessionRequest(
          code: '${group.code ?? 'G${group.id}'}-${ctx.reviewType.apiValue}',
          groupId: group.id,
          type: ctx.reviewType.apiValue,
          slot: 1,
          room: 'TBD',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo phiên cho ${group.code ?? group.id}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editReviewers(SchedulingSession session) async {
    final board = _board;
    if (board == null) return;

    final selected = {...session.reviewerIds};
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Phân công GV — ${session.groupCode ?? session.code}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: board.lecturers.map((lecturer) {
                    return CheckboxListTile(
                      value: selected.contains(lecturer.id),
                      title: Text(lecturer.displayName),
                      subtitle: Text(lecturer.department ?? lecturer.email ?? ''),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selected.add(lecturer.id);
                          } else {
                            selected.remove(lecturer.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Huỷ'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final updated = SchedulingSession(
      id: session.id,
      code: session.code,
      groupId: session.groupId,
      groupCode: session.groupCode,
      type: session.type,
      status: session.status,
      reviewerIds: result.toList(),
      sessionDate: session.sessionDate,
      dayOfWeek: session.dayOfWeek,
      slot: session.slot,
      room: session.room,
    );

    setState(() {
      _board = ReviewSchedulingBoard(
        semesterId: board.semesterId,
        reviewType: board.reviewType,
        weekStart: board.weekStart,
        lecturers: board.lecturers,
        availability: board.availability,
        groups: board.groups,
        sessions: board.sessions
            .map((s) => s.id == updated.id ? updated : s)
            .toList(),
      );
    });
  }

  String _lecturerName(ReviewSchedulingBoard board, int id) {
    for (final l in board.lecturers) {
      if (l.id == id) return l.displayName;
    }
    return 'GV $id';
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
    if (_context == null || (_loading && _board == null)) {
      return const AppLoadingIndicator(message: 'Đang tải bảng xếp lịch...');
    }

    if (_error != null && _board == null) {
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

    final board = _board;
    if (board == null) {
      return const SizedBox.shrink();
    }

    final assignedIds = board.sessions.map((s) => s.groupId).toSet();
    final unassigned =
        board.groups.where((g) => !assignedIds.contains(g.id)).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Xếp lịch review',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${board.sessions.length} phiên • '
            '${board.availability.length} slot GV đăng ký • '
            '${board.lecturers.length} giảng viên',
            style: const TextStyle(color: AppTheme.mediumGray, fontSize: 14),
          ),
          if (board.availability.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Slot GV đã đăng ký', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: board.availability.map((a) {
                return Chip(
                  label: Text(
                    '${_lecturerName(board, a.lecturerId)} • '
                    '${dayLabel(a.dayOfWeek)} ca ${a.slot}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
          if (unassigned.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Nhóm chưa có phiên', style: TextStyle(fontWeight: FontWeight.w600)),
            ...unassigned.map(
              (group) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(group.code ?? 'Nhóm ${group.id}'),
                subtitle: Text(group.projectName ?? ''),
                trailing: TextButton(
                  onPressed: _saving ? null : () => _createSession(group),
                  child: const Text('Tạo phiên'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (board.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có phiên review. Tạo phiên cho nhóm ở trên.',
                style: TextStyle(color: AppTheme.mediumGray),
              ),
            )
          else
            ...board.sessions.map((session) {
              final reviewers = session.reviewerIds
                  .map((id) => _lecturerName(board, id))
                  .join(', ');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(session.groupCode ?? session.code ?? 'Nhóm'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ca ${session.slot ?? '—'} • ${session.room ?? '—'}'),
                      Text('GV: ${reviewers.isEmpty ? 'Chưa phân công' : reviewers}'),
                      Text('Trạng thái: ${session.status ?? 'Draft'}'),
                    ],
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: _saving ? null : () => _editReviewers(session),
                ),
              );
            }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving || board.sessions.isEmpty ? null : _saveAssignments,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lưu xếp lịch (PATCH + bulk-assign)'),
            ),
          ),
        ],
      ),
    );
  }
}
