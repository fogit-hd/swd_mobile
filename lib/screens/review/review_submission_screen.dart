import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_enums.dart';
import '../../models/review_submission.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loading.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  const ReviewSubmissionScreen({
    super.key,
    required this.submissionId,
    required this.sessionTitle,
  });

  final int submissionId;
  final String sessionTitle;

  @override
  State<ReviewSubmissionScreen> createState() =>
      _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  ReviewSubmission? _submission;
  bool _loading = true;
  bool _saving = false;
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
      final submission = await ReviewService(ApiClient(auth))
          .fetchSubmission(widget.submissionId);
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
    _effortController.text =
        submission.effortHours?.toString() ?? '';

    for (final item in submission.items) {
      if (item.itemKey != null && !item.isSection) {
        _itemCommentControllers[item.itemKey!] =
            TextEditingController(text: item.comment ?? '');
      }
    }
  }

  ReviewSubmission _buildDraft() {
    final submission = _submission!;
    final items = submission.items.map((item) {
      if (item.isSection || item.itemKey == null) return item;
      return item.copyWith(
        comment: _itemCommentControllers[item.itemKey!]?.text.trim(),
      );
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
      final updated = await ReviewService(ApiClient(auth)).saveDraft(
        widget.submissionId,
        _buildDraft(),
      );
      if (!mounted) return;
      _bindSubmission(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu nháp')),
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
    setState(() => _saving = true);
    try {
      final auth = AuthScope.of(context);
      final service = ReviewService(ApiClient(auth));
      await service.saveDraft(widget.submissionId, _buildDraft());
      await service.submitReview(widget.submissionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi nhận xét review')),
      );
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
    final submission = _submission!;
    final items = [...submission.items];
    items[index] = items[index].copyWith(answer: answer);
    setState(() => _submission = submission.copyWith(items: items));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sessionTitle)),
        body: const AppLoadingIndicator(message: 'Đang tải checklist...'),
      );
    }

    if (_error != null || _submission == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.sessionTitle)),
        body: Center(child: Text(_error ?? 'Không tải được form review')),
      );
    }

    final submission = _submission!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${widget.sessionTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Excel',
            onPressed: _saving
                ? null
                : () async {
                    try {
                      final auth = AuthScope.of(context);
                      final bytes = await ReviewService(ApiClient(auth))
                          .exportSubmissionXlsx(widget.submissionId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã tải export.xlsx (${bytes.length} bytes)',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
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
                  'Nhập nhận xét theo checklist. Không có điểm số hay PASS/FAIL.',
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
                ),
                _TextField(
                  label: 'Effort (giờ)',
                  controller: _effortController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Checklist',
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
                        item.label ?? item.itemKey ?? 'Mục',
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
                            item.label ?? item.itemKey ?? 'Tiêu chí',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description!,
                              style: const TextStyle(
                                color: AppTheme.mediumGray,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: ReviewChecklistAnswer.values.map((answer) {
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
                _TextField(
                  label: 'Nhận xét chung',
                  controller: _reviewerCommentController,
                  maxLines: 4,
                ),
                _TextField(
                  label: 'Gợi ý cải thiện',
                  controller: _suggestionController,
                  maxLines: 3,
                ),
                _TextField(
                  label: 'Kết quả (nhập tay nếu cần)',
                  controller: _resultTextController,
                  maxLines: 2,
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
                          : const Text('Gửi review'),
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
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
