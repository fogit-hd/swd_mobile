import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../app/auth_scope.dart';
import '../../models/document_inline_comment.dart';
import '../../models/project_document.dart';
import '../../models/project_suggestion.dart';
import '../../services/api_client.dart';
import '../../services/document_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/ui/ai_suggestion_popover.dart';

/// Màn Giảng viên: xem / tải / AI phân tích tài liệu nhóm.
/// Không có upload (API upload chỉ dành Student).
class LecturerGroupDocumentsScreen extends StatefulWidget {
  const LecturerGroupDocumentsScreen({
    super.key,
    required this.groupId,
    this.groupCode,
  });

  final int groupId;
  final String? groupCode;

  @override
  State<LecturerGroupDocumentsScreen> createState() =>
      _LecturerGroupDocumentsScreenState();
}

class _LecturerGroupDocumentsScreenState
    extends State<LecturerGroupDocumentsScreen> {
  List<ProjectDocument> _docs = const [];
  bool _loading = true;
  String? _error;
  int? _downloadingId;
  int? _analyzingId;
  final Map<int, ProjectSuggestion> _aiByDoc = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await DocumentService(ApiClient(auth)).listByGroup(
        widget.groupId,
      );
      if (!mounted) return;
      setState(() {
        _docs = docs;
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

  Future<void> _download(ProjectDocument doc) async {
    final auth = AuthScope.of(context);

    setState(() => _downloadingId = doc.id);
    try {
      final file = await DocumentService(ApiClient(auth)).downloadToTemp(doc);
      if (!mounted) return;
      final result = await OpenFilex.open(file.path);
      if (!mounted) return;
      final message = result.type == ResultType.done
          ? 'Đã mở ${doc.title}'
          : 'Đã tải ${doc.title} (${doc.sizeLabel}). '
              '${result.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _analyze(ProjectDocument doc) async {
    if (!doc.canAnalyzeWithAi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'AI chỉ phân tích PDF, DOCX hoặc TXT. File ZIP cần giải nén trước.',
          ),
        ),
      );
      return;
    }

    final auth = AuthScope.of(context);

    setState(() => _analyzingId = doc.id);
    try {
      final suggestion = await DocumentService(ApiClient(auth)).analyzeWithAi(
        doc.id,
      );
      if (!mounted) return;
      setState(() => _aiByDoc[doc.id] = suggestion);
      await _showAiSheet(doc, suggestion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _analyzingId = null);
    }
  }

  Future<void> _showAiSheet(
    ProjectDocument doc,
    ProjectSuggestion suggestion,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    'AI phân tích · ${doc.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.docTypeLabel} · ${doc.versionLabel}',
                    style: const TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AiSuggestionPopover(suggestion: suggestion, initiallyExpanded: true),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: suggestion.displayText),
                      );
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép gợi ý AI'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Sao chép toàn bộ'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gợi ý chỉ mang tính tham khảo — hãy tự kiểm tra rồi '
                    'đưa vào nhận xét chính thức nếu phù hợp.',
                    style: TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.groupCode?.trim().isNotEmpty == true
        ? 'Tài liệu · ${widget.groupCode}'
        : 'Tài liệu nhóm #${widget.groupId}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingIndicator(message: 'Đang tải tài liệu nhóm...');
    }

    if (_error != null && _docs.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Không tải được tài liệu',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.darkGray),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (_docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Text(
            'Nhóm chưa nộp tài liệu nào, hoặc bạn không được phân công xem nhóm này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mediumGray),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: AppSpacing.pagePadding,
        itemCount: _docs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final doc = _docs[index];
          final analyzing = _analyzingId == doc.id;
          final downloading = _downloadingId == doc.id;
          final cachedAi = _aiByDoc[doc.id];

          return Card(
            elevation: 0,
            color: AppTheme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.lightGray),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${doc.docTypeLabel} · ${doc.versionLabel} · ${doc.sizeLabel}',
                    style: const TextStyle(
                      color: AppTheme.mediumGray,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Trạng thái: ${doc.statusLabel}',
                    style: const TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 12,
                    ),
                  ),
                  if (doc.uploadedByName?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Người nộp: ${doc.uploadedByName}',
                      style: const TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (cachedAi != null) ...[
                    const SizedBox(height: 10),
                    AiSuggestionPopover(suggestion: cachedAi),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: downloading ? null : () => _download(doc),
                        icon: downloading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_outlined, size: 18),
                        label: Text(downloading ? 'Đang tải...' : 'Tải xuống'),
                      ),
                      TextButton.icon(
                        onPressed: analyzing ? null : () => _analyze(doc),
                        icon: analyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          analyzing ? 'Đang phân tích...' : 'AI phân tích',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openComments(doc),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Bình luận'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openComments(ProjectDocument doc) async {
    final auth = AuthScope.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _DocumentCommentsSheet(
        document: doc,
        service: DocumentService(ApiClient(auth)),
      ),
    );
  }
}

class _DocumentCommentsSheet extends StatefulWidget {
  const _DocumentCommentsSheet({
    required this.document,
    required this.service,
  });

  final ProjectDocument document;
  final DocumentService service;

  @override
  State<_DocumentCommentsSheet> createState() => _DocumentCommentsSheetState();
}

class _DocumentCommentsSheetState extends State<_DocumentCommentsSheet> {
  final _contentController = TextEditingController();
  final _referenceController = TextEditingController();
  List<DocumentInlineComment> _comments = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await widget.service.listComments(widget.document.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
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

  Future<void> _add() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    setState(() => _saving = true);
    try {
      final created = await widget.service.addComment(
        documentId: widget.document.id,
        content: content,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _comments = [created, ..._comments];
        _contentController.clear();
        _referenceController.clear();
        _saving = false;
      });
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
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Bình luận · ${widget.document.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nội dung bình luận',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Tham chiếu đoạn (tuỳ chọn)',
                hintText: 'VD: mục 3.2 / trang 12',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _add,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined, size: 18),
                label: const Text('Thêm bình luận'),
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: _loading
                  ? const AppLoadingIndicator(message: 'Đang tải bình luận...')
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Chưa có bình luận.',
                                style: TextStyle(color: AppTheme.mediumGray),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _comments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final c = _comments[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      c.authorName ?? 'Giảng viên',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                        c.content,
                                        if (c.reference?.trim().isNotEmpty ==
                                            true)
                                          'Tham chiếu: ${c.reference}',
                                        if (c.createdAt != null)
                                          c.createdAt!.toLocal().toString(),
                                      ].join('\n'),
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
