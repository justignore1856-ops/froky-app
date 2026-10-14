import 'package:flutter/material.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/widgets/support_timeline.dart';

void main() {
  testWidgets('older pages preserve the visible message with variable heights',
      (tester) async {
    var first = 51;
    var last = 100;
    var loading = false;
    var typing = false;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
        update = setState;
        return SupportTimeline(
          messages: [
            for (var id = first; id <= last; id++)
              SupportMessage(
                id: id,
                sessionId: 1,
                senderRole: 'admin',
                senderName: 'Agent',
                type: 'text',
                text: 'Message $id${'\nMore detail' * (id % 5)}',
                attachments: const [],
              ),
          ],
          sessions: const [],
          hasMore: first > 1,
          loadingOlder: loading,
          remoteTyping: typing,
          onLoadOlder: () {},
          onRetry: (_) {},
        );
      })),
    ));
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView));
    list.controller!.jumpTo(800);
    await tester.pumpAndSettle();
    final visible = find
        .byWidgetPredicate((widget) =>
            widget is Text && widget.data?.startsWith('Message ') == true)
        .evaluate()
        .where((element) {
          final box = element.renderObject as RenderBox;
          final y = box.localToGlobal(Offset.zero).dy;
          return y > 0 && y < 500;
        })
        .first
        .widget as Text;
    final anchor = find.text(visible.data!);
    final before = tester.getTopLeft(anchor).dy;
    update(() => loading = true);
    await tester.pump();
    update(() {
      first = 1;
      loading = false;
    });
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(anchor).dy, closeTo(before, 1));
    update(() => typing = true);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(anchor).dy, closeTo(before, 1));
    update(() => last = 101);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(anchor).dy, closeTo(before, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an availability reply as a support bubble',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SupportTimeline(
          messages: const [
            SupportMessage(
              id: 2,
              sessionId: 1,
              senderRole: 'system',
              senderName: 'Customer Support',
              type: 'auto_reply',
              text: 'Our team will reply when support hours resume.',
              attachments: [],
            ),
          ],
          sessions: const [],
          hasMore: false,
          loadingOlder: false,
          remoteTyping: false,
          onLoadOlder: () {},
          onRetry: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Customer Support'), findsOneWidget);
    expect(find.text('Our team will reply when support hours resume.'),
        findsOneWidget);
    expect(find.byType(AnimatedContainer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a dark Arabic support timeline on a phone viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SupportTimeline(
          messages: [
            SupportMessage(
              id: 1,
              sessionId: 1,
              senderRole: 'admin',
              senderName: 'Support',
              type: 'text',
              text: 'مرحبا',
              attachments: const [],
              createdAt: DateTime(2026, 9, 2, 14, 5),
            ),
          ],
          sessions: const [],
          hasMore: false,
          loadingOlder: false,
          remoteTyping: true,
          footer: const Text('Inline support action'),
          footerId: 'inline-action',
          onLoadOlder: () {},
          onRetry: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('مرحبا'), findsOneWidget);
    expect(find.text('فريق الدعم يكتب…'), findsOneWidget);
    expect(find.text('2:05 PM'), findsOneWidget);
    expect(find.text('Inline support action'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
