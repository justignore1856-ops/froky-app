import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/config/dependency_injection_container.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/repo/support_repository.dart';
import 'package:hyper_commerce/screens/support_page/widgets/support_attachment_view.dart';
import 'package:photo_view/photo_view.dart';

void main() {
  late _Attachments repository;
  setUp(() {
    repository = _Attachments();
    getIt.registerSingleton<SupportRepository>(repository);
  });
  tearDown(() => getIt.unregister<SupportRepository>());

  Future<void> pump(WidgetTester tester,
      {String mime = 'image/png', String url = '/first'}) async {
    repository.bytes = (await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 48, 48), Paint()..color = Colors.blue);
      final picture = recorder.endRecording();
      final image = await picture.toImage(48, 48);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      picture.dispose();
      return bytes!.buffer.asUint8List();
    }))!;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: Center(
              child: SizedBox(
        width: 210,
        child: SupportAttachmentView(
            attachment: SupportAttachment(
          id: 1,
          name: 'Customer evidence with a long filename',
          mimeType: mime,
          size: 100,
          downloadUrl: url,
        )),
      ))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('image has explicit preview and download on narrow screens',
      (tester) async {
    await pump(tester);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    await tester.tap(find.text('Preview'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.byType(PhotoView), findsOneWidget);
    final controller =
        tester.widget<PhotoView>(find.byType(PhotoView)).controller!;
    for (var attempt = 0; attempt < 10 && controller.scale == null; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(controller.scale, isNotNull);
    final initialScale = controller.scale!;
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(controller.scale, greaterThan(initialScale));
    await tester.tap(find.byTooltip('Reset zoom'));
    await tester.pump();
    expect(controller.scale, initialScale);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF actions remain visible and enabled without row overflow',
      (tester) async {
    await pump(tester, mime: 'application/pdf');
    for (final label in ['Preview', 'Download']) {
      final button =
          tester.widget<TextButton>(find.widgetWithText(TextButton, label));
      expect(button.onPressed, isNotNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed authenticated media can retry and updated URL reloads',
      (tester) async {
    repository.fail = true;
    await pump(tester);
    expect(find.text('Retry'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    await pump(tester, url: '/updated');
    expect(repository.urls, ['/first', '/first', '/updated']);
    expect(tester.takeException(), isNull);
  });
}

class _Attachments extends SupportRepository {
  bool fail = false;
  final urls = <String>[];
  late Uint8List bytes;

  @override
  Future<Uint8List> getAttachment(String url) async {
    urls.add(url);
    if (fail) throw const SupportApiException('Unavailable');
    return bytes;
  }
}
