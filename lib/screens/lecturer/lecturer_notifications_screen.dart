import 'package:flutter/material.dart';

import '../../app/auth_scope.dart';
import '../../models/app_notification.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/display_labels.dart';
import '../../widgets/app_loading.dart';

class LecturerNotificationsScreen extends StatefulWidget {
  const LecturerNotificationsScreen({super.key});

  @override
  State<LecturerNotificationsScreen> createState() =>
      _LecturerNotificationsScreenState();
}

class _LecturerNotificationsScreenState
    extends State<LecturerNotificationsScreen> {
  AppNotificationList? _data;
  bool _loading = true;
  bool _busy = false;
  String? _error;

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
      final data = await NotificationService(ApiClient(auth)).fetchLatest();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  Future<void> _markRead(AppNotificationItem item) async {
    if (item.isRead) return;
    final auth = AuthScope.of(context);
    setState(() => _busy = true);
    try {
      await NotificationService(ApiClient(auth)).markRead(item.id);
      if (!mounted) return;
      final current = _data;
      if (current == null) return;
      setState(() {
        _data = AppNotificationList(
          items: current.items
              .map(
                (n) => n.id == item.id
                    ? n.copyWith(isRead: true, readAt: DateTime.now())
                    : n,
              )
              .toList(),
          unreadCount: (current.unreadCount - 1).clamp(0, 9999),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markAllRead() async {
    final auth = AuthScope.of(context);
    setState(() => _busy = true);
    try {
      await NotificationService(ApiClient(auth)).markAllRead();
      if (!mounted) return;
      final current = _data;
      if (current == null) return;
      setState(() {
        _data = AppNotificationList(
          items: current.items
              .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
              .toList(),
          unreadCount: 0,
        );
      });
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
    final unread = _data?.unreadCount ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _busy ? null : _markAllRead,
              child: const Text('Đọc tất cả'),
            ),
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
      return const AppLoadingIndicator(message: 'Đang tải thông báo...');
    }

    if (_error != null && (_data == null || _data!.items.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    final items = _data?.items ?? const <AppNotificationItem>[];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có thông báo.',
          style: TextStyle(color: AppTheme.mediumGray),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            color: item.isRead ? AppTheme.white : const Color(0xFFEFF6FF),
            child: ListTile(
              onTap: _busy ? null : () => _markRead(item),
              leading: Icon(
                item.isRead
                    ? Icons.notifications_none_outlined
                    : Icons.notifications_active_outlined,
                color: item.isRead ? AppTheme.mediumGray : AppTheme.primary,
              ),
              title: Text(
                item.title?.trim().isNotEmpty == true
                    ? item.title!
                    : DisplayLabels.notificationType(item.type),
                style: TextStyle(
                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
              subtitle: Text(
                [
                  if (item.message?.trim().isNotEmpty == true) item.message!,
                  if (item.createdAt != null)
                    item.createdAt!.toLocal().toString(),
                ].join('\n'),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
