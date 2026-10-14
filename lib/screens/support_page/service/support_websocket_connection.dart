import 'dart:async';
import 'dart:io';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

/// Keeps the HTTP inspector's response buffering away from socket upgrades.
/// REST requests still use the global inspector; TLS and any pre-existing
/// HTTP client configuration are preserved for every socket reconnect.
class SupportWebSocketConnection implements PusherChannelsConnection {
  SupportWebSocketConnection({required this.uri, this.onDiagnostic});

  final Uri uri;
  final void Function(String message)? onDiagnostic;
  HttpClient? _httpClient;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  static HttpOverrides? _beforeInspector;

  /// Call immediately before installing the app's global HTTP inspector.
  static void captureHttpOverridesBeforeInspector() {
    _beforeInspector = HttpOverrides.current ?? _DefaultSocketHttpOverrides();
  }

  @override
  void connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  }) async {
    try {
      // dart:io's shared WebSocket client may already have been initialized
      // with the global inspector. An explicit client avoids that cached one.
      _httpClient = _beforeInspector?.createHttpClient(null) ?? HttpClient();
      onDiagnostic?.call(
        'socket opening ${uri.scheme}://${uri.host}:${uri.port}; '
        'inspector bypass=${_beforeInspector != null}',
      );
      final socket = await WebSocket.connect(
        uri.toString(),
        customClient: _httpClient,
      );
      if (_closed) {
        unawaited(socket.close());
        return;
      }
      _socket = socket;
      onDiagnostic?.call('WebSocket upgrade succeeded');
      _subscription = socket.listen(
        (event) => onEventCallback(event.toString()),
        onDone: () {
          if (_closed) return;
          onDiagnostic?.call(
            'socket closed code=${socket.closeCode} '
            'reason=${_safeDetail(socket.closeReason ?? 'not supplied')}',
          );
          onDoneCallback();
        },
        onError: (Object error, StackTrace trace) {
          if (_closed) return;
          onDiagnostic?.call('socket error: ${_safeDetail(error)}');
          onErrorCallback(error, trace);
        },
        cancelOnError: true,
      );
    } catch (error, trace) {
      if (_closed) return;
      onDiagnostic?.call('socket handshake failed: ${_safeDetail(error)}');
      onErrorCallback(error, trace);
    }
  }

  String _safeDetail(Object value) => value.toString().replaceAll(
        uri.path,
        '/app/[redacted]',
      );

  @override
  void sendEvent(String eventEncoded) {
    if (!_closed) _socket?.add(eventEncoded);
  }

  @override
  void ping() => sendEvent('{"event":"pusher:ping","data":{}}');

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    unawaited(_socket?.close());
    _httpClient?.close(force: true);
  }
}

class _DefaultSocketHttpOverrides extends HttpOverrides {}
