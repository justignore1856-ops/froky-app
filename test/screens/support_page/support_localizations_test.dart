import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';

void main() {
  final template = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
      as Map<String, dynamic>;
  final supportKeys = template.keys
      .where((key) => key.startsWith('support') && key != 'support')
      .toSet();

  for (final locale in AppLocalizations.supportedLocales) {
    test('support uses the existing ${locale.languageCode} ARB translations',
        () async {
      final arb = jsonDecode(
        File('lib/l10n/app_${locale.languageCode}.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(supportKeys, isNotEmpty);
      for (final key in supportKeys) {
        expect(arb[key], isA<String>(), reason: key);
        expect(arb[key], isNotEmpty, reason: key);
      }

      final strings = await AppLocalizations.delegate.load(locale);
      expect(strings.supportTitle, arb['supportTitle']);
      expect(strings.supportTyping, arb['supportTyping']);
      expect(strings.supportYou, arb['supportYou']);
      expect(strings.supportResolved, arb['supportResolved']);
      expect(strings.supportCallbackBody, arb['supportCallbackBody']);
      expect(strings.supportNewChatHint, arb['supportNewChatHint']);
      expect(strings.supportAttachmentError, arb['supportAttachmentError']);
    });
  }

  test('existing English fallback text is preserved', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('gu'));
    expect(strings.supportResolveBody, template['supportResolveBody']);
  });
}
