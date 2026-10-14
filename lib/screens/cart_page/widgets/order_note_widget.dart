import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';

class OrderNoteWidget extends StatefulWidget {
  final String? initialNote;
  final Function(String note)? onNoteChanged;
  final bool isEnabled;

  const OrderNoteWidget({
    super.key,
    this.initialNote,
    this.onNoteChanged,
    this.isEnabled = true,
  });

  @override
  State<OrderNoteWidget> createState() => _OrderNoteWidgetState();
}

class _OrderNoteWidgetState extends State<OrderNoteWidget> {
  late TextEditingController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.onNoteChanged != null) {
      widget.onNoteChanged!(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 9.h),
      decoration: BoxDecoration(
        color: isDarkMode(context)
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface,
        // borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  /*Icon(
                    TablerIcons.note,
                    size: 20.sp,
                    color: AppTheme.primaryColor,
                  ),*/
                  Image.asset('assets/images/icons/order-note.png', height: 25,),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      "Add Order Note",
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode(context) ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? TablerIcons.chevron_up : TablerIcons.chevron_down,
                    size: 20.sp,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Any special instructions for the store (e.g., delivery time, fragile items, etc.)",
                    style: AppTextStyles.label.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  CustomTextFormField(
                    controller: _controller,
                    maxLines: 4,
                    minLines: 3,
                    enabled: widget.isEnabled,
                    hintText: l10n?.writeYourNoteHere ?? "Write your note here...",
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${_controller.text.length}/300',
                      style: AppTextStyles.label.copyWith(
                        color: _controller.text.length > 300
                            ? Theme.of(context).colorScheme.error
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState:
            _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}