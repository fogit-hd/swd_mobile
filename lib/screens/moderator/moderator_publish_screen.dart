import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/review_scheduling.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/review_context_bar.dart';

class ModeratorPublishScreen extends StatefulWidget {
  const ModeratorPublishScreen({super.key});

  @override
  State<ModeratorPublishScreen> createState() => _ModeratorPublishScreenState();
}

class _ModeratorPublishScreenState extends State<ModeratorPublishScreen> {
  final _subjectController = TextEditingController(text: 'Lịch review tuần này');
  final _messageController = TextEditingController(
    text: 'Lịch review đã được công bố. Vui lòng kiểm tra trên hệ thống.',
  );

  ReviewContext? _context;
  bool _publishing = false;
  bool _exporting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() => _publishing = true);
    try {
      final auth = AuthScope.of(context);
      final result = await ReviewService(ApiClient(auth)).publishSchedule(
        PublishReviewScheduleRequest(
          semesterId: ctx.semester.id,
          reviewType: ctx.reviewType.apiValue,
          weekStart: ctx.weekStart,
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã công bố ${result.publishedSessionCount} phiên. '
            'Email: ${result.sentEmailCount}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _exportZip() async {
    final ctx = _context;
    if (ctx == null) return;

    setState(() => _exporting = true);
    try {
      final auth = AuthScope.of(context);
      final bytes = await ReviewService(ApiClient(auth)).exportSubmissionsZip(
        semesterId: ctx.semester.id,
        reviewType: ctx.reviewType.apiValue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tải export.zip (${bytes.length} bytes)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReviewContextBar(
          onChanged: (ctx) => setState(() => _context = ctx),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Công bố lịch review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'POST /api/review-schedules/publish',
                style: TextStyle(color: AppTheme.mediumGray, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Tiêu đề email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Nội dung thông báo'),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _publishing || _context == null ? null : _publish,
                  child: _publishing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Công bố lịch'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _exporting || _context == null ? null : _exportZip,
                  child: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Export ZIP submissions'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
