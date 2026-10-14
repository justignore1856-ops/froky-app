import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/config/dependency_injection_container.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/support_page/bloc/support_bloc.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/repo/support_repository.dart';
import 'package:hyper_commerce/screens/support_page/service/support_realtime_service.dart';
import 'package:hyper_commerce/screens/support_page/view/support_page.dart';
import 'package:hyper_commerce/services/user_cart/user_cart_local.dart';
import 'package:hyper_commerce/services/user_cart/user_cart_remote.dart';
import 'support_drop_test_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repository repository;
  late SupportBloc support;
  late CartBloc cart;

  setUp(() {
    mockSupportDropPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/connectivity'),
            (_) async => ['none']);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel(
                'dev.fluttercommunity.plus/connectivity_status'),
            (_) async => null);
    repository = _Repository();
    support = SupportBloc(repository: repository, realtime: _Realtime());
    cart = CartBloc(_LocalCart(), _RemoteCart());
    getIt.registerFactory<SupportBloc>(() => support);
  });

  tearDown(() async {
    await getIt.unregister<SupportBloc>();
    await support.close();
    await cart.close();
  });

  Future<void> pump(WidgetTester tester, {bool active = true}) async {
    repository.active = active;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(value: cart, child: const SupportPage()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(support.state.status, SupportLoadStatus.loaded,
        reason: support.state.error);
  }

  testWidgets(
      'call and resolve are in overflow and still confirm before acting',
      (tester) async {
    await pump(tester);
    expect(find.text('Resolve chat'), findsNothing);
    expect(find.text('Request callback'), findsNothing);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request callback'));
    await tester.pumpAndSettle();
    expect(find.text('Request a call on your registered phone number?'),
        findsOneWidget);
    expect(repository.callbacks, 0);
    Navigator.of(tester.element(find.text('Request callback'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolve chat'));
    await tester.pumpAndSettle();
    expect(find.text('Resolve this chat?'), findsOneWidget);
    expect(repository.resolutions, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('guidance back returns to topics then orders', (tester) async {
    await pump(tester, active: false);
    await tester.tap(find.text('My issue is not related to an order'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General question'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    expect(find.text('Please describe your question.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    expect(find.text('Please describe your question.'), findsNothing);
    expect(find.text('General question'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    expect(find.text('Which order do you need help with?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

class _Repository extends SupportRepository {
  bool active = true;
  int callbacks = 0;
  int resolutions = 0;

  @override
  Future<SupportThreadPayload> getThread() async =>
      SupportThreadPayload.fromJson({
        'thread': {
          'id': 1,
          'uuid': 'thread',
          'active_ticket_id': active ? 1 : null,
          'customer': {'id': 1, 'name': 'Customer'},
          'sessions': active
              ? [
                  {
                    'id': 1,
                    'slug': 'SUP-1',
                    'status': 'open',
                    'subject': 'Help',
                    'messages': [],
                    'calls': []
                  }
                ]
              : [],
        },
        'polling_enabled': false,
      });

  @override
  Future<List<SupportTopic>> getTopics() async => [
        SupportTopic.fromJson({
          'id': 1,
          'title': 'General question',
          'context': 'general',
          'guidance': 'Please describe your question.',
        })
      ];

  @override
  Future<void> requestCallback(String slug, {String? phone}) async {
    callbacks++;
  }

  @override
  Future<void> resolve(String slug, {String? summary}) async {
    resolutions++;
  }

  @override
  Future<void> markRead(String slug, int? messageId) async {}
}

class _Realtime extends SupportRealtimeService {
  @override
  Stream<bool> get liveChanges => const Stream.empty();
  @override
  Stream<SupportRealtimeEvent> get events => const Stream.empty();
  @override
  Future<void> connect(
      {required SupportRealtimeConfig config,
      required String threadUuid}) async {}
  @override
  Future<void> retry() async {}
}

class _LocalCart extends Fake implements CartLocalRepository {}

class _RemoteCart extends Fake implements CartRemoteRepository {}
