import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/screens/support_page/model/support_models.dart';
import 'package:hyper_commerce/screens/support_page/service/support_attachment_cache.dart';

void main() {
  test('dropped files use private temporary paths and are cleaned up',
      () async {
    final attachment = await cacheSupportDrop(
        Stream.value([1, 2, 3]), '../../evidence.png', 'image/png', 'png');
    expect(attachment.name, 'evidence.png');
    expect(attachment.size, 3);
    expect(attachment.temporary, isTrue);
    expect(await attachment.file.readAsBytes(), [1, 2, 3]);
    final directory = attachment.file.parent;
    await removeSupportDrop(attachment);
    expect(await directory.exists(), isFalse);
  });

  test('empty and oversized native drops are rejected', () async {
    await expectLater(
        cacheSupportDrop(const Stream.empty(), null, 'image/png', 'png'),
        throwsFormatException);
    await expectLater(
        cacheSupportDrop(Stream.value(List.filled(10 * 1024 * 1024 + 1, 0)),
            'large.pdf', 'application/pdf', 'pdf'),
        throwsFormatException);
  });

  test('cleanup never removes a file selected outside the temporary drop cache',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('support-cache-test-');
    final file = await File('${directory.path}/original.png').writeAsBytes([1]);
    await removeSupportDrop(SupportLocalAttachment(
        path: file.path, name: 'original.png', size: 1, mimeType: 'image/png'));
    expect(await file.exists(), isTrue);
    await file.delete();
    await directory.delete();
  });
}
