import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/bloc/support_bloc.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/repo/support_repository.dart';
import 'package:hyper_commerce/screens/support_page/service/support_realtime_service.dart';
import 'package:hyper_commerce/screens/support_page/widgets/support_avatar.dart';
import 'package:hyper_commerce/screens/support_page/widgets/support_feedback.dart';
import 'package:hyper_commerce/screens/support_page/widgets/support_timeline.dart';

void main() {
  group('support response models', () {
    test('parse a permanent thread and keep messages chronological', () {
      final payload = _payload();

      expect(payload.thread.uuid, 'thread-uuid');
      expect(payload.thread.activeSession?.slug, 'SUP-100');
      expect(payload.thread.messages.map((message) => message.id), [1, 2]);
      expect(payload.thread.messages.last.attachments.single.isPdf, isTrue);
      expect(payload.realtime.isConfigured, isFalse);
    });
  });

  group('SupportBloc', () {
    test('loads the active session and changes between polling and live',
        () async {
      final repository = _FakeSupportRepository(_payload());
      final realtime = _FakeSupportRealtimeService();
      final bloc = SupportBloc(repository: repository, realtime: realtime);
      addTearDown(bloc.close);

      bloc.add(const SupportStarted());
      await _waitFor(bloc, (state) => state.status == SupportLoadStatus.loaded);

      expect(bloc.state.activeSession?.slug, 'SUP-100');
      expect(bloc.state.connectionMode, SupportConnectionMode.polling);

      realtime.emitLive(true);
      await _waitFor(
        bloc,
        (state) => state.connectionMode == SupportConnectionMode.live,
      );

      realtime.emitLive(false);
      await _waitFor(
        bloc,
        (state) => state.connectionMode == SupportConnectionMode.polling,
      );
    });

    test('optimistically sends and reconciles by client message id', () async {
      final repository = _FakeSupportRepository(_payload());
      final realtime = _FakeSupportRealtimeService();
      final bloc = SupportBloc(repository: repository, realtime: realtime);
      addTearDown(bloc.close);

      bloc.add(const SupportStarted());
      await _waitFor(bloc, (state) => state.status == SupportLoadStatus.loaded);
      bloc.add(const SupportDraftChanged('Please help me.'));
      await _waitFor(bloc, (state) => state.draft == 'Please help me.');
      bloc.add(const SupportSendRequested());

      final optimistic = await _waitFor(
        bloc,
        (state) => state.messages.any((message) => message.pending),
      );
      final pending = optimistic.messages.last;
      expect(pending.clientMessageId, isNotEmpty);
      expect(pending.id, lessThan(0));

      repository.completeSend(
        SupportMessage(
          id: 3,
          sessionId: 1,
          clientMessageId: pending.clientMessageId,
          senderRole: 'user',
          senderName: 'Customer',
          type: 'text',
          text: pending.text,
          attachments: const [],
          createdAt: DateTime(2026, 9, 2, 10, 10),
        ),
      );
      await _waitFor(
        bloc,
        (state) => state.messages.any((message) => message.id == 3),
      );

      expect(
        bloc.state.messages.where(
          (message) => message.clientMessageId == pending.clientMessageId,
        ),
        hasLength(1),
      );
      expect(repository.lastClientMessageId, pending.clientMessageId);
      expect(repository.typingStates, containsAllInOrder([true, false]));
    });

    test('expires a remote typing indicator when a stop event is lost',
        () async {
      final repository = _FakeSupportRepository(_payload());
      final realtime = _FakeSupportRealtimeService();
      final bloc = SupportBloc(repository: repository, realtime: realtime);
      addTearDown(bloc.close);

      bloc.add(const SupportStarted());
      await _waitFor(bloc, (state) => state.status == SupportLoadStatus.loaded);
      realtime.emitEvent(const SupportRealtimeEvent(
        'support.typing',
        {'role': 'admin', 'typing': true},
      ));
      await _waitFor(bloc, (state) => state.remoteTyping);

      final expired = await bloc.stream
          .firstWhere((state) => !state.remoteTyping)
          .timeout(const Duration(seconds: 6));
      expect(expired.remoteTyping, isFalse);
    });

    test('consumes transient feedback so draft changes cannot replay it',
        () async {
      final repository = _FakeSupportRepository(_payload());
      final realtime = _FakeSupportRealtimeService();
      final bloc = SupportBloc(repository: repository, realtime: realtime);
      addTearDown(bloc.close);

      bloc.add(const SupportStarted());
      await _waitFor(bloc, (state) => state.status == SupportLoadStatus.loaded);
      bloc.add(const SupportCallbackRequested());
      await _waitFor(bloc, (state) => state.notice == 'Callback requested.');

      bloc.add(const SupportFeedbackConsumed());
      await _waitFor(
        bloc,
        (state) => state.notice == null && state.error == null,
      );
      bloc.add(const SupportDraftChanged('Typing must not replay the toast'));
      final drafted = await _waitFor(
        bloc,
        (state) => state.draft == 'Typing must not replay the toast',
      );

      expect(drafted.notice, isNull);
    });

    test('merges a committed websocket message without polling the API',
        () async {
      final repository = _FakeSupportRepository(_payload());
      final realtime = _FakeSupportRealtimeService();
      final bloc = SupportBloc(repository: repository, realtime: realtime);
      addTearDown(bloc.close);

      bloc.add(const SupportStarted());
      await _waitFor(bloc, (state) => state.status == SupportLoadStatus.loaded);
      realtime.emitEvent(const SupportRealtimeEvent(
        'support.activity',
        {
          'activity': 'message.created',
          'message_record': {
            'id': 77,
            'session_id': 1,
            'sender_role': 'admin',
            'sender_name': 'Agent',
            'type': 'text',
            'text': 'This came through the socket.',
            'attachments': <dynamic>[],
            'created_at': '2026-09-02T12:00:00+05:30',
          },
        },
      ));

      final received = await _waitFor(
        bloc,
        (state) => state.messages.any((message) => message.id == 77),
      );
      expect(received.messages.last.text, 'This came through the socket.');
      expect(repository.updateRequests, 0);
    });
  });

  testWidgets('timeline renders native bubbles in light, dark and RTL', (
    tester,
  ) async {
    Future<void> pump({required ThemeMode mode, required Locale locale}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SupportTimeline(
              messages: _payload()
                  .thread
                  .messages
                  .map((message) => message.copyWith(attachments: const []))
                  .toList(),
              sessions: _payload().thread.sessions,
              hasMore: false,
              loadingOlder: false,
              remoteTyping: true,
              onLoadOlder: () {},
              onRetry: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(mode: ThemeMode.light, locale: const Locale('en'));
    expect(find.text('Where is my order?'), findsOneWidget);
    expect(find.text('I am checking it.'), findsOneWidget);
    expect(find.byType(SupportAvatar), findsAtLeastNWidgets(2));

    await pump(mode: ThemeMode.dark, locale: const Locale('ar'));
    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });

  testWidgets('support feedback is safely removed with its scaffold',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showSupportFeedback(
                context,
                message: 'Saved',
                type: SupportFeedbackType.success,
              ),
              child: const Text('Show feedback'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show feedback'));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<SupportState> _waitFor(
  SupportBloc bloc,
  bool Function(SupportState state) predicate,
) async {
  if (predicate(bloc.state)) return bloc.state;
  return bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 4));
}

SupportThreadPayload _payload() => SupportThreadPayload.fromJson({
      'thread': {
        'id': 1,
        'uuid': 'thread-uuid',
        'active_ticket_id': 1,
        'customer': {
          'id': 10,
          'name': 'Customer',
          'email': 'customer@example.com',
        },
        'sessions': [
          {
            'id': 1,
            'slug': 'SUP-100',
            'subject': 'Delivery help',
            'status': 'open',
            'topic': {
              'id': 5,
              'slug': 'delivery',
              'title': 'Delivery',
              'quick_replies': ['My order is late'],
            },
            'assignee': null,
            'messages': [
              {
                'id': 2,
                'session_id': 1,
                'sender_role': 'admin',
                'sender_name': 'Support agent',
                'type': 'text',
                'text': 'I am checking it.',
                'attachments': [
                  {
                    'id': 8,
                    'name': 'receipt.pdf',
                    'mime_type': 'application/pdf',
                    'size': 1200,
                    'download_url': 'https://example.test/receipt.pdf',
                  },
                ],
                'created_at': '2026-09-02T10:05:00+05:30',
              },
              {
                'id': 1,
                'session_id': 1,
                'sender_role': 'user',
                'sender_name': 'Customer',
                'type': 'text',
                'text': 'Where is my order?',
                'attachments': [],
                'created_at': '2026-09-02T10:00:00+05:30',
              },
            ],
            'calls': [],
            'created_at': '2026-09-02T10:00:00+05:30',
          },
        ],
        'message_pagination': {
          'has_more': false,
          'oldest_message_id': 1,
        },
      },
      'recent_orders': [],
      'poll_interval_ms': 15000,
      'polling_enabled': true,
      'realtime': {
        'driver': 'reverb',
        'key': null,
        'host': null,
        'port': 443,
        'scheme': 'https',
        'cluster': 'mt1',
        'auth_endpoint': 'https://example.test/api/broadcasting/auth',
      },
    });

class _FakeSupportRepository extends SupportRepository {
  _FakeSupportRepository(this.payload);

  final SupportThreadPayload payload;
  final sendCompleter = Completer<SupportMessage>();
  final List<bool> typingStates = [];
  String? lastClientMessageId;
  int updateRequests = 0;

  @override
  Future<SupportThreadPayload> getThread() async => payload;

  @override
  Future<List<SupportTopic>> getTopics() async => const [];

  @override
  Future<SupportUpdates> getUpdates({
    required int afterMessageId,
    required int afterCallId,
  }) async {
    updateRequests++;
    return SupportUpdates(
      messages: const [],
      calls: const [],
      messageCursor: afterMessageId,
      callCursor: afterCallId,
      activeTicketId: payload.thread.activeTicketId,
    );
  }

  @override
  Future<SupportMessage> sendMessage({
    required String slug,
    required String message,
    required List<SupportLocalAttachment> attachments,
    required String clientMessageId,
  }) {
    lastClientMessageId = clientMessageId;
    return sendCompleter.future;
  }

  @override
  Future<void> setTyping(String slug, bool typing) async {
    typingStates.add(typing);
  }

  @override
  Future<void> requestCallback(String slug, {String? phone}) async {}

  @override
  Future<void> markRead(String slug, int? messageId) async {}

  void completeSend(SupportMessage message) => sendCompleter.complete(message);
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

  @override
  Future<void> connect({
    required SupportRealtimeConfig config,
    required String threadUuid,
  }) async {}

  void emitLive(bool value) {
    _live = value;
    _liveController.add(value);
  }

  void emitEvent(SupportRealtimeEvent event) => _eventController.add(event);

  @override
  void whisperTyping(bool typing) {}

  @override
  Future<void> dispose() async {
    await _liveController.close();
    await _eventController.close();
  }
}
