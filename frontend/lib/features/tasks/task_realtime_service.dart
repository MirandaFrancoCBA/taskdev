import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';

class TaskRealtimeService {
  TaskRealtimeService({required this.teamId, required this.accessTokenProvider, required this.onTaskEvent});
  final int teamId;
  final String? Function() accessTokenProvider;
  final Future<void> Function() onTaskEvent;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _attempt = 0;

  void connect() {
    if (_disposed) return;
    final accessToken = accessTokenProvider();
    if (accessToken == null) return;
    final uri = AppConfig.websocketUri(teamId, accessToken);
    try {
      _channel = WebSocketChannel.connect(uri);
      _subscription = _channel!.stream.listen(_handleMessage, onError: (_) => _scheduleReconnect(), onDone: _scheduleReconnect);
      _attempt = 0;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'];
      if (type == 'task.created' || type == 'task.claimed' || type == 'task.updated') {
        onTaskEvent();
      }
    } catch (_) {
      // Ignore malformed realtime messages; REST state remains authoritative.
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer?.isActive == true) return;
    _subscription?.cancel();
    _channel = null;
    final seconds = [1, 2, 5, 10, 20][_attempt.clamp(0, 4)];
    _attempt++;
    _reconnectTimer = Timer(Duration(seconds: seconds), connect);
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
  }
}
