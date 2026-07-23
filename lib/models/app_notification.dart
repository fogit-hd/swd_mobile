class AppNotificationList {
  const AppNotificationList({
    this.items = const [],
    this.unreadCount = 0,
  });

  factory AppNotificationList.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? const [];
    return AppNotificationList(
      items: itemsRaw
          .map((e) => AppNotificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  final List<AppNotificationItem> items;
  final int unreadCount;
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    this.type,
    this.title,
    this.message,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String?,
      title: json['title'] as String?,
      message: json['message'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }

  final int id;
  final String? type;
  final String? title;
  final String? message;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  AppNotificationItem copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
