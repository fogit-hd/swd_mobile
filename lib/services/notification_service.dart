import 'dart:convert';

import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService(this._client);

  final ApiClient _client;

  Future<AppNotificationList> fetchLatest({int take = 20}) async {
    final response = await _client.get(
      '/api/notifications',
      query: {'take': take.toString()},
    );
    _client.throwIfFailed(response, 'Tải thông báo');

    return AppNotificationList.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> markRead(int notificationId) async {
    final response = await _client.patch(
      '/api/notifications/$notificationId/read',
    );
    _client.throwIfFailed(response, 'Đánh dấu đã đọc');
  }

  Future<int> markAllRead() async {
    final response = await _client.patch('/api/notifications/read-all');
    _client.throwIfFailed(response, 'Đánh dấu tất cả đã đọc');

    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['updated'] is num) {
        return (body['updated'] as num).toInt();
      }
    } catch (_) {}
    return 0;
  }
}
