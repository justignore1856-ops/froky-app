import 'dart:async';
import 'dart:developer';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import '../../../config/security.dart';
import '../model/support_models.dart';
import 'support_websocket_connection.dart';

class SupportRealtimeEvent {
  const SupportRealtimeEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

class SupportRealtimeService {
  final _events = StreamController<SupportRealtimeEvent>.broadcast();
  final _live = StreamController<bool>.broadcast();

  PusherChannelsClient? _client;
  PrivateChannel? _threadChannel;
  PresenceChannel? _presenceChannel;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _isLive = false;
  PusherChannelsClientLifeCycleState _lifecycleState =
      PusherChannelsClientLifeCycleState.inactive;
  bool _retrying = false;
  bool _clientWhispersEnabled = true;

  Stream<SupportRealtimeEvent> get events => _events.stream;
  Stream<bool> get liveChanges => _live.stream;
  bool get isLive => _isLive;

  Future<void> connect({
    required SupportRealtimeConfig config,
    required String threadUuid,
  }) async {
    await disconnect();
    if (!config.isConfigured || threadUuid.isEmpty) {
      _setLive(false);
      return;
    }

    try {
      final authUri = Uri.tryParse(config.authEndpoint);
      if (authUri == null || !authUri.hasScheme) {
        _debug('invalid auth endpoint: ${config.authEndpoint}');
        _setLive(false);
        return;
      }

      final scheme = config.scheme == 'http' ? 'ws' : 'wss';
      final key = config.key!;
      final PusherChannelsOptions options = config.driver == 'pusher'
          ? PusherChannelsOptions.fromCluster(
              scheme: scheme,
              cluster: config.cluster,
              key: key,
              port: config.port,
            )
          : PusherChannelsOptions.fromHost(
              scheme: scheme,
              host: config.host!,
              key: key,
              port: config.port,
            );

      final client = PusherChannelsClient.custom(
        connectionDelegate: () => SupportWebSocketConnection(
          uri: options.uri,
          onDiagnostic: _debug,
        ),
        minimumReconnectDelayDuration: const Duration(seconds: 2),
        connectionErrorHandler: (error, _, refresh) {
          _debug('transport error: ${error.runtimeType}');
          _setLive(false);
          refresh();
        },
      );
      _client = client;
      _clientWhispersEnabled = true;
      _debug(
        'connecting driver=${config.driver} scheme=$scheme '
        'target=${config.driver == 'pusher' ? config.cluster : config.host} '
        'port=${config.port}',
      );

      final authHeaders = Map<String, String>.from(headers ?? const {});
      authHeaders.removeWhere(
        (name, _) => name.toLowerCase() == 'content-type',
      );
      final privateChannel = client.privateChannel(
      'private-support.thread.$threadUuid',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPrivateChannel(
        authorizationEndpoint: authUri,
        headers: authHeaders,
        onAuthFailed: (error, _) {
          _debug('private auth failed: ${error.runtimeType}');
          _setLive(false);
        },
      ),
    );
    final presenceChannel = client.presenceChannel(
      'presence-support.presence.thread.$threadUuid',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPresenceChannel(
        authorizationEndpoint: authUri,
        headers: authHeaders,
        onAuthFailed: (error, _) {
          _debug('presence auth failed: ${error.runtimeType}');
          _setLive(false);
        },
      ),
    );
    _threadChannel = privateChannel;
    _presenceChannel = presenceChannel;

    _subscriptions.addAll([
      privateChannel.whenSubscriptionSucceeded().listen((_) {
        _debug('private subscription succeeded');
        _setLive(true);
      }),
      privateChannel.onSubscriptionError().listen((event) {
        _debug(
          'private subscription failed: '
          '${event.tryGetDataAsMap()?['type'] ?? 'unknown'}',
        );
        _setLive(false);
      }),
      presenceChannel.whenSubscriptionSucceeded().listen((_) {
        _debug('presence subscription succeeded');
      }),
      presenceChannel.onSubscriptionError().listen((event) {
        _debug(
          'presence subscription failed: '
          '${event.tryGetDataAsMap()?['type'] ?? 'unknown'}',
        );
      }),
      privateChannel.bind('support.activity').listen(
            (event) => _emit('support.activity', event.tryGetDataAsMap()),
          ),
      privateChannel.bind('support.typing').listen(
            (event) => _emit('support.typing', event.tryGetDataAsMap()),
          ),
      presenceChannel.bind('client-typing').listen(
            (event) => _emit('support.typing', event.tryGetDataAsMap()),
          ),
      client.pusherErrorEventStream.listen((event) {
        final data = event.tryGetDataAsMap();
        final message = data?['message']?.toString() ?? '';
        _debug('protocol error: ${message.isEmpty ? 'unknown' : message}');
        if (message.toLowerCase().contains('client events')) {
          _clientWhispersEnabled = false;
          _debug('client typing whisper disabled; REST typing remains active');
        }
      }),
      client.lifecycleStream.listen((state) {
        _lifecycleState = state;
        _debug('lifecycle: ${state.name}');
        if (_transportIsUnavailable(state)) {
          _setLive(false);
        }
      }),
      client.onConnectionEstablished.listen((_) {
        _debug('transport established; authorizing channels');
        privateChannel.subscribeIfNotUnsubscribed();
        presenceChannel.subscribeIfNotUnsubscribed();
      }),
    ]);

    unawaited(client.connect());
    } catch (e) {
      _debug('connect failed: $e');
      _setLive(false);
    }
  }

  /// Retries both the transport and private-channel authorization.
  ///
  /// A socket can stay connected while a private subscription fails because
  /// authentication was temporarily unavailable. Re-subscribing is therefore
  /// required in addition to reconnecting the underlying socket.
  Future<void> retry() async {
    final client = _client;
    if (client == null || _isLive || _retrying) return;
    _retrying = true;
    try {
      if (_lifecycleState ==
          PusherChannelsClientLifeCycleState.establishedConnection) {
        _threadChannel?.subscribeIfNotUnsubscribed();
        _presenceChannel?.subscribeIfNotUnsubscribed();
      } else if (_lifecycleState !=
              PusherChannelsClientLifeCycleState.pendingConnection &&
          _lifecycleState != PusherChannelsClientLifeCycleState.reconnecting) {
        await client.reconnect();
      }
    } catch (_) {
      _setLive(false);
    } finally {
      _retrying = false;
    }
  }

  void whisperTyping(bool typing) {
    if (!_isLive || !_clientWhispersEnabled) return;
    _presenceChannel?.trigger(
      eventName: 'client-typing',
      data: {'role': 'customer', 'typing': typing},
    );
  }

  Future<void> disconnect() async {
    _setLive(false);
    _lifecycleState = PusherChannelsClientLifeCycleState.inactive;
    _retrying = false;
    _clientWhispersEnabled = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _threadChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _threadChannel = null;
    _presenceChannel = null;
    _client?.dispose();
    _client = null;
  }

  void _emit(String name, Map<String, dynamic>? data) {
    if (data != null && !_events.isClosed) {
      _events.add(SupportRealtimeEvent(name, data));
    }
  }

  void _setLive(bool value) {
    if (_isLive == value) return;
    _isLive = value;
    _debug('private channel live: $value');
    if (!_live.isClosed) _live.add(value);
  }

  /// `gotPusherError` is a protocol/application error, not proof that the
  /// transport or an already-authorized private subscription was lost.
  /// A common example is managed Pusher rejecting optional client events.
  static bool transportIsUnavailableForTest(
    PusherChannelsClientLifeCycleState state,
  ) =>
      _transportIsUnavailable(state);

  static bool _transportIsUnavailable(
    PusherChannelsClientLifeCycleState state,
  ) =>
      switch (state) {
        PusherChannelsClientLifeCycleState.establishedConnection ||
        PusherChannelsClientLifeCycleState.gotPusherError =>
          false,
        _ => true,
      };

  void _debug(String message) {
    if (kDebugMode) debugPrint('[SupportRealtime] $message');
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
    await _live.close();
  }
}
