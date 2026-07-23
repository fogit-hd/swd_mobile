import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../config/api_config.dart';
import '../models/review_attendance.dart';
import 'auth_service.dart';

/// Client SignalR cho hub `/hubs/review-progress`.
class ReviewProgressHubClient {
  ReviewProgressHubClient(this._auth);

  final AuthService _auth;
  HubConnection? _connection;
  int? _joinedSessionId;
  int? _joinedGroupId;

  final _commentController = StreamController<ReviewComment>.broadcast();

  Stream<ReviewComment> get onCommentAdded => _commentController.stream;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connectAndJoin({
    required int sessionId,
    required int groupId,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) return;

    await disconnect();

    final hubUrl = '${ApiConfig.baseUrl}/hubs/review-progress';
    final connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('reviewProgressCommentAdded', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _commentController.add(
          ReviewComment.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    });

    await connection.start();
    await connection.invoke(
      'JoinReviewProgress',
      args: <Object>[sessionId, groupId],
    );
    _connection = connection;
    _joinedSessionId = sessionId;
    _joinedGroupId = groupId;
  }

  Future<void> disconnect() async {
    final connection = _connection;
    final sessionId = _joinedSessionId;
    final groupId = _joinedGroupId;
    _connection = null;
    _joinedSessionId = null;
    _joinedGroupId = null;
    if (connection == null) return;
    try {
      if (sessionId != null && groupId != null) {
        await connection.invoke(
          'LeaveReviewProgress',
          args: <Object>[sessionId, groupId],
        );
      }
    } catch (_) {}
    try {
      await connection.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await disconnect();
    await _commentController.close();
  }
}
