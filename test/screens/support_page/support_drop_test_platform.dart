// ignore_for_file: depend_on_referenced_packages, implementation_imports

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irondash_message_channel/irondash_message_channel.dart';
import 'package:super_native_extensions/src/native/context.dart';

export 'package:super_clipboard/super_clipboard.dart'
    show DataReader, DataReaderFile, ReadProgress;

void mockSupportDropPlatform() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('dev.irondash.engine_context'), (_) async => 1);
  final context = superNativeExtensionsContext as MockMessageChannelContext;
  context.registerMockMethodCallHandler('DropManager', (_) async => null);
  context.registerMockMethodCallHandler('DragManager', (_) async => null);
}
