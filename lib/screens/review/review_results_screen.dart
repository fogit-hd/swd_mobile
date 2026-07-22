import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../app/auth_scope.dart';
import '../../models/review_submission.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/checklist_labels.dart';
import '../../widgets/app_loading.dart';

class ReviewResultsScreen extends StatefulWidget {
  const ReviewResultsScreen({super.key, required this.submissionId});

  final int submissionId;

  @override
  State<ReviewResultsScreen> createState() => _ReviewResultsScreenState();
}

class _ReviewResultsScreenState extends State<ReviewResultsScreen> {
  ReviewSubmission? _submission;
  bool _loading = true;
  String? _error;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = AuthScope.of(context);
      final submission = await ReviewService(ApiClient(auth))
          .fetchSubmission(widget.submissionId);
      if (!mounted) return;
      setState(() {
        _submission = submission;
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

  Future<void> _exportXlsx() async {
    try {
      final auth = AuthScope.of(context);
      final file = await ReviewService(ApiClient(auth))
          .exportSubmissionXlsxToFile(widget.submissionId);
      final sizeKb = (await file.length() / 1024).toStringAsFixed(0);
      if (!mounted) return;
      await OpenFilex.open(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xuất checklist Excel ($sizeKb KB). '
            'Đây không phải tài liệu đồ án của nhóm.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_view_outlined),
            tooltip: 'Xuất checklist Excel',
            onPressed: _exportXlsx,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoadingIndicator(message: 'Đang tải kết quả...');
    }

    final submission = _submission;
    if (_error != null || submission == null) {
      return Center(child: Text(_error ?? 'Không tải được kết quả'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          submission.projectName ?? submission.groupCode ?? 'Nhóm',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Người chấm: ${submission.reviewerName ?? submission.reviewerCode ?? '—'}',
          style: const TextStyle(color: AppTheme.mediumGray),
        ),
        const SizedBox(height: 16),
        if (!submission.isSubmitted)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Bài chấm chưa được gửi. Chỉ xem được sau khi đã nộp nhận xét.',
                style: TextStyle(color: AppTheme.mediumGray),
              ),
            ),
          ),
        ...submission.items.map((item) {
          if (item.isSection) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                ChecklistLabels.localize(item.label ?? 'Mục'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            );
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
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
                      ChecklistLabels.localize(item.description!),
                      style: const TextStyle(
                        color: AppTheme.mediumGray,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text('Trả lời: ${item.answer?.label ?? '—'}'),
                  if (item.comment != null && item.comment!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Nhận xét: ${item.comment}'),
                    ),
                ],
              ),
            ),
          );
        }),
        const Divider(height: 32),
        _InfoBlock(title: 'Nhận xét chung', value: submission.reviewerComment),
        _InfoBlock(title: 'Gợi ý', value: submission.suggestion),
        _InfoBlock(title: 'Kết quả', value: submission.resultText),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value!),
        ],
      ),
    );
  }
}
