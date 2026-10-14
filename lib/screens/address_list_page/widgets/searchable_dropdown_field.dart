import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';

import '../../../l10n/app_localizations.dart';

class SearchableDropdownField<T> extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final String? Function()? validator;
  final VoidCallback onTap;
  final bool enabled;
  final IconData? prefixIcon;
  final bool loading;

  const SearchableDropdownField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.hint,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showValue = (value ?? '').isNotEmpty;
    return FormField<String>(
      validator: (_) => validator?.call(),
      builder: (fieldState) {
        return GestureDetector(
          onTap: enabled && !loading ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: InputDecorator(
            isEmpty: !showValue,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              errorText: fieldState.errorText,
              filled: true,
              fillColor: enabled
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surface.withValues(alpha: 0.6),
              contentPadding: EdgeInsets.symmetric(
                vertical: 14.h,
                horizontal: 8.w,
              ),
              labelStyle: AppTextStyles.body.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4))
                  : null,
              suffixIcon: loading
                  ? Padding(
                      padding: EdgeInsets.all(12.sp),
                      child: SizedBox(
                        width: 18.sp,
                        height: 18.sp,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Text(
              showValue ? value! : (hint ?? ''),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w400,
                color: showValue
                    ? theme.colorScheme.onSurface
                    : Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

class DropdownPickerOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const DropdownPickerOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class DropdownPickerPage<T> {
  final List<DropdownPickerOption<T>> options;
  final bool hasMore;

  const DropdownPickerPage({required this.options, this.hasMore = false});
}

Future<T?> showSearchablePickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<DropdownPickerOption<T>> Function(String query) itemsBuilder,
  bool remoteSearch = false,
  Future<DropdownPickerPage<T>> Function(String query, int page)?
      remotePagedBuilder,
  String? initialQuery,
  String? emptyLabel,
  String? searchHint,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return _SearchableDropdownSheet<T>(
        title: title,
        itemsBuilder: itemsBuilder,
        remoteSearch: remoteSearch,
        remotePagedBuilder: remotePagedBuilder,
        initialQuery: initialQuery,
        emptyLabel: emptyLabel,
        searchHint: searchHint,
      );
    },
  );
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  final String title;
  final List<DropdownPickerOption<T>> Function(String query) itemsBuilder;
  final bool remoteSearch;
  final Future<DropdownPickerPage<T>> Function(String query, int page)?
      remotePagedBuilder;
  final String? initialQuery;
  final String? emptyLabel;
  final String? searchHint;

  const _SearchableDropdownSheet({
    required this.title,
    required this.itemsBuilder,
    required this.remoteSearch,
    required this.remotePagedBuilder,
    required this.initialQuery,
    required this.emptyLabel,
    required this.searchHint,
  });

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<DropdownPickerOption<T>> _items = const [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  int _requestId = 0;

  bool get _paged => widget.remotePagedBuilder != null;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _refresh(_controller.text);
    _controller.addListener(() => _refresh(_controller.text));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_paged || _loading || _loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _refresh(String query) async {
    if (_paged) {
      final current = ++_requestId;
      setState(() {
        _loading = true;
        _loadingMore = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted || current != _requestId) return;
      try {
        final result = await widget.remotePagedBuilder!(query, 1);
        if (!mounted || current != _requestId) return;
        setState(() {
          _items = result.options;
          _hasMore = result.hasMore;
          _page = 1;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || current != _requestId) return;
        setState(() {
          _items = const [];
          _hasMore = false;
          _loading = false;
        });
      }
      return;
    }

    if (!widget.remoteSearch) {
      setState(() {
        _items = widget.itemsBuilder(query);
        _loading = false;
      });
      return;
    }
    final current = ++_requestId;
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || current != _requestId) return;
    try {
      final results = widget.itemsBuilder(query);
      if (!mounted || current != _requestId) return;
      setState(() {
        _items = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || current != _requestId) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final current = _requestId;
    final nextPage = _page + 1;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.remotePagedBuilder!(_controller.text, nextPage);
      if (!mounted || current != _requestId) return;
      setState(() {
        _items = [..._items, ...result.options];
        _hasMore = result.hasMore;
        _page = nextPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || current != _requestId) return;
      setState(() {
        _hasMore = false;
        _loadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 4.h),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  top: 8.h, left: 16.w, right: 8.w, bottom: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w400),
                decoration: InputDecoration(
                  hintText: widget.searchHint ?? l10n?.search ?? 'Search',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  prefixIcon:
                      Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded,
                              size: 18.sp,
                              color: colorScheme.onSurfaceVariant),
                          onPressed: () => _controller.clear(),
                        ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainer,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1.2),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Flexible(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.sp),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 40.sp,
                                    color: colorScheme.onSurfaceVariant),
                                SizedBox(height: 8.h),
                                Text(
                                  widget.emptyLabel ??
                                      l10n?.somethingWentWrong ??
                                      'No results',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildItemsList(colorScheme),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(ColorScheme colorScheme) {
    final hasFooter = _paged && _hasMore;
    return ListView.separated(
      controller: _scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 8.h),
      itemCount: _items.length + (hasFooter ? 1 : 0),
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      itemBuilder: (ctx, i) {
        if (i >= _items.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        }
        final item = _items[i];
        return ListTile(
          title: Text(
            item.label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: item.subtitle == null
              ? null
              : Text(
                  item.subtitle!,
                  style: AppTextStyles.label.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.primaryColor,
            size: 18.sp,
          ),
          onTap: () => Navigator.of(context).pop(item.value),
        );
      },
    );
  }
}
