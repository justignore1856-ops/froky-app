import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import '../bloc/return_order_item/return_order_item_bloc.dart';
import '../model/order_detail_model.dart';

/// Reason codes that make the remark + at least one photo mandatory.
const Set<String> _kCriticalReturnReasons = {
  'damaged',
  'defective',
  'wrong_item',
  'not_as_described',
};

/// Minimal bottom sheet to raise a return request for a single order item.
class ReturnItemBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required OrderItems item,
    required String orderSlug,
  }) {
    final bloc = context.read<ReturnOrderItemBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReturnItemSheet(item: item, bloc: bloc),
    );
  }
}

class _ReturnItemSheet extends StatefulWidget {
  final OrderItems item;
  final ReturnOrderItemBloc bloc;

  const _ReturnItemSheet({required this.item, required this.bloc});

  @override
  State<_ReturnItemSheet> createState() => _ReturnItemSheetState();
}

class _ReturnItemSheetState extends State<_ReturnItemSheet> {
  final TextEditingController _remarkCtrl = TextEditingController();
  final List<XFile> _images = [];
  static const int _maxImages = 5;
  String? _selectedReason;
  bool _submitting = false;
  int _qty = 1;

  int get _maxReturnable {
    final r = widget.item.returnableQuantity ?? widget.item.quantity ?? 1;
    return r < 1 ? 1 : r;
  }

  Map<String, String> get _reasons =>
      SettingsData.instance.system?.returnReasonEnum ?? const {};

  bool get _isCritical =>
      _selectedReason != null && _kCriticalReturnReasons.contains(_selectedReason);

  bool get _canSubmit {
    if (_submitting) return false;
    if (_selectedReason == null) return false;
    if (_isCritical && _remarkCtrl.text.trim().isEmpty) return false;
    if (_isCritical && _images.isEmpty) return false;
    return true;
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _images.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() => _images.addAll(picked.take(remaining)));
  }

  void _submit() {
    if (!_canSubmit || widget.item.id == null) return;
    setState(() => _submitting = true);
    widget.bloc.add(ReturnOrderItemRequest(
      orderItemId: widget.item.id!,
      reason: _selectedReason!,
      remark: _remarkCtrl.text.trim(),
      quantity: _qty,
      images: _images,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 14.h),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    l10n?.returnButton ?? 'Return',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(Icons.close_rounded,
                          size: 20.sp, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _itemRow(scheme),
              SizedBox(height: 18.h),

              if (_maxReturnable > 1) ...[
                _qtyStepper(scheme, l10n),
                SizedBox(height: 16.h),
              ],

              // Reason (always required)
              _fieldLabel(
                l10n?.reasonForReturn ?? 'Reason for return',
                required: true,
                l10n: l10n,
              ),
              SizedBox(height: 8.h),
              _reasonDropdown(scheme, l10n),
              SizedBox(height: 16.h),

              // Remark (required only for critical reasons)
              _fieldLabel(
                l10n?.remark ?? 'Remark',
                required: _isCritical,
                l10n: l10n,
              ),
              SizedBox(height: 8.h),
              CustomTextFormField(
                controller: _remarkCtrl,
                hintText: l10n?.describeTheIssue ?? 'Describe the issue',
                minLines: 3,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 16.h),

              // Photos (required only for critical reasons)
              _fieldLabel(
                l10n?.photos ?? 'Photos',
                required: _isCritical,
                l10n: l10n,
              ),
              SizedBox(height: 8.h),
              _photosRow(scheme),
              SizedBox(height: 20.h),

              SizedBox(
                width: double.infinity,
                height: 35.h,
                child: CustomButton(
                  text: l10n?.submitReturn ?? 'Submit return',
                  onPressed: _submit,
                  isDisabled: !_canSubmit,
                  isLoading: _submitting,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text,
      {required bool required, AppLocalizations? l10n}) {
    return Row(
      children: [
        Text(
          text,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          required ? '*' : '(${l10n?.optional ?? 'optional'})',
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w500,
            color: required
                ? Theme.of(context).colorScheme.error
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _reasonDropdown(ColorScheme scheme, AppLocalizations? l10n) {
    final entries = _reasons.entries.toList();
    return DropdownButtonFormField<String>(
      initialValue: _selectedReason,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
      hint: Text(
        l10n?.selectReason ?? 'Select a reason',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade400),
      ),
      style: AppTextStyles.bodySmall.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        for (final e in entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() => _selectedReason = v),
    );
  }

  Widget _qtyStepper(ColorScheme scheme, AppLocalizations? l10n) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.quantity ?? 'Quantity',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                l10n?.returnUpTo(_maxReturnable) ??
                    'You can return up to $_maxReturnable',
                style: AppTextStyles.label.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        _stepBtn(Icons.remove_rounded, _qty > 1,
            () => setState(() => _qty--)),
        Container(
          width: 44.w,
          alignment: Alignment.center,
          child: Text(
            '$_qty',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        _stepBtn(Icons.add_rounded, _qty < _maxReturnable,
            () => setState(() => _qty++)),
      ],
    );
  }

  Widget _stepBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 32.w,
        height: 32.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: enabled ? Colors.black : Colors.grey.shade500,
          ),
        ),
        child: Icon(icon,
            size: 18.sp, color: enabled ? Colors.black : Colors.grey.shade500),
      ),
    );
  }

  Widget _itemRow(ColorScheme scheme) {
    final image = (widget.item.variant?.image?.isNotEmpty ?? false)
        ? widget.item.variant!.image!
        : (widget.item.product?.image ?? '');
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: image.isNotEmpty
              ? CustomImageContainer(imagePath: image, fit: BoxFit.cover)
              : Icon(Icons.image_outlined,
                  size: 20.sp, color: Colors.grey.shade400),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title ?? widget.item.product?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              if ((widget.item.variantTitle ?? '').isNotEmpty)
                Text(
                  widget.item.variantTitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photosRow(ColorScheme scheme) {
    return SizedBox(
      height: 60.w,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int i = 0; i < _images.length; i++)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(
                      File(_images[i].path),
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2.w,
                    top: 2.w,
                    child: InkWell(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(2.w),
                        child:
                            Icon(Icons.close, size: 12.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_images.length < _maxImages)
            InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    size: 20.sp, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }
}
