/*
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../model/support_models.dart';
import 'support_attachment_view.dart';
import 'support_avatar.dart';

class SupportTimeline extends StatefulWidget {
  const SupportTimeline({
    super.key,
    required this.messages,
    required this.sessions,
    required this.hasMore,
    required this.loadingOlder,
    required this.remoteTyping,
    required this.onLoadOlder,
    required this.onRetry,
    this.footer,
    this.footerId,
  });

  final List<SupportMessage> messages;
  final List<SupportSession> sessions;
  final bool hasMore;
  final bool loadingOlder;
  final bool remoteTyping;
  final VoidCallback onLoadOlder;
  final ValueChanged<String> onRetry;
  final Widget? footer;
  final String? footerId;

  @override
  State<SupportTimeline> createState() => _SupportTimelineState();
}

class _SupportTimelineState extends State<SupportTimeline> {
  final _controller = ScrollController();
  final _messageKeys = <int, GlobalKey>{};
  bool _olderRequested = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant SupportTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadingOlder && !widget.loadingOlder) {
      _olderRequested = false;
    }
    if (!_controller.hasClients) return;
    final latestChanged = oldWidget.messages.isEmpty ||
        widget.messages.isEmpty ||
        oldWidget.messages.last.id != widget.messages.last.id;
    final nearBottom = _controller.offset < 80;
    if (latestChanged ||
        oldWidget.remoteTyping != widget.remoteTyping ||
        oldWidget.footerId != widget.footerId) {
      if (nearBottom) {
        if (_controller.offset > 0) {
          _scrollToBottom();
        }
      } else {
        final viewport = context.findRenderObject() as RenderBox?;
        if (viewport == null) return;
        final top = viewport.localToGlobal(Offset.zero).dy;
        for (final key in _messageKeys.values) {
          final box = key.currentContext?.findRenderObject() as RenderBox?;
          if (box == null || !box.attached) continue;
          final y = box.localToGlobal(Offset.zero).dy;
          if (y + box.size.height <= top || y >= top + viewport.size.height) {
            continue;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final updated =
                key.currentContext?.findRenderObject() as RenderBox?;
            if (!_controller.hasClients ||
                updated == null ||
                !updated.attached) {
              return;
            }
            final delta = updated.localToGlobal(Offset.zero).dy - y;
            _controller.jumpTo((_controller.offset - delta)
                .clamp(0, _controller.position.maxScrollExtent)
                .toDouble());
          });
          break;
        }
      }
    }
  }

  void _scrollToBottom() {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    if (!_controller.hasClients ||
        (widget.messages.isEmpty
                ? _controller.offset
                : _controller.position.maxScrollExtent - _controller.offset) >
            80 ||
        !widget.hasMore ||
        widget.loadingOlder ||
        _olderRequested) {
      return;
    }
    _olderRequested = true;
    widget.onLoadOlder();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final entries = <Widget>[];
    if (widget.hasMore) {
      entries.add(Center(
        key: const ValueKey('history'),
        child: TextButton.icon(
          onPressed: widget.loadingOlder ? null : widget.onLoadOlder,
          icon: widget.loadingOlder
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.history, size: 18),
          label: Text(strings.supportLoadOlder),
        ),
      ));
    }

    int? previousSessionId;
    DateTime? previousDate;
    for (var i = 0; i < widget.messages.length; i++) {
      final message = widget.messages[i];
      final session = _session(message.sessionId);
      if (previousSessionId != message.sessionId && session != null) {
        entries.add(KeyedSubtree(
            key: ValueKey('session-${session.id}'),
            child: _SessionDivider(session: session)));
        previousSessionId = message.sessionId;
        previousDate = null;
      }
      final date = message.createdAt;
      if (date != null &&
          (previousDate == null ||
              previousDate.year != date.year ||
              previousDate.month != date.month ||
              previousDate.day != date.day)) {
        entries.add(KeyedSubtree(
            key: ValueKey(
                'date-${message.sessionId}-${date.year}-${date.month}-${date.day}'),
            child: _DateDivider(date: date)));
        previousDate = date;
      }

      bool isContinuousWithPrevious = false;
      if (i > 0) {
        final prevMessage = widget.messages[i - 1];
        final prevDate = prevMessage.createdAt;
        final isSameSession = message.sessionId == prevMessage.sessionId;
        final isSameDay = (date == null && prevDate == null) ||
            (date != null &&
                prevDate != null &&
                date.year == prevDate.year &&
                date.month == prevDate.month &&
                date.day == prevDate.day);
        final isSameSender = message.senderRole == prevMessage.senderRole &&
            (message.type == 'auto_reply' || !message.isSystem) &&
            (prevMessage.type == 'auto_reply' || !prevMessage.isSystem);

        isContinuousWithPrevious = isSameSession && isSameDay && isSameSender;
      }

      bool isContinuousWithNext = false;
      if (i + 1 < widget.messages.length) {
        final nextMessage = widget.messages[i + 1];
        final nextDate = nextMessage.createdAt;
        final isSameSession = message.sessionId == nextMessage.sessionId;
        final isSameDay = (date == null && nextDate == null) ||
            (date != null &&
                nextDate != null &&
                date.year == nextDate.year &&
                date.month == nextDate.month &&
                date.day == nextDate.day);
        final isSameSender = message.senderRole == nextMessage.senderRole &&
            (message.type == 'auto_reply' || !message.isSystem) &&
            (nextMessage.type == 'auto_reply' || !nextMessage.isSystem);

        isContinuousWithNext = isSameSession && isSameDay && isSameSender;
      }

      entries.add(KeyedSubtree(
          key: _messageKeys.putIfAbsent(message.id, GlobalKey.new),
          child: _MessageEntry(
            message: message,
            onRetry: widget.onRetry,
            isContinuousWithNext: isContinuousWithNext,
            isContinuousWithPrevious: isContinuousWithPrevious,
          )));
    }
    if (widget.remoteTyping) {
      entries.add(
          const KeyedSubtree(key: ValueKey('typing'), child: _TypingBubble()));
    }

    if (entries.isEmpty && widget.footer == null) {
      entries.add(Center(
        key: const ValueKey('empty'),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(strings.supportNoMessages, textAlign: TextAlign.center),
        ),
      ));
    }
    if (widget.footer != null) {
      entries.add(
          KeyedSubtree(key: const ValueKey('footer'), child: widget.footer!));
    }
    final orderedEntries =
        widget.messages.isEmpty ? entries : entries.reversed.toList();
    final indices = {
      for (var i = 0; i < orderedEntries.length; i++) orderedEntries[i].key!: i
    };
    final messageIds = widget.messages.map((message) => message.id).toSet();
    _messageKeys.removeWhere((id, _) => !messageIds.contains(id));

    return Scrollbar(
      controller: _controller,
      thickness: 3,
      radius: const Radius.circular(8),
      child: ListView.builder(
        reverse: widget.messages.isNotEmpty,
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: orderedEntries.length,
        findChildIndexCallback: (key) => indices[key],
        itemBuilder: (_, index) => orderedEntries[index],
      ),
    );
  }

  SupportSession? _session(int id) {
    for (final session in widget.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }
}

class _SessionDivider extends StatelessWidget {
  const _SessionDivider({required this.session});

  final SupportSession session;

  @override
  Widget build(BuildContext context) {
    final label = [
      session.slug,
      session.topic?.title ?? session.subject,
      if (session.order != null) session.order!.number,
    ].where((value) => value.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(
            child:
                Divider(color: Theme.of(context).colorScheme.outlineVariant)),
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
            child:
                Divider(color: Theme.of(context).colorScheme.outlineVariant)),
      ]),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(DateFormat('d MMM yyyy').format(date),
              style: Theme.of(context).textTheme.labelSmall),
        ),
      );
}

class _MessageEntry extends StatelessWidget {
  const _MessageEntry({
    required this.message,
    required this.onRetry,
    this.isContinuousWithNext = false,
    this.isContinuousWithPrevious = false,
  });

  final SupportMessage message;
  final ValueChanged<String> onRetry;
  final bool isContinuousWithNext;
  final bool isContinuousWithPrevious;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem && message.type != 'auto_reply') {
      return _SystemEvent(message: message);
    }
    final customer = message.isCustomer;
    final bubbleColor = customer
        ? AppTheme.primaryColor
        : Theme.of(context).colorScheme.surfaceContainer;
    final foreground =
        customer ? Colors.black : Theme.of(context).colorScheme.onSurface;
    final senderName = message.senderName?.trim().isNotEmpty == true
        ? message.senderName!
        : customer
            ? AppLocalizations.of(context)!.supportYou
            : 'Support';

    final bubble = Flexible(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .76,
          minWidth: 64,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(customer ? 16 : 4),
            bottomRight: Radius.circular(customer ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    customer
                        ? AppLocalizations.of(context)!.supportYou
                        : (message.senderName ?? 'Support'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(alpha: .8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (message.createdAt != null)
                  Text(
                    DateFormat('h:mm a').format(message.createdAt!),
                    style: TextStyle(
                      color: foreground.withValues(alpha: .6),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
            if (message.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message.text,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
            if (message.localFiles.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...message.localFiles.map((file) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: file.isImage
                        ? InkWell(
                            onTap: () =>
                                showSupportLocalAttachment(context, file),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 240),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  width: 0.8,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(file.path),
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () =>
                                showSupportLocalAttachment(context, file),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 240),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: file.isPdf
                                          ? Colors.red.withValues(alpha: 0.12)
                                          : Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      file.isPdf
                                          ? Icons.picture_as_pdf_rounded
                                          : Icons.insert_drive_file_outlined,
                                      size: 18,
                                      color: file.isPdf
                                          ? Colors.red.shade700
                                          : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  )),
            ],
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...message.attachments.map((attachment) => Padding(
                    key: ValueKey('attachment-${attachment.id}'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SupportAttachmentView(attachment: attachment),
                  )),
            ],
            if (message.pending)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: foreground.withValues(alpha: .65),
                  ),
                ),
              ),
            if (message.failed)
              InkWell(
                onTap: message.clientMessageId == null
                    ? null
                    : () => onRetry(message.clientMessageId!),
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.supportMessageFailed,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final avatar = SupportAvatar(
      radius: 15,
      name: senderName,
      imageUrl: message.senderAvatar,
      backgroundColor: customer
          ? AppTheme.primaryColor.withValues(alpha: .2)
          : Theme.of(context).colorScheme.surfaceContainer,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isContinuousWithNext ? 3 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            customer ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: customer
            ? [bubble, const SizedBox(width: 7), avatar]
            : [avatar, const SizedBox(width: 7), bubble],
      ),
    );
  }
}


class _SystemEvent extends StatelessWidget {
  const _SystemEvent({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final closure = message.type == 'closure';
    final text = _localizedText(context);
    final color =
        closure ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant;
    final background = closure
        ? Colors.green.withValues(alpha: .08)
        : Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: .8);
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: background, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(closure ? Icons.check_circle_outline : Icons.info_outline,
              size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
              child: Text(text, style: TextStyle(fontSize: 11, color: color))),
          if (message.createdAt != null) ...[
            const SizedBox(width: 8),
            Text(DateFormat('h:mm a').format(message.createdAt!),
                style:
                    TextStyle(fontSize: 9, color: color.withValues(alpha: .7))),
          ],
        ]),
      ),
    );
  }

  String _localizedText(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final metadata = message.metadata ?? const <String, dynamic>{};
    final actorRole = metadata['actor_role']?.toString();
    final actorName = metadata['actor_name']?.toString();
    final actor = actorRole == 'customer'
        ? strings.supportYou
        : (actorName?.isNotEmpty == true ? actorName! : null);
    final action = switch (message.type) {
      'closure' => strings.supportResolved,
      'callback' when metadata['status']?.toString() == 'requested' =>
        strings.supportCallRequested,
      'callback' => strings.supportCallUpdated,
      'assignment' when metadata['agent_id'] == null =>
        strings.supportUnassigned,
      'assignment' => strings.supportAssigned,
      'status' => strings.supportStatusUpdated,
      _ => null,
    };
    if (action == null) return message.text;
    return actor == null ? action : '$action ${strings.supportBy} $actor';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          const CircleAvatar(
              radius: 15, child: Icon(Icons.support_agent, size: 16)),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(AppLocalizations.of(context)!.supportTyping,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ]),
      );
}
*/

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../model/support_models.dart';
import 'support_attachment_view.dart';

class SupportTimeline extends StatefulWidget {
  const SupportTimeline({
    super.key,
    required this.messages,
    required this.sessions,
    required this.hasMore,
    required this.loadingOlder,
    required this.remoteTyping,
    required this.onLoadOlder,
    required this.onRetry,
    this.footer,
    this.footerId,
  });

  final List<SupportMessage> messages;
  final List<SupportSession> sessions;
  final bool hasMore;
  final bool loadingOlder;
  final bool remoteTyping;
  final VoidCallback onLoadOlder;
  final ValueChanged<String> onRetry;
  final Widget? footer;
  final String? footerId;

  @override
  State<SupportTimeline> createState() => _SupportTimelineState();
}

class _SupportTimelineState extends State<SupportTimeline> {
  final _controller = ScrollController();
  final _messageKeys = <int, GlobalKey>{};
  bool _olderRequested = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant SupportTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.loadingOlder && !widget.loadingOlder) {
      _olderRequested = false;
    }

    if (!_controller.hasClients) return;

    final latestChanged = oldWidget.messages.isEmpty ||
        widget.messages.isEmpty ||
        oldWidget.messages.last.id != widget.messages.last.id;

    final nearBottom = _controller.offset < 80;

    if (latestChanged ||
        oldWidget.remoteTyping != widget.remoteTyping ||
        oldWidget.footerId != widget.footerId) {
      if (nearBottom) {
        if (_controller.offset > 0) {
          _scrollToBottom();
        }
      } else {
        final viewport = context.findRenderObject() as RenderBox?;

        if (viewport == null) return;

        final top = viewport.localToGlobal(Offset.zero).dy;

        for (final key in _messageKeys.values) {
          final box = key.currentContext?.findRenderObject() as RenderBox?;

          if (box == null || !box.attached) continue;

          final y = box.localToGlobal(Offset.zero).dy;

          if (y + box.size.height <= top || y >= top + viewport.size.height) {
            continue;
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final updated =
                key.currentContext?.findRenderObject() as RenderBox?;

            if (!_controller.hasClients ||
                updated == null ||
                !updated.attached) {
              return;
            }

            final delta = updated.localToGlobal(Offset.zero).dy - y;

            _controller.jumpTo(
              (_controller.offset - delta)
                  .clamp(
                    0,
                    _controller.position.maxScrollExtent,
                  )
                  .toDouble(),
            );
          });

          break;
        }
      }
    }
  }

  void _scrollToBottom() {
    if (!_controller.hasClients) return;

    _controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    if (!_controller.hasClients ||
        (widget.messages.isEmpty
                ? _controller.offset
                : _controller.position.maxScrollExtent - _controller.offset) >
            80 ||
        !widget.hasMore ||
        widget.loadingOlder ||
        _olderRequested) {
      return;
    }

    _olderRequested = true;
    widget.onLoadOlder();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final entries = <Widget>[];

    if (widget.hasMore) {
      entries.add(
        Center(
          key: const ValueKey('history'),
          child: TextButton.icon(
            onPressed: widget.loadingOlder ? null : widget.onLoadOlder,
            icon: widget.loadingOlder
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.history,
                    size: 18,
                  ),
            label: Text(strings.supportLoadOlder),
          ),
        ),
      );
    }

    int? previousSessionId;
    DateTime? previousDate;

    for (var i = 0; i < widget.messages.length; i++) {
      final message = widget.messages[i];
      final session = _session(message.sessionId);

      if (previousSessionId != message.sessionId && session != null) {
        entries.add(
          KeyedSubtree(
            key: ValueKey('session-${session.id}'),
            child: _SessionDivider(
              session: session,
            ),
          ),
        );

        previousSessionId = message.sessionId;
        previousDate = null;
      }

      final date = message.createdAt;

      if (date != null &&
          (previousDate == null ||
              previousDate.year != date.year ||
              previousDate.month != date.month ||
              previousDate.day != date.day)) {
        entries.add(
          KeyedSubtree(
            key: ValueKey(
              'date-${message.sessionId}-'
              '${date.year}-${date.month}-${date.day}',
            ),
            child: _DateDivider(
              date: date,
            ),
          ),
        );

        previousDate = date;
      }

      bool isContinuousWithPrevious = false;

      if (i > 0) {
        final prevMessage = widget.messages[i - 1];
        final prevDate = prevMessage.createdAt;

        final isSameSession = message.sessionId == prevMessage.sessionId;

        final isSameDay = (date == null && prevDate == null) ||
            (date != null &&
                prevDate != null &&
                date.year == prevDate.year &&
                date.month == prevDate.month &&
                date.day == prevDate.day);

        final isSameSender = message.senderRole == prevMessage.senderRole &&
            (message.type == 'auto_reply' || !message.isSystem) &&
            (prevMessage.type == 'auto_reply' || !prevMessage.isSystem);

        isContinuousWithPrevious = isSameSession && isSameDay && isSameSender;
      }

      bool isContinuousWithNext = false;

      if (i + 1 < widget.messages.length) {
        final nextMessage = widget.messages[i + 1];
        final nextDate = nextMessage.createdAt;

        final isSameSession = message.sessionId == nextMessage.sessionId;

        final isSameDay = (date == null && nextDate == null) ||
            (date != null &&
                nextDate != null &&
                date.year == nextDate.year &&
                date.month == nextDate.month &&
                date.day == nextDate.day);

        final isSameSender = message.senderRole == nextMessage.senderRole &&
            (message.type == 'auto_reply' || !message.isSystem) &&
            (nextMessage.type == 'auto_reply' || !nextMessage.isSystem);

        isContinuousWithNext = isSameSession && isSameDay && isSameSender;
      }

      entries.add(
        KeyedSubtree(
          key: _messageKeys.putIfAbsent(
            message.id,
            GlobalKey.new,
          ),
          child: _MessageEntry(
            message: message,
            onRetry: widget.onRetry,
            isContinuousWithNext: isContinuousWithNext,
            isContinuousWithPrevious: isContinuousWithPrevious,
          ),
        ),
      );
    }

    if (widget.remoteTyping) {
      entries.add(
        const KeyedSubtree(
          key: ValueKey('typing'),
          child: _TypingBubble(),
        ),
      );
    }

    if (entries.isEmpty && widget.footer == null) {
      entries.add(
        Center(
          key: const ValueKey('empty'),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              strings.supportNoMessages,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (widget.footer != null) {
      entries.add(
        KeyedSubtree(
          key: const ValueKey('footer'),
          child: widget.footer!,
        ),
      );
    }

    final orderedEntries =
        widget.messages.isEmpty ? entries : entries.reversed.toList();

    final indices = {
      for (var i = 0; i < orderedEntries.length; i++) orderedEntries[i].key!: i,
    };

    final messageIds = widget.messages.map((message) => message.id).toSet();

    _messageKeys.removeWhere(
      (id, _) => !messageIds.contains(id),
    );

    return Scrollbar(
      controller: _controller,
      thickness: 3,
      radius: const Radius.circular(8),
      child: ListView.builder(
        reverse: widget.messages.isNotEmpty,
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          22,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: orderedEntries.length,
        findChildIndexCallback: (key) => indices[key],
        itemBuilder: (_, index) => orderedEntries[index],
      ),
    );
  }

  SupportSession? _session(int id) {
    for (final session in widget.sessions) {
      if (session.id == id) {
        return session;
      }
    }

    return null;
  }
}

class _SessionDivider extends StatelessWidget {
  const _SessionDivider({
    required this.session,
  });

  final SupportSession session;

  @override
  Widget build(BuildContext context) {
    final label = [
      session.slug,
      session.topic?.title ?? session.subject,
      if (session.order != null) session.order!.number,
    ].where((value) => value.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          DateFormat('d MMM yyyy').format(date),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _MessageEntry extends StatelessWidget {
  const _MessageEntry({
    required this.message,
    required this.onRetry,
    this.isContinuousWithNext = false,
    this.isContinuousWithPrevious = false,
  });

  final SupportMessage message;
  final ValueChanged<String> onRetry;
  final bool isContinuousWithNext;
  final bool isContinuousWithPrevious;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem && message.type != 'auto_reply') {
      return _SystemEvent(message: message);
    }

    final customer = message.isCustomer;

    final bubbleColor = customer
        ? AppTheme.primaryColor
        : Theme.of(context).colorScheme.surfaceContainer;

    final foreground =
    customer ? Colors.black : Theme.of(context).colorScheme.onSurface;

    final hasTail = !isContinuousWithPrevious;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth * 0.76;

    final leftPadding = !customer && hasTail ? 16.0 : 10.0;
    final rightPadding = customer && hasTail ? 16.0 : 10.0;

    final contentMaxWidth =
        maxBubbleWidth - leftPadding - rightPadding;

    final bubble = Container(
      margin: EdgeInsets.only(
        left: (!customer && !hasTail) ? 7 : 0,
        right: (customer && !hasTail) ? 7 : 0,
      ),
      child: CustomPaint(
        painter: _WhatsAppBubblePainter(
          color: bubbleColor,
          isCustomer: customer,
          hasTail: hasTail,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            customer ? 10 : (hasTail ? 16 : 10),
            6,
            customer ? (hasTail ? 16 : 10) : 10,
            5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.text.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: contentMaxWidth,
                    ),
                    child: Text(
                      message.text,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14.5,
                        height: 1.32,
                      ),
                    ),
                  ),
                ),

              // Local attachments
              if (message.localFiles.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...message.localFiles.map(
                      (file) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: file.isImage
                        ? InkWell(
                      onTap: () => showSupportLocalAttachment(
                        context,
                        file,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.path),
                          width: 170,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                        : InkWell(
                      onTap: () => showSupportLocalAttachment(
                        context,
                        file,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            file.isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.insert_drive_file_outlined,
                            size: 20,
                            color: foreground,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: contentMaxWidth - 26,
                            ),
                            child: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: foreground,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // Remote attachments
              if (message.attachments.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...message.attachments.map(
                      (attachment) => Padding(
                    key: ValueKey(
                      'attachment-${attachment.id}',
                    ),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SupportAttachmentView(
                      attachment: attachment,
                    ),
                  ),
                ),
              ],

              // Time / status
              if (message.createdAt != null ||
                  message.pending ||
                  message.failed) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.createdAt != null)
                      Text(
                        DateFormat('h:mm a')
                            .format(message.createdAt!)
                            .toLowerCase(),
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                    if (customer && message.pending) ...[
                      const SizedBox(width: 4),
                      SizedBox.square(
                        dimension: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.2,
                          color: foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],

                    if (customer && message.failed) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: message.clientMessageId == null
                            ? null
                            : () => onRetry(
                          message.clientMessageId!,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isContinuousWithNext ? 3 : 10,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: customer
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 64,
                maxWidth: maxBubbleWidth,
              ),
              child: bubble,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppBubblePainter extends CustomPainter {
  final Color color;
  final bool isCustomer;
  final bool hasTail;
  final double radius;

  _WhatsAppBubblePainter({
    required this.color,
    required this.isCustomer,
    required this.hasTail,
    this.radius = 10.0,
  });

  Path _getPath(Size size) {
    final path = Path();

    final r = radius;
    final w = size.width;
    final h = size.height;

    if (!hasTail) {
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          Radius.circular(r),
        ),
      );

      return path;
    }

    const tw = 7.0;
    const th = 12.0;

    if (isCustomer) {
      // Customer bubble - tail on right.
      path.moveTo(r, 0);
      path.lineTo(w, 0);

      path.quadraticBezierTo(
        w - tw * 0.25,
        th * 0.35,
        w - tw,
        th,
      );

      path.lineTo(w - tw, h - r);

      path.arcToPoint(
        Offset(w - tw - r, h),
        radius: Radius.circular(r),
      );

      path.lineTo(r, h);

      path.arcToPoint(
        Offset(0, h - r),
        radius: Radius.circular(r),
      );

      path.lineTo(0, r);

      path.arcToPoint(
        Offset(r, 0),
        radius: Radius.circular(r),
      );
    } else {
      // Support bubble - tail on left.
      path.moveTo(0, 0);
      path.lineTo(w - r, 0);

      path.arcToPoint(
        Offset(w, r),
        radius: Radius.circular(r),
      );

      path.lineTo(w, h - r);

      path.arcToPoint(
        Offset(w - r, h),
        radius: Radius.circular(r),
      );

      path.lineTo(tw + r, h);

      path.arcToPoint(
        Offset(tw, h - r),
        radius: Radius.circular(r),
      );

      path.lineTo(tw, th);

      path.quadraticBezierTo(
        tw * 0.25,
        th * 0.35,
        0,
        0,
      );
    }

    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getPath(size);

    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: .06),
      1.5,
      false,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant _WhatsAppBubblePainter oldDelegate,
  ) {
    return oldDelegate.color != color ||
        oldDelegate.isCustomer != isCustomer ||
        oldDelegate.hasTail != hasTail ||
        oldDelegate.radius != radius;
  }
}

class _SystemEvent extends StatelessWidget {
  const _SystemEvent({
    required this.message,
  });

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final closure = message.type == 'closure';
    final text = _localizedText(context);

    final color =
        closure ? Colors.green : Theme.of(context).colorScheme.onSurfaceVariant;

    final background = closure
        ? Colors.green.withValues(alpha: .08)
        : Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: .8);

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              closure ? Icons.check_circle_outline : Icons.info_outline,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                ),
              ),
            ),
            if (message.createdAt != null) ...[
              const SizedBox(width: 8),
              Text(
                DateFormat('h:mm a').format(message.createdAt!),
                style: TextStyle(
                  fontSize: 9,
                  color: color.withValues(alpha: .7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _localizedText(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final metadata = message.metadata ?? const <String, dynamic>{};

    final actorRole = metadata['actor_role']?.toString();

    final actorName = metadata['actor_name']?.toString();

    final actor = actorRole == 'customer'
        ? strings.supportYou
        : (actorName?.isNotEmpty == true ? actorName! : null);

    final action = switch (message.type) {
      'closure' => strings.supportResolved,
      'callback' when metadata['status']?.toString() == 'requested' =>
        strings.supportCallRequested,
      'callback' => strings.supportCallUpdated,
      'assignment' when metadata['agent_id'] == null =>
        strings.supportUnassigned,
      'assignment' => strings.supportAssigned,
      'status' => strings.supportStatusUpdated,
      _ => null,
    };

    if (action == null) {
      return message.text;
    }

    return actor == null ? action : '$action ${strings.supportBy} $actor';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 15,
            child: Icon(
              Icons.support_agent,
              size: 16,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              AppLocalizations.of(context)!.supportTyping,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
