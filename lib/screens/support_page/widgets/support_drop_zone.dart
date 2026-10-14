import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../l10n/app_localizations.dart';
import '../model/support_models.dart';
import '../service/support_attachment_cache.dart';
import 'support_feedback.dart';

class SupportDropZone extends StatefulWidget {
  const SupportDropZone(
      {super.key,
      required this.enabled,
      required this.remaining,
      required this.onFiles,
      required this.child});

  final bool enabled;
  final int remaining;
  final ValueChanged<List<SupportLocalAttachment>> onFiles;
  final Widget child;

  @override
  State<SupportDropZone> createState() => _SupportDropZoneState();
}

class _SupportDropZoneState extends State<SupportDropZone> {
  static const _formats = [
    Formats.jpeg,
    Formats.png,
    Formats.webp,
    Formats.pdf
  ];
  static const _mimes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf'
  ];
  static const _extensions = ['jpg', 'png', 'webp', 'pdf'];
  bool _hovering = false;
  bool _reading = false;
  String? _lastHoverLog;

  void _log(String message) {
    if (kDebugMode) debugPrint('[SupportDrop] $message');
  }

  @override
  void initState() {
    super.initState();
    _log(
        'mounted platform=${defaultTargetPlatform.name} enabled=${widget.enabled} remaining=${widget.remaining}');
  }

  @override
  void didUpdateWidget(covariant SupportDropZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.remaining != widget.remaining) {
      _log('state enabled=${widget.enabled} remaining=${widget.remaining}');
    }
  }

  void _hover(bool value) {
    if (mounted && _hovering != value) setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) => DropRegion(
        formats: _formats,
        hitTestBehavior: HitTestBehavior.opaque,
        onDropOver: (event) {
          final accepts = widget.enabled &&
              !_reading &&
              event.session.items.length <= widget.remaining &&
              event.session.items
                  .every((item) => _formats.any(item.canProvide)) &&
              event.session.allowedOperations.contains(DropOperation.copy);
          _hover(accepts);
          final diagnostic =
              'hover accepted=$accepts enabled=${widget.enabled} reading=$_reading remaining=${widget.remaining} items=${event.session.items.length} formats=${event.session.items.map((item) => item.platformFormats).toList()} operations=${event.session.allowedOperations.map((operation) => operation.name).join(',')}';
          if (_lastHoverLog != diagnostic) {
            _lastHoverLog = diagnostic;
            _log(diagnostic);
          }
          return accepts ? DropOperation.copy : DropOperation.none;
        },
        onDropLeave: (_) => _hover(false),
        onDropEnded: (_) {
          _hover(false);
          _lastHoverLog = null;
          _log('ended');
        },
        onPerformDrop: (event) async {
          _log(
              'perform items=${event.session.items.length} enabled=${widget.enabled} reading=$_reading');
          _hover(false);
          if (!widget.enabled ||
              _reading ||
              event.session.items.length > widget.remaining) {
            return;
          }
          final reads = <Future<SupportLocalAttachment>>[];
          for (final item in event.session.items) {
            final reader = item.dataReader;
            final index = _formats.indexWhere(item.canProvide);
            if (reader == null || index < 0) {
              reads
                  .add(Future.error(const FormatException('Unavailable file')));
              continue;
            }
            final result = Completer<SupportLocalAttachment>();
            void failRead(Object error) {
              _log('read failed type=${error.runtimeType}');
              if (!result.isCompleted) result.completeError(error);
            }

            try {
              final progress = reader.getFile(_formats[index], (file) {
                try {
                  final stream = file.getStream();
                  unawaited(cacheSupportDrop(stream, file.fileName,
                          _mimes[index], _extensions[index])
                      .then(result.complete, onError: failRead));
                } catch (error) {
                  file.close();
                  failRead(error);
                }
              }, onError: failRead);
              if (progress == null && !result.isCompleted) {
                failRead(const FormatException('Unavailable file'));
              }
            } catch (error) {
              failRead(error);
            }
            bool timedOut = false;
            reads.add(result.future.timeout(const Duration(seconds: 45),
                onTimeout: () {
              timedOut = true;
              throw const FormatException('File read timed out');
            }));
            unawaited(result.future.then((file) async {
              if (timedOut) await removeSupportDrop(file);
            }, onError: (Object _) {}));
          }
          setState(() => _reading = true);
          unawaited(_receive(reads));
        },
        child: Stack(children: [
          AbsorbPointer(absorbing: _reading, child: widget.child),
          if ((_hovering && widget.enabled) || _reading)
            Positioned.fill(
                child: IgnorePointer(
                    child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: .95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_reading)
                  const CircularProgressIndicator()
                else
                  const Icon(Icons.file_upload_outlined, size: 36),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context)!.supportDropMedia,
                    textAlign: TextAlign.center),
              ])),
            ))),
        ]),
      );

  Future<void> _receive(List<Future<SupportLocalAttachment>> reads) async {
    final files = <SupportLocalAttachment>[];
    bool failed = false;
    await Future.wait(reads.map((read) async {
      try {
        files.add(await read);
      } catch (_) {
        failed = true;
      }
    }));
    if (!mounted ||
        !widget.enabled ||
        failed ||
        files.length > widget.remaining) {
      for (final file in files) {
        await removeSupportDrop(file);
      }
      if (mounted && failed) {
        showSupportFeedback(context,
            message: AppLocalizations.of(context)!.supportAttachmentError,
            type: SupportFeedbackType.error);
      }
    } else {
      _log(
          'attached count=${files.length} bytes=${files.fold<int>(0, (size, file) => size + file.size)}');
      widget.onFiles(files);
    }
    if (mounted) setState(() => _reading = false);
  }
}
