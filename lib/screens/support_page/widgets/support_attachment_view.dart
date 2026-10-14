import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/dependency_injection_container.dart';
import '../../../l10n/app_localizations.dart';
import '../model/support_models.dart';
import '../repo/support_repository.dart';
import 'support_feedback.dart';
import 'support_image_preview.dart';

void showSupportLocalAttachment(
    BuildContext context, SupportLocalAttachment attachment) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => attachment.isImage
        ? SupportImagePreview(
            image: FileImage(File(attachment.path)), name: attachment.name)
        : Scaffold(
            appBar: AppBar(title: Text(attachment.name)),
            body: PdfViewer.file(attachment.path),
          ),
  ));
}

class SupportAttachmentView extends StatefulWidget {
  const SupportAttachmentView({super.key, required this.attachment});

  final SupportAttachment attachment;

  @override
  State<SupportAttachmentView> createState() => _SupportAttachmentViewState();
}

class _SupportAttachmentViewState extends State<SupportAttachmentView> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(covariant SupportAttachmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id ||
        oldWidget.attachment.downloadUrl != widget.attachment.downloadUrl) {
      _loadBytes();
    }
  }

  void _loadBytes() {
    _bytes =
        getIt<SupportRepository>().getAttachment(widget.attachment.downloadUrl);
  }

  void _retryLoad() {
    setState(() {
      _bytes = getIt<SupportRepository>()
          .getAttachment(widget.attachment.downloadUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final strings = AppLocalizations.of(context)!;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final ready = snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            !snapshot.hasError;
        final bytes = ready ? snapshot.data : null;
        void preview() {
          if (bytes == null) return;
          if (attachment.isImage) {
            _showImage(context, bytes);
          } else if (attachment.isPdf) {
            _showPdf(context, bytes);
          }
        }

        if (attachment.isImage) {
          return _buildImageSection(
            context: context,
            bytes: bytes,
            ready: ready,
            hasError: snapshot.hasError,
            strings: strings,
            preview: preview,
          );
        }

        return _buildDocumentSection(
          context: context,
          bytes: bytes,
          ready: ready,
          hasError: snapshot.hasError,
          strings: strings,
          preview: preview,
        );
      },
    );
  }

  Widget _buildImageSection({
    required BuildContext context,
    required Uint8List? bytes,
    required bool ready,
    required bool hasError,
    required AppLocalizations strings,
    required VoidCallback preview,
  }) {
    if (hasError) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 32, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 6),
            Text(
              strings.supportActionFailed,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _retryLoad,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(strings.supportRetry),
            ),
          ],
        ),
      );
    }

    if (!ready || bytes == null) {
      return Container(
        width: 230,
        height: 165,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: preview,
              child: Image.memory(
                bytes,
                width: double.infinity,
                height: 155,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 155,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 36),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  Text(
                    _fileSize(widget.attachment.size),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: preview,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: Text(
                      strings.supportPreview,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _download(context, bytes),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.download_outlined, size: 14),
                    label: Text(
                      strings.supportDownload,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required BuildContext context,
    required Uint8List? bytes,
    required bool ready,
    required bool hasError,
    required AppLocalizations strings,
    required VoidCallback preview,
  }) {
    final attachment = widget.attachment;
    final isPdf = attachment.isPdf;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: bytes != null ? preview : null,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPdf
                        ? Colors.red.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.insert_drive_file_outlined,
                    color: isPdf
                        ? Colors.red.shade700
                        : Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_fileSize(attachment.size)}${isPdf ? ' • PDF' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(strings.supportActionFailed,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () => setState(_loadBytes),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  icon: const Icon(Icons.refresh, size: 15),
                  label: Text(strings.supportRetry),
                ),
              ],
            ),
          ] else if (!ready) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPdf) ...[
                  TextButton.icon(
                    onPressed: preview,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: Text(
                      strings.supportPreview,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  onPressed: () => _download(context, bytes!),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.download_outlined, size: 14),
                  label: Text(
                    strings.supportDownload,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showImage(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => SupportImagePreview(
        image: MemoryImage(bytes),
        name: widget.attachment.name,
        actions: [
          IconButton(
              onPressed: () => _share(context, bytes),
              tooltip: AppLocalizations.of(context)!.supportShare,
              icon: const Icon(Icons.ios_share_outlined)),
          IconButton(
              onPressed: () => _download(context, bytes),
              tooltip: AppLocalizations.of(context)!.supportDownload,
              icon: const Icon(Icons.download_outlined)),
        ],
      ),
    ));
  }

  void _showPdf(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(widget.attachment.name, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              onPressed: () => _share(context, bytes),
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              onPressed: () => _download(context, bytes),
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        body: PdfViewer.data(bytes, sourceName: widget.attachment.name),
      ),
    ));
  }

  Future<void> _download(BuildContext context, Uint8List bytes) async {
    try {
      await FileSaver.instance.saveFile(
        name: widget.attachment.name,
        bytes: bytes,
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: widget.attachment.mimeType,
      );
      if (!context.mounted) return;
      showSupportFeedback(
        context,
        message: AppLocalizations.of(context)!.supportDownload,
        type: SupportFeedbackType.success,
      );
    } catch (_) {
      if (!context.mounted) return;
      showSupportFeedback(
        context,
        message: AppLocalizations.of(context)!.supportActionFailed,
        type: SupportFeedbackType.error,
      );
    }
  }

  Future<void> _share(BuildContext context, Uint8List bytes) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: widget.attachment.name,
              mimeType: widget.attachment.mimeType,
            ),
          ],
          fileNameOverrides: [widget.attachment.name],
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      showSupportFeedback(
        context,
        message: AppLocalizations.of(context)!.supportActionFailed,
        type: SupportFeedbackType.error,
      );
    }
  }

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
