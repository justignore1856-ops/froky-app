import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/dependency_injection_container.dart';
import '../../../config/settings_data_instance.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../bloc/support_bloc.dart';
import '../model/support_models.dart';
import '../service/support_route_presence.dart';
import '../widgets/support_attachment_view.dart';
import '../widgets/support_drop_zone.dart';
import '../widgets/support_avatar.dart';
import '../widgets/support_feedback.dart';
import '../widgets/support_timeline.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key, this.initialOrderId, this.ticketSlug});

  final int? initialOrderId;
  final String? ticketSlug;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<SupportBloc>()
          ..add(SupportStarted(initialOrderId: initialOrderId)),
        child: const _SupportView(),
      );
}

class _SupportView extends StatefulWidget {
  const _SupportView();

  @override
  State<_SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<_SupportView>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _showOlderOrders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SupportRoutePresence.visible = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SupportBloc>().add(const SupportAppResumed());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      context.read<SupportBloc>().add(const SupportAppPaused());
    }
  }

  @override
  void dispose() {
    SupportRoutePresence.visible = false;
    SupportRoutePresence.threadUuid = null;
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupportBloc, SupportState>(
      listenWhen: (previous, current) =>
          previous.notice != current.notice ||
          previous.error != current.error ||
          previous.draft != current.draft ||
          previous.thread?.uuid != current.thread?.uuid,
      listener: (context, state) {
        SupportRoutePresence.threadUuid = state.thread?.uuid;
        if (state.draft.isEmpty && _messageController.text.isNotEmpty) {
          _messageController.clear();
        }
        if (state.notice?.isNotEmpty == true) {
          final message = state.notice!;
          context.read<SupportBloc>().add(const SupportFeedbackConsumed());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showSupportFeedback(
              context,
              message: message,
              type: SupportFeedbackType.success,
            );
          });
        } else if (state.error?.isNotEmpty == true) {
          final message = state.error!;
          context.read<SupportBloc>().add(const SupportFeedbackConsumed());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showSupportFeedback(
              context,
              message: message,
              type: SupportFeedbackType.error,
            );
          });
        }
      },
      builder: (context, state) => CustomScaffold(
        showViewCart: false,
        showAppBar: false,
        notifyConnectivityStatusOnInit: true,
        onConnectivityChanged: (connected, _) {
          context
              .read<SupportBloc>()
              .add(SupportConnectivityChanged(connected));
        },
        body: SupportDropZone(
            enabled: !state.sending &&
                (state.hasActiveSession ||
                    (state.flowOpen && state.selectedTopicId != null)),
            remaining: 5 - state.attachments.length,
            onFiles: (files) => context
                .read<SupportBloc>()
                .add(SupportAttachmentsSelected(files)),
            child: SafeArea(
              child: Column(
                children: [
                  _Header(
                    state: state,
                    onRefresh: () => context
                        .read<SupportBloc>()
                        .add(const SupportRefreshRequested()),
                    onContact: () => _showContactSheet(context),
                    onCallback: state.hasActiveSession
                        ? () => _confirmCallback(context)
                        : null,
                    onResolve: state.hasActiveSession
                        ? () => _confirmResolve(context)
                        : null,
                  ),
                  const Divider(height: 1),
                  Expanded(child: _body(context, state)),
                  _bottomArea(context, state),
                ],
              ),
            )),
      ),
    );
  }

  Widget _body(BuildContext context, SupportState state) {
    final strings = AppLocalizations.of(context)!;
    if (state.status == SupportLoadStatus.loading ||
        state.status == SupportLoadStatus.initial) {
      return const _LoadingState();
    }
    if (state.status == SupportLoadStatus.failed && state.payload == null) {
      return _ErrorState(
        text: strings.supportFailed,
        onRetry: () =>
            context.read<SupportBloc>().add(const SupportRefreshRequested()),
      );
    }
    final footer = _timelineFooter(context, state);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<SupportBloc>().add(const SupportRefreshRequested());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SupportTimeline(
          key: ValueKey(state.thread?.id),
          messages: state.messages,
          sessions: state.thread?.sessions ?? const [],
          hasMore: state.hasMoreMessages,
          loadingOlder: state.loadingOlder,
          remoteTyping: state.remoteTyping,
          footer: footer,
          footerId: _timelineFooterId(state),
          onLoadOlder: () =>
              context.read<SupportBloc>().add(const SupportLoadOlderRequested()),
          onRetry: (clientId) => context
              .read<SupportBloc>()
              .add(SupportRetryMessageRequested(clientId)),
        ),
      ),
    );
  }

  Widget _bottomArea(BuildContext context, SupportState state) {
    if (state.status != SupportLoadStatus.loaded) {
      return const SizedBox.shrink();
    }
    if (state.hasActiveSession) return _composer(context, state);
    return const SizedBox.shrink();
  }

  Widget? _timelineFooter(BuildContext context, SupportState state) {
    final active = state.activeSession;
    if (active != null) {
      return active.assigneeId == null
          ? _ExecutiveNotice(
              text: AppLocalizations.of(context)!.supportExecutive,
            )
          : null;
    }
    return state.flowOpen
        ? _guidedFlow(context, state)
        : _resolvedArea(context, state);
  }

  String? _timelineFooterId(SupportState state) {
    final active = state.activeSession;
    if (active != null) {
      return active.assigneeId == null ? 'unassigned-${active.id}' : null;
    }
    if (!state.flowOpen) return 'resolved-${state.latestSession?.id}';
    return 'flow-${state.orderSelectionMade}-${state.selectedTopicId}';
  }

  Widget _composer(BuildContext context, SupportState state) {
    final replies =
        state.activeSession?.topic?.quickReplies ?? const <String>[];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 0.h),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replies.isNotEmpty)
              _QuickReplies(
                replies: replies,
                onTap: (reply) => _setDraft(context, reply),
              ),
            _SelectedAttachments(
              attachments: state.attachments,
              onRemove: (path) => context
                  .read<SupportBloc>()
                  .add(SupportAttachmentRemoved(path)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _messageField(context, state)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageField(BuildContext context, SupportState state) {
    final isSending = state.sending;
    final hasText = _messageController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 46,
                maxHeight: 130,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !isSending,
                minLines: 1,
                maxLines: 8,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                cursorColor: Theme.of(context).colorScheme.tertiary,
                onChanged: (value) {
                  context
                      .read<SupportBloc>()
                      .add(SupportDraftChanged(value));

                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText:
                  AppLocalizations.of(context)!.supportMessagePlaceholder,
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '',
                  prefixIcon: IconButton(
                    tooltip: AppLocalizations.of(context)!.supportAttach,
                    onPressed: state.sending
                        ? null
                        : () => _pickAttachments(context, state),
                    icon: const Icon(Icons.attach_file, size: 21, color: Colors.grey,),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Camera',
                    onPressed: state.sending
                        ? null
                        : () => _pickFromCamera(context, state),
                    icon: const Icon(Icons.camera_alt_outlined, size: 21, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
            ),
            child: IconButton(
              onPressed: state.sending ||
                  (state.draft.trim().isEmpty &&
                      state.attachments.isEmpty)
                  ? null
                  : () => context
                  .read<SupportBloc>()
                  .add(const SupportSendRequested()),
              icon: isSending
                  ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.send_rounded),
              color: hasText && !isSending
                  ? Colors.black
                  : Colors.red,
              iconSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guidedFlow(BuildContext context, SupportState state) {
    final strings = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (state.orderSelectionMade)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: state.sending
                      ? null
                      : () => context
                          .read<SupportBloc>()
                          .add(const SupportFlowBackRequested()),
                  icon: const BackButtonIcon(),
                ),
              Expanded(
                child: Text(
                  strings.supportWelcome,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (state.thread?.sessions.isNotEmpty == true)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => context
                      .read<SupportBloc>()
                      .add(const SupportFlowClosed()),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.supportWelcomeDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          if (!state.orderSelectionMade)
            _orderStep(context, state)
          else
            _topicStep(context, state),
        ],
      ),
    );
  }

  Widget _orderStep(BuildContext context, SupportState state) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.supportSelectOrder,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...state.payload!.recentOrders.take(_showOlderOrders ? 20 : 5).map(
              (order) => _OrderChoice(
                order: order,
                onTap: () => context
                    .read<SupportBloc>()
                    .add(SupportOrderSelected(order.id)),
              ),
            ),
        if (state.payload!.recentOrders.length > 5 && !_showOlderOrders)
          TextButton.icon(
            onPressed: () => setState(() => _showOlderOrders = true),
            icon: const Icon(Icons.history, size: 18),
            label: Text(strings.supportOlderOrders),
          ),
        OutlinedButton.icon(
          onPressed: () =>
              context.read<SupportBloc>().add(const SupportOrderSelected(null)),
          icon: const Icon(Icons.help_outline, size: 19),
          label: Text(strings.supportGeneralHelp),
        ),
      ],
    );
  }

  Widget _topicStep(BuildContext context, SupportState state) {
    final strings = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.supportSelectTopic,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.visibleTopics
              .map(
                (topic) => ChoiceChip(
                  label: Text(topic.title),
                  selected: topic.id == state.selectedTopicId,
                  onSelected: (_) => context
                      .read<SupportBloc>()
                      .add(SupportTopicSelected(topic.id)),
                ),
              )
              .toList(),
        ),
        if (state.selectedTopic != null) ...[
          if (state.selectedTopic!.guidance?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                state.selectedTopic!.guidance!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 4),
          if (state.selectedTopic!.quickReplies.isNotEmpty)
            _QuickReplies(
              replies: state.selectedTopic!.quickReplies,
              onTap: (reply) => _setDraft(context, reply),
            ),
          _SelectedAttachments(
            attachments: state.attachments,
            onRemove: (path) =>
                context.read<SupportBloc>().add(SupportAttachmentRemoved(path)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _messageField(context, state)),
            ],
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            onPressed: state.canStartSession
                ? () => context
                    .read<SupportBloc>()
                    .add(const SupportStartSessionRequested())
                : null,
            icon: state.sending
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(strings.supportStartChat),
          ),
        ],
      ],
    );
  }

  Widget _resolvedArea(BuildContext context, SupportState state) {
    final strings = AppLocalizations.of(context)!;
    final latest = state.latestSession;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (latest?.resolutionSummary?.trim().isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.task_alt_rounded,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(latest!.resolutionSummary!)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (latest != null && latest.rating == null) ...[
            Text(
              strings.supportRate,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final score = index + 1;
                return IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: score <= state.ratingScore
                        ? AppTheme.ratingStarColor.withValues(alpha: .12)
                        : Colors.transparent,
                  ),
                  onPressed: () => context
                      .read<SupportBloc>()
                      .add(SupportRatingScoreChanged(score)),
                  icon: Icon(
                    score <= state.ratingScore
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppTheme.ratingStarColor,
                    size: 30,
                  ),
                );
              }),
            ),
            TextField(
              controller: _feedbackController,
              minLines: 2,
              maxLines: 3,
              maxLength: 2000,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                maxLength,
              }) =>
                  null,
              onChanged: (value) => context
                  .read<SupportBloc>()
                  .add(SupportRatingFeedbackChanged(value)),
              decoration: InputDecoration(hintText: strings.supportFeedback),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: state.ratingScore > 0 && !state.submittingRating
                    ? () => context
                        .read<SupportBloc>()
                        .add(const SupportRatingSubmitted())
                    : null,
                icon: state.submittingRating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.star_rounded, size: 19),
                label: Text(strings.supportSubmitRating),
              ),
            ),
            const SizedBox(height: 10),
          ] else if (latest?.rating != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(strings.supportThanks),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.supportStillIssue,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      strings.supportNewChatHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                ),
                onPressed: () =>
                    context.read<SupportBloc>().add(const SupportFlowOpened()),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(strings.supportChatWithUs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setDraft(BuildContext context, String value) {
    _messageController.text = value;
    _messageController.selection =
        TextSelection.collapsed(offset: value.length);
    context.read<SupportBloc>().add(SupportDraftChanged(value));
  }

  Future<void> _pickAttachments(
    BuildContext context,
    SupportState state,
  ) async {
    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (pickedFiles.isEmpty || !context.mounted) return;
    final files = <SupportLocalAttachment>[];
    var invalid = false;
    for (final file in pickedFiles) {
      final path = file.path;
      final extension = file.extension?.toLowerCase();
      final size = await file.length();
      if (path == null ||
          size > 10 * 1024 * 1024 ||
          files.length + state.attachments.length >= 5) {
        invalid = true;
        continue;
      }
      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => '',
      };
      if (mime.isEmpty || !File(path).existsSync()) {
        invalid = true;
        continue;
      }
      files.add(
        SupportLocalAttachment(
          path: path,
          name: file.name,
          size: size,
          mimeType: mime,
        ),
      );
    }
    if (files.isNotEmpty && context.mounted) {
      context.read<SupportBloc>().add(SupportAttachmentsSelected(files));
    }
    if (invalid && context.mounted) {
      showSupportFeedback(
        context,
        message: AppLocalizations.of(context)!.supportAttachmentError,
        type: SupportFeedbackType.warning,
      );
    }
  }

  Future<void> _pickFromCamera(
    BuildContext context,
    SupportState state,
  ) async {
    if (state.attachments.length >= 5) {
      showSupportFeedback(
        context,
        message: AppLocalizations.of(context)!.supportAttachmentError,
        type: SupportFeedbackType.warning,
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo == null || !context.mounted) return;

      final file = File(photo.path);
      if (!file.existsSync()) return;

      final size = await file.length();
      if (size > 10 * 1024 * 1024) {
        if (context.mounted) {
          showSupportFeedback(
            context,
            message: AppLocalizations.of(context)!.supportAttachmentError,
            type: SupportFeedbackType.warning,
          );
        }
        return;
      }

      final name = photo.name.isNotEmpty
          ? photo.name
          : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final extension = name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      final attachment = SupportLocalAttachment(
        path: photo.path,
        name: name,
        size: size,
        mimeType: mime,
        temporary: true,
      );

      if (context.mounted) {
        context
            .read<SupportBloc>()
            .add(SupportAttachmentsSelected([attachment]));
      }
    } catch (e) {
      if (context.mounted) {
        showSupportFeedback(
          context,
          message: AppLocalizations.of(context)!.supportAttachmentError,
          type: SupportFeedbackType.warning,
        );
      }
    }
  }

  Future<void> _confirmResolve(BuildContext context) async {
    final strings = AppLocalizations.of(context)!;
    var summary = '';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.supportResolveTitle,
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(strings.supportResolveBody),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => summary = value,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(hintText: strings.supportFeedback),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: Text(strings.supportKeepChatting),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(strings.supportConfirmResolve),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<SupportBloc>()
          .add(SupportResolveRequested(summary: summary));
    }
  }

  Future<void> _confirmCallback(BuildContext context) async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_callback_outlined,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.supportCallback,
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(strings.supportCallbackBody),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(sheetContext, true),
              icon: const Icon(Icons.phone_callback_outlined),
              label: Text(strings.supportRequestCallback),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<SupportBloc>().add(const SupportCallbackRequested());
    }
  }

  void _showContactSheet(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final phone = SettingsData.instance.web?.supportNumber ?? '';
    final email = SettingsData.instance.web?.supportEmail ?? '';
    if (phone.trim().isEmpty && email.trim().isEmpty) {
      showSupportFeedback(
        context,
        message: strings.supportActionFailed,
        type: SupportFeedbackType.warning,
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.supportContact,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (phone.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const CircleAvatar(child: Icon(Icons.phone_outlined)),
                  title: Text(strings.supportCall),
                  subtitle: Text(phone),
                  onTap: () => launchUrl(
                    Uri.parse('tel:$phone'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              if (email.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const CircleAvatar(child: Icon(Icons.email_outlined)),
                  title: Text(strings.supportEmail),
                  subtitle: Text(email),
                  onTap: () => launchUrl(
                    Uri.parse('mailto:$email?subject=Support Request'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.onContact,
    required this.onRefresh,
    this.onCallback,
    this.onResolve,
  });

  final SupportState state;
  final VoidCallback onContact;
  final VoidCallback onRefresh;
  final VoidCallback? onCallback;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final session = state.activeSession ?? state.latestSession;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              SupportAvatar(
                radius: 19,
                name: session?.assigneeName ?? strings.supportTitle,
                imageUrl: session?.assigneeAvatar,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: .13),
                foregroundColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.assigneeName ?? strings.supportTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      session == null
                          ? strings.supportAssistant
                          : '${session.slug} · ${session.topic?.title ?? session.subject}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                icon: const Icon(Icons.more_vert, size: 22),
                onSelected: (action) {
                  switch (action) {
                    case 'refresh':
                      onRefresh();
                    case 'callback':
                      onCallback?.call();
                    case 'resolve':
                      onResolve?.call();
                    case 'contact':
                      onContact();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'refresh',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.refresh),
                      title: Text(strings.refresh),
                    ),
                  ),
                  if (onCallback != null)
                    PopupMenuItem(
                      value: 'callback',
                      enabled: !state.requestingCallback,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.phone_callback_outlined),
                        title: Text(strings.supportRequestCallback),
                      ),
                    ),
                  if (onResolve != null)
                    PopupMenuItem(
                      value: 'resolve',
                      enabled: !state.resolving,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(strings.supportResolve),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'contact',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.contact_support_outlined),
                      title: Text(strings.supportContact),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.mode, required this.compact});

  final SupportConnectionMode mode;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final (label, color) = switch (mode) {
      SupportConnectionMode.live => (
          'WS · ${strings.supportLive}',
          Colors.green,
        ),
      SupportConnectionMode.polling => (
          'API · ${strings.supportPolling}',
          Colors.orange,
        ),
      SupportConnectionMode.offline => (
          strings.supportOffline,
          Colors.red,
        ),
    };
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: compact ? 8 : 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExecutiveNotice extends StatelessWidget {
  const _ExecutiveNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: .22),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 15,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 11))),
          ],
        ),
      );
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.replies, required this.onTap});

  final List<String> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemCount: replies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, index) => ActionChip(
            visualDensity: VisualDensity.compact,
            label: Text(replies[index], maxLines: 1),
            onPressed: () => onTap(replies[index]),
          ),
        ),
      );
}

class _SelectedAttachments extends StatelessWidget {
  const _SelectedAttachments({
    required this.attachments,
    required this.onRemove,
  });

  final List<SupportLocalAttachment> attachments;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final file = attachments[index];
          return Container(
            width: 210,
            padding: const EdgeInsets.fromLTRB(8, 5, 3, 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  file.isImage
                      ? Icons.image_outlined
                      : Icons.picture_as_pdf_outlined,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.supportPreview,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showSupportLocalAttachment(context, file),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.supportRemove,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRemove(file.path),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderChoice extends StatelessWidget {
  const _OrderChoice({required this.order, required this.onTap});

  final SupportOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 7),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: .12),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppTheme.primaryColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.number,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${order.status.replaceAll('_', ' ')} · ${order.currencyCode} ${order.total.toStringAsFixed(2)}${order.createdAt == null ? '' : ' · ${DateFormat('d MMM').format(order.createdAt!)}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: 6,
        itemBuilder: (_, index) => Align(
          alignment:
              index.isEven ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width:
                MediaQuery.sizeOf(context).width * (index.isEven ? .58 : .46),
            height: 58,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, size: 48),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.supportRetry),
              ),
            ],
          ),
        ),
      );
}
