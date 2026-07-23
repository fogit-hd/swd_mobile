import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/auth_scope.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';

/// Dialog nhập mã 8 ký tự để mở phiên review đã được PĐT khóa bằng access-code.
///
/// Grant mã là theo từng giảng viên trên BE. Nếu đã verify trên web, mobile
/// sẽ hỏi lại BE trước khi hiện dialog để đồng bộ trạng thái.
Future<bool> ensureReviewSessionAccess({
  required BuildContext context,
  required int sessionId,
  required bool hasAccessCode,
  required bool isAccessVerified,
  String? sessionTitle,
}) async {
  if (!hasAccessCode || isAccessVerified) return true;

  final auth = AuthScope.of(context);
  final service = ReviewService(ApiClient(auth));

  // Đồng bộ với web / thiết bị khác trước khi hỏi mã.
  try {
    final latest = await service.fetchSessionAccessStatus(sessionId);
    if (!context.mounted) return false;
    if (latest != null && (!latest.hasAccessCode || latest.isAccessVerified)) {
      return true;
    }
  } catch (_) {
    // Vẫn cho nhập mã nếu refresh trạng thái lỗi tạm thời.
  }

  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AccessCodeDialog(
      sessionId: sessionId,
      sessionTitle: sessionTitle,
      auth: auth,
    ),
  );

  return ok == true;
}

class _AccessCodeDialog extends StatefulWidget {
  const _AccessCodeDialog({
    required this.sessionId,
    required this.auth,
    this.sessionTitle,
  });

  final int sessionId;
  final AuthService auth;
  final String? sessionTitle;

  @override
  State<_AccessCodeDialog> createState() => _AccessCodeDialogState();
}

class _AccessCodeDialogState extends State<_AccessCodeDialog> {
  final _controller = TextEditingController();
  var _verifying = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 8) {
      setState(() => _error = 'Mã truy cập phải đủ 8 ký tự.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await ReviewService(ApiClient(widget.auth)).verifySessionAccessCode(
        sessionId: widget.sessionId,
        accessCode: code,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sessionTitle;
    return AlertDialog(
      title: const Text('Mã truy cập buổi review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title == null || title.trim().isEmpty
                ? 'Nhập mã do Phòng Đào tạo cung cấp để mở buổi này.'
                : 'Nhập mã để mở «$title».',
            style: const TextStyle(
              color: AppTheme.mediumGray,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_verifying,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            decoration: InputDecoration(
              labelText: 'Mã truy cập',
              hintText: 'VD: AB12CD34',
              errorText: _error,
              errorMaxLines: 4,
              counterText: '',
            ),
            onSubmitted: _verifying ? null : (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verifying ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _verifying ? null : _submit,
          child: _verifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}
