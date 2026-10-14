import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';

void main() {
  test('parses the permanent support timeline and typed session data', () {
    final payload = SupportThreadPayload.fromJson({
      'thread': {
        'id': 7,
        'uuid': 'thread-uuid',
        'active_ticket_id': 12,
        'customer': {'id': 3, 'name': 'Customer'},
        'message_pagination': {
          'has_more': true,
          'oldest_message_id': 41,
        },
        'sessions': [
          {
            'id': 11,
            'slug': 'SUP-OLD',
            'subject': 'Old issue',
            'status': 'resolved',
            'rating': {
              'score': 4,
              'feedback': 'Helpful',
              'agent': {'name': 'Agent One'},
            },
            'messages': [
              {
                'id': 42,
                'session_id': 11,
                'sender_role': 'system',
                'type': 'closure',
                'text': 'This conversation has been closed',
                'attachments': [],
              },
            ],
            'calls': [],
          },
          {
            'id': 12,
            'slug': 'SUP-ACTIVE',
            'subject': 'Delivery help',
            'status': 'open',
            'assignee': {
              'id': 8,
              'name': 'Agent Two',
              'avatar': 'https://example.test/agent-two.jpg',
            },
            'topic': {
              'id': 2,
              'slug': 'delivery',
              'title': 'Delivery',
              'quick_replies': ['My order is late'],
            },
            'messages': [
              {
                'id': 43,
                'session_id': 12,
                'client_message_id': 'client-id',
                'sender_role': 'user',
                'type': 'text',
                'text': 'Where is my order?',
                'attachments': [
                  {
                    'id': 9,
                    'name': 'proof.pdf',
                    'mime_type': 'application/pdf',
                    'size': 1200,
                    'download_url': 'https://example.test/proof.pdf',
                  },
                ],
              },
            ],
            'calls': [],
          },
        ],
      },
      'recent_orders': [],
      'poll_interval_ms': 15000,
      'polling_enabled': true,
      'realtime': {
        'driver': 'pusher',
        'key': 'public-key',
        'cluster': 'ap2',
        'port': 443,
        'scheme': 'https',
        'auth_endpoint': 'https://example.test/api/broadcasting/auth',
      },
    });

    expect(payload.thread.activeSession?.slug, 'SUP-ACTIVE');
    expect(
      payload.thread.activeSession?.assigneeAvatar,
      'https://example.test/agent-two.jpg',
    );
    expect(payload.thread.latestSession?.rating, isNull);
    expect(payload.thread.sessions.first.rating?.agentName, 'Agent One');
    expect(payload.thread.messages.map((message) => message.id), [42, 43]);
    expect(payload.thread.messages.last.attachments.single.isPdf, isTrue);
    expect(payload.thread.hasMoreMessages, isTrue);
    expect(payload.realtime.isConfigured, isTrue);
  });

  test('filters topics by order context', () {
    final order = SupportTopic.fromJson({
      'id': 1,
      'slug': 'order',
      'title': 'Order',
      'context': 'order',
    });
    final general = SupportTopic.fromJson({
      'id': 2,
      'slug': 'general',
      'title': 'General',
      'context': 'general',
    });
    final both = SupportTopic.fromJson({
      'id': 3,
      'slug': 'both',
      'title': 'Both',
      'context': 'both',
    });

    expect(order.supports(true), isTrue);
    expect(order.supports(false), isFalse);
    expect(general.supports(false), isTrue);
    expect(both.supports(true), isTrue);
    expect(both.supports(false), isTrue);
  });

  test('resolves relative auth_endpoint to absolute url', () {
    final config = SupportRealtimeConfig.fromJson({
      'driver': 'pusher',
      'key': 'test-key',
      'cluster': 'ap2',
      'auth_endpoint': '/api/v1/broadcasting/auth',
    });

    expect(config.isConfigured, isTrue);
    expect(config.authEndpoint.startsWith('http'), isTrue);
    expect(config.authEndpoint.endsWith('/api/v1/broadcasting/auth'), isTrue);
  });
}
