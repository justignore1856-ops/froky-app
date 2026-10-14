import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter_http_inspector/flutter_http_inspector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/service/support_websocket_connection.dart';

void main() {
  test('sockets and reconnects bypass inspector while REST stays inspected',
      () async {
    final previousOverrides = HttpOverrides.current;
    final originalClient = _CountingHttpOverrides();
    HttpOverrides.global = originalClient;
    SupportWebSocketConnection.captureHttpOverridesBeforeInspector();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    server.listen((request) async {
      if (request.uri.path == '/health') {
        request.response.write('ok');
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.add(jsonEncode({
        'event': 'pusher:connection_established',
        'data': jsonEncode({'socket_id': '1.2', 'activity_timeout': 120}),
      }));
    });
    InspectorStore().clearAll();
    HttpInspector.setup();
    final diagnostics = <String>[];
    final client = PusherChannelsClient.custom(
      connectionDelegate: () => SupportWebSocketConnection(
        uri: Uri.parse('ws://127.0.0.1:${server.port}/app/test'),
        onDiagnostic: diagnostics.add,
      ),
      minimumReconnectDelayDuration: const Duration(milliseconds: 10),
      connectionErrorHandler: (error, trace, refresh) {},
    );
    addTearDown(() async {
      client.dispose();
      HttpOverrides.global = previousOverrides;
      InspectorStore().clearAll();
      for (final socket in sockets) {
        unawaited(socket.close());
      }
      await server.close(force: true);
    });
    final established = client.onConnectionEstablished.first;
    unawaited(client.connect());
    await established.timeout(const Duration(seconds: 2));
    final reconnected = client.onConnectionEstablished.first;
    unawaited(sockets.first.close(1001, 'test reconnect'));
    await reconnected.timeout(const Duration(seconds: 2));
    expect(originalClient.created, 2);
    expect(
        diagnostics, contains('socket closed code=1001 reason=test reconnect'));
    expect(InspectorStore().records, isEmpty);

    final http = HttpClient();
    try {
      final request = await http
          .getUrl(Uri.parse('http://127.0.0.1:${server.port}/health'));
      final response = await request.close();
      expect(await utf8.decoder.bind(response).join(), 'ok');
      expect(InspectorStore().records.single.url, endsWith('/health'));
      expect(originalClient.created, 3);
    } finally {
      http.close(force: true);
    }
  });
}

class _CountingHttpOverrides extends HttpOverrides {
  int created = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    created++;
    return super.createHttpClient(context);
  }
}
