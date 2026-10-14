import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../../../l10n/app_localizations.dart';

class SupportImagePreview extends StatefulWidget {
  const SupportImagePreview(
      {super.key,
      required this.image,
      required this.name,
      this.actions = const []});
  final ImageProvider image;
  final String name;
  final List<Widget> actions;

  @override
  State<SupportImagePreview> createState() => _SupportImagePreviewState();
}

class _SupportImagePreviewState extends State<SupportImagePreview> {
  final _controller = PhotoViewController();
  double? _initialScale;
  StreamSubscription<PhotoViewControllerValue>? _scaleSubscription;

  @override
  void initState() {
    super.initState();
    _scaleSubscription = _controller.outputStateStream.listen((value) {
      if (value.scale != null && value.scale! > 0) {
        _initialScale ??= value.scale;
      }
    });
  }

  void _zoom(double factor) {
    final scale = _controller.scale;
    if (scale == null) return;
    _initialScale ??= scale;
    _controller.scale =
        (scale * factor).clamp(_initialScale!, _initialScale! * 5);
  }

  @override
  void dispose() {
    _scaleSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.name, overflow: TextOverflow.ellipsis),
        actions: widget.actions,
      ),
      body: PhotoView(
        imageProvider: widget.image,
        controller: _controller,
        minScale: PhotoViewComputedScale.contained,
        initialScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.contained * 5,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        errorBuilder: (_, __, ___) => Center(
            child: Text(strings.supportActionFailed,
                style: const TextStyle(color: Colors.white))),
      ),
      bottomNavigationBar: SafeArea(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              tooltip: strings.supportZoomOut,
              color: Colors.white,
              onPressed: () => _zoom(1 / 1.5),
              icon: const Icon(Icons.zoom_out)),
          IconButton(
              tooltip: strings.supportZoomReset,
              color: Colors.white,
              onPressed: () {
                _controller.scale = _initialScale;
                _controller.position = Offset.zero;
              },
              icon: const Icon(Icons.fit_screen)),
          IconButton(
              tooltip: strings.supportZoomIn,
              color: Colors.white,
              onPressed: () => _zoom(1.5),
              icon: const Icon(Icons.zoom_in)),
        ],
      )),
    );
  }
}
