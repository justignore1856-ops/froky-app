import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/service/support_realtime_service.dart';

void main() {
  group('SupportRealtimeService transport state', () {
    test('keeps an authorized socket live after a protocol error', () {
      expect(
        SupportRealtimeService.transportIsUnavailableForTest(
          PusherChannelsClientLifeCycleState.gotPusherError,
        ),
        isFalse,
      );
    });

    test('falls back when the transport is unavailable', () {
      for (final state in [
        PusherChannelsClientLifeCycleState.connectionError,
        PusherChannelsClientLifeCycleState.disconnected,
        PusherChannelsClientLifeCycleState.reconnecting,
      ]) {
        expect(
          SupportRealtimeService.transportIsUnavailableForTest(state),
          isTrue,
        );
      }
    });
  });
}
