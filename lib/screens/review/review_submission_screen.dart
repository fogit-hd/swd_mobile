import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../app/auth_scope.dart';
import '../../models/review_enums.dart';
import '../../models/review_submission.dart';
import '../../services/ai_suggestion_service.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/checklist_labels.dart';
import '../../widgets/app_loading.dart';
import '../lecturer/lecturer_group_documents_screen.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  const ReviewSubmissionScreen({
    super.key,
    required this.submissionId,
    required this.sessionTitle,
  });

  final int submissionId;
  final String sessionTitle;

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  ReviewSubmission? _submission;
  bool _loading = true;
  bool _saving = false;
  bool _aiLoading = false;
  bool _commentExpanded = true;
  bool _suggestionExpanded = true;
  String? _error;

  final _reviewerCommentController = TextEditingController();
  final _suggestionController = TextEditingController();
  final _resultTextController = TextEditingController();
  final _workVersionController = TextEditingController();
  final _workSizeController = TextEditingController();
  final _effortController = TextEditingController();
  final Map<String, TextEditingController> _itemCommentControllers = {};

  @override
  void dispose() {
    _reviewerCommentController.dispose();
    _suggestionController.dispose();
    _resultTextController.dispose();
    _workVersionController.dispose();
    _workSizeController.dispose();
    _effortController.dispose();
    for (final controller in _itemCommentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final auth = AuthScope.of(context);
      final submission = await ReviewService(
        ApiClient(auth),
      ).fetchSubmission(widget.submissionId);
      if (!mounted) return;
      _bindSubmission(submission);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _bindSubmission(ReviewSubmission submission) {
    for (final controller in _itemCommentControllers.values) {
      controller.dispose();
    }
    _itemCommentControllers.clear();

    _submission = submission;
    _reviewerCommentController.text = submission.reviewerComment ?? '';
    _suggestionController.text = submission.suggestion ?? '';
    _resultTextController.text = submission.resultText ?? '';
    _workVersionController.text = submission.workProductVersion ?? '';
    _workSizeController.text = submission.workProductSize ?? '';
    _effortController.text = submission.effortHours?.toString() ?? '';

    for (final item in submission.items) {
      final key = item.itemKey;
      if (key != null && !item.isSection) {
        _itemCommentControllers[key] = TextEditingController(
          text: item.comment ?? '',
        );
      }
    }
  }

  ReviewSubmission _buildDraft() {
    final submission = _submission;
    if (submission == null) {
      throw StateError('Submission chưa được tải');
    }
    final items = submission.items.map((item) {
      final key = item.itemKey;
      if (item.isSection || key == null) return item;
      return item.copyWith(comment: _itemCommentControllers[key]?.text.trim());
    }).toList();

    return submission.copyWith(
      workProductVersion: _workVersionController.text.trim(),
      workProductSize: _workSizeController.text.trim(),
      effortHours: double.tryParse(_effortController.text.trim()),
      reviewerComment: _reviewerCommentController.text.trim(),
      suggestion: _suggestionController.text.trim(),
      resultText: _resultTextController.text.trim(),
      items: items,
    );
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      final updated = await ReviewService(
        ApiClient(auth),
      ).saveDraft(widget.submissionId, _buildDraft());
      if (!mounted) return;
      _bindSubmission(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu nháp')));
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
    final draft = _buildDraft();
    final unansweredCount = draft.items
        .where((item) => !item.isSection && item.answer == null)
        .length;
    if (unansweredCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng trả lời đủ checklist ($unansweredCount mục chưa chọn).',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (draft.reviewerComment?.trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nhận xét chung trước khi gửi.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      final service = ReviewService(ApiClient(auth));
      await service.saveDraft(widget.submissionId, draft);
      await service.submitReview(widget.submissionId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi nhận xét review')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setAnswer(int index, ReviewChecklistAnswer answer) {
    final submission = _submission;
    if (submission == null) return;
    final items = [...submission.items];
    items[index] = items[index].copyWith(answer: answer);
    setState(() => _submission = submission.copyWith(items: items));
  }

  /// Điền nhận xét / gợi ý từ POST /api/project-suggestions/summary.
  Future<void> _applyAiSuggestion() async {
    final submission = _submission;
    if (submission == null || _aiLoading || _saving) return;

    setState(() => _aiLoading = true);
    try {
      final auth = AuthScope.of(context);
      final draft = _buildDraft();
      final ai = await AiSuggestionService(
        ApiClient(auth),
      ).generateFromSubmission(draft, fallbackProjectName: widget.sessionTitle);
      if (!mounted) return;
      if (ai == null || ai.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa nhận được gợi ý AI. Thử lại sau.'),
          ),
        );
        return;
      }

      final commentParts = <String>[
        if (ai.contentSummary.isNotEmpty) ai.contentSummary,
        if (ai.strengthsSummary.isNotEmpty) 'Điểm mạnh: ${ai.strengthsSummary}',
      ];
      if (commentParts.isNotEmpty) {
        _reviewerCommentController.text = commentParts.join('\n\n');
      }
      if (ai.improvementSummary.isNotEmpty) {
        _suggestionController.text = ai.improvementSummary;
      }
      setState(() {
        _commentExpanded = true;
        _suggestionExpanded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã điền gợi ý AI vào form')),
      );
    } on AiSuggestionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? ApiClient.localizeMessage(e.message)
                : 'Không tạo được gợi ý AI. Thử lại sau.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sessionTitle)),
        body: const AppLoadingIndicator(message: 'Đang tải tiêu chí review...'),
      );
    }

    final submission = _submission;
    if (_error != null || submission == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sessionTitle)),
        body: Center(child: Text(_error ?? 'Không tải được form review')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Nhận xét review · ${widget.sessionTitle}'),
        actions: [
          if (submission.groupId > 0)
            IconButton(
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: 'Tài liệu nhóm',
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LecturerGroupDocumentsScreen(
                      groupId: submission.groupId,
                      groupCode: submission.groupCode ?? submission.projectName,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: _aiLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            tooltip: 'Gợi ý AI',
            onPressed: (_saving || _aiLoading) ? null : _applyAiSuggestion,
          ),
          IconButton(
            icon: const Icon(Icons.table_view_outlined),
            tooltip: 'Xuất checklist Excel',
            onPressed: _saving
                ? null
                : () async {
                    try {
                      final auth = AuthScope.of(context);
                      final file = await ReviewService(
                        ApiClient(auth),
                      ).exportSubmissionXlsxToFile(widget.submissionId);
                      final sizeKb = (await file.length() / 1024)
                          .toStringAsFixed(0);
                      if (!mounted) return;
                      await OpenFilex.open(file.path);
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã xuất checklist Excel ($sizeKb KB). '
                            'Đây không phải tài liệu đồ án của nhóm.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  submission.projectName ?? widget.sessionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập nhận xét theo danh sách tiêu chí. Không chấm điểm số hay đạt/không đạt.',
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
                ),
                const Divider(height: 32),
                _TextField(
                  label: 'Phiên bản sản phẩm',
                  controller: _workVersionController,
                ),
                _TextField(
                  label: 'Quy mô sản phẩm',
                  controller: _workSizeController,
                  helperText:
                      'Do giảng viên ghi nhận (vd. 4.5 MB, 45 trang) — không tự lấy từ file tài liệu',
                ),
                _TextField(
                  label: 'Thời gian thực hiện (giờ)',
                  controller: _effortController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Danh sách tiêu chí',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...submission.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  if (item.isSection) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        ChecklistLabels.localize(
                          item.label ?? item.itemKey ?? 'Mục',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  }

                  final commentController = _itemCommentControllers.putIfAbsent(
                    item.itemKey ?? 'item-$index',
                    () => TextEditingController(text: item.comment ?? ''),
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ChecklistLabels.localize(
                              item.label ?? item.itemKey ?? 'Tiêu chí',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if ((item.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              ChecklistLabels.localize(item.description ?? ''),
                              style: const TextStyle(
                                color: AppTheme.mediumGray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: ReviewChecklistAnswer.values.map((
                              answer,
                            ) {
                              final selected = item.answer == answer;
                              return ChoiceChip(
                                label: Text(answer.label),
                                selected: selected,
                                onSelected: (_) => _setAnswer(index, answer),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              labelText: 'Nhận xét',
                              hintText: 'Ghi chú cho tiêu chí này',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 32),
                // ── Phần AI gợi ý ──────────────────────────────────────
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Gợi ý từ AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: (_saving || _aiLoading)
                          ? null
                          : _applyAiSuggestion,
                      icon: _aiLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_aiLoading ? 'Đang tạo...' : 'AI gợi ý'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nội dung AI điền vào đây — có thể chỉnh trước khi gửi.',
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.statusActiveBg.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _AiSuggestionFrame(
                        title: 'Nhận xét chung',
                        controller: _reviewerCommentController,
                        expanded: _commentExpanded,
                        loading: _aiLoading,
                        emptyHint:
                            'Chưa có gợi ý. Nhấn «AI gợi ý» để tạo nhận xét.',
                        onToggleExpand: () => setState(
                          () => _commentExpanded = !_commentExpanded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AiSuggestionFrame(
                        title: 'Gợi ý cải thiện',
                        controller: _suggestionController,
                        expanded: _suggestionExpanded,
                        loading: _aiLoading,
                        emptyHint:
                            'Chưa có gợi ý. Nhấn «AI gợi ý» để tạo hướng cải thiện.',
                        onToggleExpand: () => setState(
                          () => _suggestionExpanded = !_suggestionExpanded,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── Phần giảng viên nhập ───────────────────────────────
                const Text(
                  'Nhập của giảng viên',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ghi chú kết luận của giảng viên sau buổi review, không phải điểm số.',
                  style: TextStyle(color: AppTheme.mediumGray, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _TextField(
                  label: 'Ghi nhận cuối buổi (không bắt buộc)',
                  controller: _resultTextController,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.lightGray)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _saveDraft,
                      child: const Text('Lưu nháp'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Gửi nhận xét'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.helperText,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
        ),
      ),
    );
  }
}

/// Khung AI: cùng layout khi trống / đang tạo / đã có kết quả.
/// Mỗi khung có nút thu gọn / mở rộng riêng.
class _AiSuggestionFrame extends StatelessWidget {
  const _AiSuggestionFrame({
    required this.title,
    required this.controller,
    required this.expanded,
    required this.loading,
    required this.emptyHint,
    required this.onToggleExpand,
  });

  final String title;
  final TextEditingController controller;
  final bool expanded;
  final bool loading;
  final String emptyHint;
  final VoidCallback onToggleExpand;

  static const int _collapsedLines = 3;
  static const int _emptyMinLines = 4;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.lightGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (hasText || loading)
                      TextButton.icon(
                        onPressed: loading ? null : onToggleExpand,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: Icon(
                          expanded ? Icons.unfold_less : Icons.unfold_more,
                          size: 18,
                        ),
                        label: Text(
                          expanded ? 'Thu gọn' : 'Mở rộng',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: loading && !hasText
                      ? const _LoadingPlaceholder(minLines: _emptyMinLines)
                      : TextField(
                          controller: controller,
                          minLines: expanded
                              ? (hasText ? _collapsedLines : _emptyMinLines)
                              : _collapsedLines,
                          maxLines: expanded ? null : _collapsedLines,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: InputDecoration(
                            hintText: emptyHint,
                            hintMaxLines: 3,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.minLines});

  final int minLines;

  @override
  Widget build(BuildContext context) {
    // Giữ chiều cao tương đương khung khi đã có kết quả (đồng bộ layout).
    return SizedBox(
      height: 20.0 * minLines,
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đang tạo gợi ý AI...',
                style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
