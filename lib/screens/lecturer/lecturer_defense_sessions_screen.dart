import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/auth_scope.dart';
import '../../models/capstone_group.dart';
import '../../models/defense.dart';
import '../../services/api_client.dart';
import '../../services/defense_hub_client.dart';
import '../../services/defense_service.dart';
import '../../services/semester_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/display_labels.dart';
import '../../widgets/app_loading.dart';
import 'lecturer_group_documents_screen.dart';

class LecturerDefenseSessionsScreen extends StatefulWidget {
  const LecturerDefenseSessionsScreen({super.key});

  @override
  State<LecturerDefenseSessionsScreen> createState() =>
      _LecturerDefenseSessionsScreenState();
}

class _LecturerDefenseSessionsScreenState
    extends State<LecturerDefenseSessionsScreen> {
  List<DefenseSessionAssignment>? _sessions;
  bool _loading = true;
  String? _error;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      if (auth.isDemoMode) {
        if (!mounted) return;
        setState(() {
          _sessions = [];
          _loading = false;
        });
        return;
      }

      final sessions =
          await DefenseService(ApiClient(auth)).fetchMyBoardSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
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

  Future<void> _openSession(DefenseSessionAssignment session) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DefenseSessionDetailScreen(session: session),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppLoadingIndicator(message: 'Đang tải phiên bảo vệ...');
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

    final sessions = _sessions ?? [];
    if (sessions.isEmpty) {
      return const Center(child: Text('Chưa có phiên bảo vệ nào.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final s = sessions[index];
          return Card(
            child: ListTile(
              title: Text(s.title),
              subtitle: Text(
                '${s.councilCode ?? ''} • ${s.room ?? ''} • Ca ${s.slot ?? '—'}',
              ),
              trailing: Chip(
                label: Text(
                  s.isEnded
                      ? 'Kết thúc'
                      : s.isStarted
                          ? 'Đang diễn ra'
                          : 'Chưa bắt đầu',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              onTap: () => _openSession(s),
            ),
          );
        },
      ),
    );
  }
}

class DefenseSessionDetailScreen extends StatefulWidget {
  const DefenseSessionDetailScreen({super.key, required this.session});

  final DefenseSessionAssignment session;

  @override
  State<DefenseSessionDetailScreen> createState() =>
      _DefenseSessionDetailScreenState();
}

class _DefenseSessionDetailScreenState
    extends State<DefenseSessionDetailScreen> {
  DefenseSessionState? _state;
  List<CapstoneGroupMember> _members = [];
  List<DefenseEvidence> _evidences = [];
  final Map<String, double> _localScores = {};
  bool _loading = true;
  bool _busy = false;
  String? _hubStatus;
  DefenseHubClient? _hub;
  final List<StreamSubscription<dynamic>> _subs = [];

  DefenseService get _service => DefenseService(ApiClient(AuthScope.of(context)));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _hub?.dispose();
    super.dispose();
  }

  String _scoreKey(int studentId, String scoreType) => '$studentId|$scoreType';

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _hubStatus = null;
    });
    try {
      final auth = AuthScope.of(context);
      final client = ApiClient(auth);
      final defense = DefenseService(client);
      final semesterService = SemesterService(client);

      final state = await defense.resolveByCode(
        widget.session.code ?? widget.session.id.toString(),
      );
      final groupId = state.groupId > 0 ? state.groupId : widget.session.groupId;
      final members = groupId > 0
          ? await semesterService.fetchGroupMembers(groupId: groupId)
          : <CapstoneGroupMember>[];
      final evidences = await defense.fetchEvidences(widget.session.id);

      if (!mounted) return;
      setState(() {
        _state = state;
        _members = members;
        _evidences = evidences;
        _loading = false;
      });

      await _connectHub(widget.session.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _connectHub(int sessionId) async {
    final auth = AuthScope.of(context);
    if (auth.isDemoMode) return;
    final hub = DefenseHubClient(auth);
    try {
      await hub.connectAndJoin(sessionId);
      _subs.add(hub.onSessionState.listen((s) {
        if (!mounted) return;
        setState(() => _state = s);
      }));
      _subs.add(hub.onScoreSubmitted.listen((score) {
        if (!mounted) return;
        final type = score.scoreType ?? 'BaoVe';
        final value = score.scoreValue;
        if (value != null) {
          setState(() {
            _localScores[_scoreKey(score.studentId, type)] = value;
            _hubStatus = 'Điểm mới: SV #${score.studentId} ($type) = $value';
          });
        }
      }));
      _subs.add(hub.onEvidenceCaptured.listen((e) {
        if (!mounted) return;
        setState(() {
          _evidences = [e, ..._evidences.where((x) => x.id != e.id)];
          _hubStatus = 'Có minh chứng mới';
        });
      }));
      _subs.add(hub.onMemberJoined.listen((name) {
        if (!mounted) return;
        setState(() => _hubStatus = '$name đã tham gia phiên');
      }));
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _hubStatus = 'Realtime: đã kết nối';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hubStatus = 'Realtime offline: $e');
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final state = await _service.startSession(widget.session.id);
      if (!mounted) return;
      setState(() => _state = state);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    setState(() => _busy = true);
    try {
      final state = await _service.closeSession(widget.session.id);
      if (!mounted) return;
      setState(() => _state = state);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitScore({
    required CapstoneGroupMember student,
    required String scoreType,
  }) async {
    final state = _state;
    if (state == null || state.startedAt == null || state.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ chấm điểm khi phiên đang diễn ra')),
      );
      return;
    }

    final key = _scoreKey(student.id, scoreType);
    final controller = TextEditingController(
      text: (_localScores[key] ?? 8.0).toStringAsFixed(1),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Điểm ${DisplayLabels.defenseScoreType(scoreType)} — ${student.displayName}',
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Điểm (0–10)',
            hintText: '8.5',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    if (value < 0 || value > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điểm phải trong khoảng 0–10'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final submitted = await _service.submitScore(
        sessionId: widget.session.id,
        studentId: student.id,
        scoreType: scoreType,
        scoreValue: value,
      );
      if (!mounted) return;
      setState(() {
        _localScores[key] = submitted.scoreValue ?? value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã gửi điểm ${DisplayLabels.defenseScoreType(scoreType)}: $value',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadEvidence() async {
    final state = _state;
    if (state == null || state.startedAt == null || state.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ tải minh chứng khi phiên đang diễn ra')),
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file == null || !mounted) return;

    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi chú minh chứng'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Tùy chọn',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, noteController.text),
            child: const Text('Tải lên'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      final evidence = await _service.uploadEvidence(
        sessionId: widget.session.id,
        bytes: bytes,
        fileName: file.name,
        note: note.trim().isEmpty ? null : note.trim(),
      );
      if (!mounted) return;
      setState(() {
        _evidences = [evidence, ..._evidences];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tải minh chứng')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final state = _state;
    final canScore = state?.startedAt != null &&
        state?.endedAt == null &&
        state?.isLocked != true;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.title),
        actions: [
          IconButton(
            tooltip: 'Tài liệu nhóm',
            onPressed: () {
              final groupId =
                  (_state?.groupId ?? 0) > 0 ? _state!.groupId : s.groupId;
              if (groupId <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phiên này chưa gắn nhóm — không mở tài liệu'),
                  ),
                );
                return;
              }
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => LecturerGroupDocumentsScreen(
                    groupId: groupId,
                    groupCode: s.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingIndicator(message: 'Đang tải phiên bảo vệ...')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Mã phiên: ${s.code ?? s.id}'),
                Text('Hội đồng: ${s.councilCode ?? '—'}'),
                Text('Phòng: ${s.room ?? '—'} • Ca ${s.slot ?? '—'}'),
                if (state != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.isChairman
                        ? 'Vai trò: Chủ tịch'
                        : 'Vai trò: Thành viên',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    state.isLocked
                        ? 'Trạng thái: Đã khóa'
                        : state.startedAt != null
                            ? 'Trạng thái: Đang diễn ra'
                            : 'Trạng thái: Chưa bắt đầu',
                  ),
                ],
                if (_hubStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _hubStatus!,
                    style: const TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                if (state?.isChairman == true) ...[
                  if (state?.startedAt == null)
                    ElevatedButton(
                      onPressed: _busy ? null : _start,
                      child: const Text('Bắt đầu phiên bảo vệ'),
                    ),
                  if (state?.startedAt != null && state?.endedAt == null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _busy ? null : _close,
                      child: const Text('Kết thúc phiên bảo vệ'),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                const Text(
                  'Chấm điểm thành viên',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bảo vệ / Cá nhân — điểm 0–10',
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (_members.isEmpty)
                  const Text(
                    'Không tải được danh sách sinh viên nhóm. Kiểm tra học kỳ / mã nhóm.',
                    style: TextStyle(color: AppTheme.mediumGray),
                  )
                else
                  ..._members.map((m) {
                    final baoVe = _localScores[_scoreKey(m.id, 'BaoVe')];
                    final nguoi = _localScores[_scoreKey(m.id, 'Nguoi')];
                    return Card(
                      child: ListTile(
                        title: Text(m.displayName),
                        subtitle: Text(
                          '${m.code ?? ''}'
                          '${baoVe != null ? ' · Bảo vệ $baoVe' : ''}'
                          '${nguoi != null ? ' · Cá nhân $nguoi' : ''}',
                        ),
                        trailing: canScore
                            ? PopupMenuButton<String>(
                                onSelected: (type) => _submitScore(
                                  student: m,
                                  scoreType: type,
                                ),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'BaoVe',
                                    child: Text('Chấm bảo vệ'),
                                  ),
                                  PopupMenuItem(
                                    value: 'Nguoi',
                                    child: Text('Chấm cá nhân'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Minh chứng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (canScore)
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _uploadEvidence,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Tải lên'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_evidences.isEmpty)
                  const Text(
                    'Chưa có minh chứng.',
                    style: TextStyle(color: AppTheme.mediumGray),
                  )
                else
                  ..._evidences.map(
                    (e) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.image_outlined),
                        title: Text(e.fileName ?? 'Ảnh #${e.id}'),
                        subtitle: Text(
                          [
                            if (e.note != null && e.note!.isNotEmpty) e.note!,
                            if (e.capturedAt != null)
                              e.capturedAt!.toLocal().toString(),
                          ].join(' · '),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
