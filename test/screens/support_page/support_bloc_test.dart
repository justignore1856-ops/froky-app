import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/bloc/support_bloc.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/repo/support_repository.dart';
import 'package:hyper_commerce/screens/support_page/service/support_realtime_service.dart';

void main() {
  test('another delete during refresh is reconciled by a follow-up snapshot',
      () async {
    final repository = _FakeSupportRepository(_activePayload(messages: [
      _message(1, text: 'First'),
      _message(2, text: 'Second'),
    ]));
    final realtime = _FakeSupportRealtimeService();
    final bloc = SupportBloc(repository: repository, realtime: realtime);
    addTearDown(bloc.close);
    bloc.add(const SupportStarted());
    await bloc.stream.firstWhere((s) => s.status == SupportLoadStatus.loaded);
    final firstRefresh = Completer<SupportThreadPayload>();
    repository.nextThreadResponse = firstRefresh;
    realtime.emitActivity('message.deleted');
    await Future<void>.delayed(Duration.zero);
    expect(repository.threadRequests, 2);
    repository.nextThreadResponse = null;
    repository.payload = _activePayload();
    realtime.emitActivity('thread.cleared');
    await Future<void>.delayed(Duration.zero);
    firstRefresh
        .complete(_activePayload(messages: [_message(2, text: 'Second')]));
    await bloc.stream
        .firstWhere((s) => s.messages.isEmpty)
        .timeout(const Duration(seconds: 2));
    expect(repository.threadRequests, 3);
  });

  test('snapshot reconciliation keeps a message arriving over the socket',
      () async {
    final repository = _FakeSupportRepository(
        _activePayload(messages: [_message(1, text: 'Old')]));
    final realtime = _FakeSupportRealtimeService();
    final bloc = SupportBloc(repository: repository, realtime: realtime);
    addTearDown(bloc.close);
    bloc.add(const SupportStarted());
    await bloc.stream.firstWhere((s) => s.status == SupportLoadStatus.loaded);
    final snapshot = Completer<SupportThreadPayload>();
    repository.nextThreadResponse = snapshot;
    realtime.emitActivity('message.deleted');
    await Future<void>.delayed(Duration.zero);
    realtime.emitEvent(const SupportRealtimeEvent('support.activity', {
      'activity': 'message.created',
      'message_record': {
        'id': 3,
        'session_id': 10,
        'sender_role': 'admin',
        'type': 'text',
        'text': 'New reply',
        'attachments': []
      },
    }));
    await bloc.stream.firstWhere((s) => s.messages.any((m) => m.id == 3));
    snapshot.complete(_activePayload());
    final changed = await bloc.stream
        .firstWhere((s) => s.messages.length == 1)
        .timeout(const Duration(seconds: 2));
    expect(changed.messages.single.id, 3);
  });
  for (final activity in ['message.deleted', 'thread.cleared']) {
    test('$activity reconciles the timeline without resetting its cursor',
        () async {
      final repository = _FakeSupportRepository(_activePayload(
        messages: [_message(1, text: 'Old'), _message(50, text: 'Delete me')],
      ));
      final realtime = _FakeSupportRealtimeService();
      final bloc = SupportBloc(repository: repository, realtime: realtime);
      addTearDown(bloc.close);
      bloc.add(const SupportStarted());
      await bloc.stream.firstWhere((s) => s.status == SupportLoadStatus.loaded);
      realtime.setLive(true);
      await bloc.stream
          .firstWhere((s) => s.connectionMode == SupportConnectionMode.live);
      await Future<void>.delayed(Duration.zero);
      repository.payload = _activePayload(
        messages:
            activity == 'thread.cleared' ? [] : [_message(1, text: 'Old')],
      );
      realtime.emitActivity(activity);
      final changed = await bloc.stream
          .firstWhere(
            (s) => !s.messages.any((m) => m.id == 50),
          )
          .timeout(const Duration(seconds: 2));
      expect(changed.messages.map((m) => m.id),
          activity == 'thread.cleared' ? isEmpty : [1]);
      expect(changed.messageCursor, 50);
    });
  }

  test('delete reconciliation preserves already loaded older pages', () async {
    final repository = _FakeSupportRepository(_activePayload(
      messages: [_message(50, text: 'Delete me'), _message(51, text: 'Keep')],
      hasMore: true,
      oldestMessageId: 50,
    ));
    final realtime = _FakeSupportRealtimeService();
    final bloc = SupportBloc(repository: repository, realtime: realtime);
    addTearDown(bloc.close);
    bloc.add(const SupportStarted());
    await bloc.stream.firstWhere((s) => s.status == SupportLoadStatus.loaded);
    bloc.add(const SupportLoadOlderRequested());
    await bloc.stream.firstWhere((s) => s.messages.length == 3);
    repository.payload = _activePayload(
      messages: [_message(51, text: 'Keep')],
      hasMore: true,
      oldestMessageId: 51,
    );
    realtime.emitActivity('message.deleted');
    final changed = await bloc.stream
        .firstWhere(
          (s) => s.messages.length == 2,
        )
        .timeout(const Duration(seconds: 2));
    expect(changed.messages.map((m) => m.id), [1, 51]);
    expect(changed.oldestMessageId, 1);
    expect(changed.hasMoreMessages, false);
  });

  test('fallback polling catches a deletion without a socket event', () async {
    final repository = _FakeSupportRepository(_activePayload(
      messages: [_message(50, text: 'Delete me')],
    ));
    final bloc = SupportBloc(
        repository: repository, realtime: _FakeSupportRealtimeService());
    addTearDown(bloc.close);
    bloc.add(const SupportStarted());
    await bloc.stream.firstWhere((s) => s.status == SupportLoadStatus.loaded);
    repository.payload = _activePayload();
    final changed = await bloc.stream
        .firstWhere((s) => s.messages.isEmpty)
        .timeout(const Duration(seconds: 17));
    expect(changed.messageCursor, 50);
  });
  test('guided back clears one selection at a time but keeps the draft',
      () async {
    final bloc = SupportBloc(
      repository: _FakeSupportRepository(_activePayload()),
      realtime: _FakeSupportRealtimeService(),
    );
    addTearDown(bloc.close);
    bloc.add(const SupportFlowOpened());
    bloc.add(const SupportOrderSelected(22));
    bloc.add(const SupportTopicSelected(7));
    bloc.add(const SupportDraftChanged('Keep my draft'));
    await bloc.stream.firstWhere((s) => s.draft == 'Keep my draft');
    bloc.add(const SupportFlowBackRequested());
    final topics =
        await bloc.stream.firstWhere((s) => s.selectedTopicId == null);
    expect(topics.selectedOrderId, 22);
    expect(topics.orderSelectionMade, true);
    expect(topics.draft, 'Keep my draft');
    bloc.add(const SupportFlowBackRequested());
    final orders = await bloc.stream.firstWhere((s) => !s.orderSelectionMade);
    expect(orders.selectedOrderId, isNull);
    expect(orders.flowOpen, true);
    expect(orders.draft, 'Keep my draft');
  });

  test('resumes an active session, enters live mode, and reconciles a send',
      () async {
    final repository = _FakeSupportRepository(_activePayload());
    final realtime = _FakeSupportRealtimeService();
    final bloc = SupportBloc(repository: repository, realtime: realtime);

    final loaded = bloc.stream.firstWhere(
      (state) => state.status == SupportLoadStatus.loaded,
    );
    bloc.add(const SupportStarted());
    expect((await loaded).activeSession?.slug, 'SUP-1');

    final live = bloc.stream.firstWhere(
      (state) => state.connectionMode == SupportConnectionMode.live,
    );
    realtime.setLive(true);
    await live;

    final drafted = bloc.stream.firstWhere((state) => state.draft == 'Hello');
    bloc.add(const SupportDraftChanged('Hello'));
    await drafted;

    final sent = bloc.stream.firstWhere(
      (state) => state.messages.any((message) => message.id == 99),
    );
    bloc.add(const SupportSendRequested());
    final sentState = await sent;

    expect(repository.lastClientMessageId,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f-]{27}$')));
    expect(sentState.messages.single.clientMessageId,
        repository.lastClientMessageId);
    expect(sentState.messages.single.pending, isFalse);

    await bloc.close();
  });

  test('loads older messages chronologically and preserves the polling mode',
      () async {
    final repository = _FakeSupportRepository(_activePayload(
      messages: [_message(50, text: 'Newest')],
      hasMore: true,
      oldestMessageId: 50,
    ));
    final bloc = SupportBloc(
      repository: repository,
      realtime: _FakeSupportRealtimeService(),
    );
    final loaded = bloc.stream.firstWhere(
      (state) => state.status == SupportLoadStatus.loaded,
    );
    bloc.add(const SupportStarted());
    expect((await loaded).connectionMode, SupportConnectionMode.polling);

    final paged = bloc.stream.firstWhere(
      (state) => !state.hasMoreMessages && state.messages.length == 2,
    );
    bloc.add(const SupportLoadOlderRequested());
    final state = await paged;

    expect(state.messages.map((message) => message.id), [1, 50]);
    await bloc.close();
  });

  test('gracefully recovers and enters polling when realtime connection throws',
      () async {
    final repository = _FakeSupportRepository(_activePayload(messages: [
      _message(1, text: 'Hello'),
    ]));
    final realtime = _FakeSupportRealtimeService()..shouldThrowOnConnect = true;
    final bloc = SupportBloc(repository: repository, realtime: realtime);

    final loaded = bloc.stream.firstWhere(
      (state) => state.status == SupportLoadStatus.loaded,
    );
    bloc.add(const SupportStarted());
    final state = await loaded;

    expect(state.status, SupportLoadStatus.loaded);
    expect(state.connectionMode, SupportConnectionMode.polling);
    expect(state.messages.length, 1);
    await bloc.close();
  });

  test('continues automatic polling as a safety backup even when realtime is live',
      () async {
    final repository = _FakeSupportRepository(_activePayload(messages: [
      _message(1, text: 'Hello'),
    ]));
    final realtime = _FakeSupportRealtimeService();
    final bloc = SupportBloc(repository: repository, realtime: realtime);
    addTearDown(bloc.close);

    bloc.add(const SupportStarted());
    await bloc.stream.firstWhere((state) => state.status == SupportLoadStatus.loaded);

    realtime.setLive(true);
    await bloc.stream.firstWhere((state) => state.connectionMode == SupportConnectionMode.live);
    await Future<void>.delayed(Duration.zero);

    expect(repository.threadRequests, 2);
  });
}

class _FakeSupportRepository extends SupportRepository {
  _FakeSupportRepository(this.payload);

  SupportThreadPayload payload;
  Completer<SupportThreadPayload>? nextThreadResponse;
  int threadRequests = 0;
  String? lastClientMessageId;

  @override
  Future<SupportThreadPayload> getThread() async {
    threadRequests++;
    return nextThreadResponse == null
        ? payload
        : await nextThreadResponse!.future;
  }

  @override
  Future<List<SupportTopic>> getTopics() async => const [];

  @override
  Future<SupportUpdates> getUpdates({
    required int afterMessageId,
    required int afterCallId,
  }) async =>
      SupportUpdates(
        messages: const [],
        calls: const [],
        messageCursor: afterMessageId,
        callCursor: afterCallId,
        activeTicketId: payload.thread.activeTicketId,
      );

  @override
  Future<SupportMessagePage> getOlderMessages(int beforeMessageId) async =>
      SupportMessagePage(
        messages: [_message(1, text: 'Oldest')],
        hasMore: false,
        oldestMessageId: 1,
      );

  @override
  Future<SupportMessage> sendMessage({
    required String slug,
    required String message,
    required List<SupportLocalAttachment> attachments,
    required String clientMessageId,
  }) async {
    lastClientMessageId = clientMessageId;
    return _message(99, text: message, clientMessageId: clientMessageId);
  }

  @override
  Future<void> markRead(String slug, int? messageId) async {}

  @override
  Future<void> setTyping(String slug, bool typing) async {}
}

class _FakeSupportRealtimeService extends SupportRealtimeService {
  final _liveController = StreamController<bool>.broadcast();
  final _eventController = StreamController<SupportRealtimeEvent>.broadcast();
  bool _live = false;

  @override
  Stream<bool> get liveChanges => _liveController.stream;

  @override
  Stream<SupportRealtimeEvent> get events => _eventController.stream;

  @override
  bool get isLive => _live;

  bool shouldThrowOnConnect = false;

  @override
  Future<void> connect({
    required SupportRealtimeConfig config,
    required String threadUuid,
  }) async {
    if (shouldThrowOnConnect) {
      throw Exception('Socket connection refused');
    }
  }

  void setLive(bool value) {
    _live = value;
    _liveController.add(value);
  }

  void emitActivity(String activity) => _eventController.add(
        SupportRealtimeEvent('support.activity', {'activity': activity}),
      );

  void emitEvent(SupportRealtimeEvent event) => _eventController.add(event);

  @override
  void whisperTyping(bool typing) {}

  @override
  Future<void> dispose() async {
    await _liveController.close();
    await _eventController.close();
  }
}

SupportThreadPayload _activePayload({
  List<SupportMessage> messages = const [],
  bool hasMore = false,
  int? oldestMessageId,
}) =>
    SupportThreadPayload(
      thread: SupportThread(
        id: 1,
        uuid: 'thread-uuid',
        activeTicketId: 10,
        customer: const SupportCustomer(id: 1, name: 'Customer'),
        sessions: [
          SupportSession(
            id: 10,
            slug: 'SUP-1',
            subject: 'Help',
            status: 'open',
            messages: messages,
            calls: const [],
          ),
        ],
        hasMoreMessages: hasMore,
        oldestMessageId: oldestMessageId,
      ),
      recentOrders: const [],
      pollIntervalMs: 15000,
      pollingEnabled: true,
      realtime: const SupportRealtimeConfig(
        driver: 'pusher',
        key: 'key',
        port: 443,
        scheme: 'https',
        cluster: 'ap2',
        authEndpoint: 'https://example.test/api/broadcasting/auth',
      ),
    );

SupportMessage _message(
  int id, {
  required String text,
  String? clientMessageId,
}) =>
    SupportMessage(
      id: id,
      sessionId: 10,
      clientMessageId: clientMessageId,
      senderRole: 'user',
      type: 'text',
      text: text,
      attachments: const [],
      createdAt: DateTime(2026, 9, 2, 10, id.clamp(0, 59)),
    );
