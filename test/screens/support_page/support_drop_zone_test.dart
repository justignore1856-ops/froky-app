import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/support_page/widgets/support_drop_zone.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/service/support_attachment_cache.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'support_drop_test_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockSupportDropPlatform);
  testWidgets('a performed native drop reaches the attachment draft',
      (tester) async {
    final received = Completer<List<SupportLocalAttachment>>.sync();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: SupportDropZone(
        enabled: true,
        remaining: 5,
        onFiles: received.complete,
        child: const SizedBox.expand(),
      )),
    ));
    final region = tester.widget<DropRegion>(find.byType(DropRegion));
    final session = _Session()..items = [_Item(Formats.png, _Reader())];
    await tester.runAsync(() async {
      await region.onPerformDrop(PerformDropEvent(
          session: session,
          position: DropPosition(local: Offset.zero, global: Offset.zero),
          acceptedOperation: DropOperation.copy));
      final files = await received.future.timeout(const Duration(seconds: 5));
      expect(files.single.mimeType, 'image/png');
      expect(files.single.size, 4);
      expect(await files.single.file.readAsBytes(), [137, 80, 78, 71]);
      await removeSupportDrop(files.single);
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('native read exceptions show feedback and release the drop zone',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: SupportDropZone(
        enabled: true,
        remaining: 5,
        onFiles: (_) => fail('Failed read attached'),
        child: const SizedBox.expand(),
      )),
    ));
    final region = tester.widget<DropRegion>(find.byType(DropRegion));
    final session = _Session()
      ..items = [_Item(Formats.png, _Reader(fails: true))];
    await region.onPerformDrop(PerformDropEvent(
        session: session,
        position: DropPosition(local: Offset.zero, global: Offset.zero),
        acceptedOperation: DropOperation.copy));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'native file hover is highlighted only for permitted media and capacity',
      (tester) async {
    Future<DropRegion> pump({bool enabled = true, int remaining = 5}) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: SupportDropZone(
          enabled: enabled,
          remaining: remaining,
          onFiles: (_) => fail('Hover must not upload or attach files'),
          child: const SizedBox.expand(),
        )),
      ));
      return tester.widget<DropRegion>(find.byType(DropRegion));
    }

    final session = _Session();
    final event = DropOverEvent(
        session: session,
        position: DropPosition(local: Offset.zero, global: Offset.zero));
    var region = await pump();
    expect(await region.onDropOver(event), DropOperation.copy);
    await tester.pump();
    expect(find.text('Drop images or PDFs to attach'), findsOneWidget);
    region.onDropLeave!(DropEvent(session: session));
    await tester.pump();
    expect(find.text('Drop images or PDFs to attach'), findsNothing);
    region = await pump(enabled: false);
    expect(await region.onDropOver(event), DropOperation.none);
    region = await pump(remaining: 0);
    expect(await region.onDropOver(event), DropOperation.none);
    region = await pump();
    session.items = [_Item(Formats.plainText)];
    expect(await region.onDropOver(event), DropOperation.none);
    expect(tester.takeException(), isNull);
  });
}

class _Item extends DropItem {
  _Item(this.format, [this.reader]);
  final DataFormat format;
  final DataReader? reader;
  @override
  DataReader? get dataReader => reader;
  @override
  List<String> get platformFormats => ['test-format'];
  @override
  bool canProvide(DataFormat f) => f == format;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reader extends DataReader {
  _Reader({this.fails = false});
  final bool fails;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getFile) {
      if (fails) throw StateError('Native read failed');
      final callback = invocation.positionalArguments[1] as Function;
      callback(_File());
      return _Progress();
    }
    return super.noSuchMethod(invocation);
  }
}

class _Progress implements ReadProgress {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _File extends DataReaderFile {
  @override
  String get fileName => 'proof.png';
  @override
  int get fileSize => 4;
  @override
  Stream<Uint8List> getStream() =>
      Stream.value(Uint8List.fromList([137, 80, 78, 71]));
  @override
  Future<Uint8List> readAll() async => Uint8List.fromList([137, 80, 78, 71]);
  @override
  void close() {}
}

class _Session extends DropSession {
  @override
  List<DropItem> items = [_Item(Formats.png)];
  @override
  Set<DropOperation> get allowedOperations => {DropOperation.copy};
  @override
  final onDisposed = ChangeNotifier();
}
