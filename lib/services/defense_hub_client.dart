import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../config/api_config.dart';
import '../models/defense.dart';
import 'auth_service.dart';

/// Client SignalR cho hub `/hubs/defense` (chỉ Lecturer).
class DefenseHubClient {
  DefenseHubClient(this._auth);

  final AuthService _auth;
  HubConnection? _connection;

  final _stateController = StreamController<DefenseSessionState>.broadcast();
  final _scoreController = StreamController<SubmittedScore>.broadcast();
  final _evidenceController = StreamController<DefenseEvidence>.broadcast();
  final _memberController = StreamController<String>.broadcast();

  Stream<DefenseSessionState> get onSessionState => _stateController.stream;
  Stream<SubmittedScore> get onScoreSubmitted => _scoreController.stream;
  Stream<DefenseEvidence> get onEvidenceCaptured => _evidenceController.stream;
  Stream<String> get onMemberJoined => _memberController.stream;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connectAndJoin(int sessionId) async {
    if (_auth.isDemoMode) return;
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) return;

    await disconnect();

    final hubUrl = '${ApiConfig.baseUrl}/hubs/defense';
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

    connection.on('defenseSessionState', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _stateController.add(
          DefenseSessionState.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    });

    connection.on('defenseSessionStarted', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _stateController.add(
          DefenseSessionState.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    });

    connection.on('defenseSessionClosed', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _stateController.add(
          DefenseSessionState.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    });

    connection.on('scoreSubmitted', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _scoreController.add(
          SubmittedScore.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    });

    connection.on('defenseEvidenceCaptured', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        _evidenceController.add(
          DefenseEvidence.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    });

    connection.on('memberJoined', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final name = map['fullName'] ?? map['FullName'] ?? map['code'] ?? 'TV';
        _memberController.add(name.toString());
      }
    });

    await connection.start();
    await connection.invoke('JoinDefenseSession', args: <Object>[sessionId]);
    _connection = connection;
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    try {
      await connection.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _scoreController.close();
    await _evidenceController.close();
    await _memberController.close();
  }
}
