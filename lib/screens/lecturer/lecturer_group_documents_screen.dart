import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../app/auth_scope.dart';
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
    if (auth.isDemoMode) {
      setState(() {
        _docs = const [];
        _loading = false;
        _error = 'Chế độ demo — chưa có dữ liệu tài liệu thật.';
      });
      return;
    }

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
    if (auth.isDemoMode) return;

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
    if (auth.isDemoMode) return;

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
                  if (cachedAi != null) ...[
                    const SizedBox(height: 10),
                    AiSuggestionPopover(suggestion: cachedAi),
                  ],
                  const SizedBox(height: 8),
                  Row(
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
                      const SizedBox(width: 4),
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
}
