import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/product_detail_page/bloc/product_feedback/product_feedback_bloc.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_image_container.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/dashed_container.dart';

import '../../../config/theme.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class ProductRatingPage extends StatefulWidget {
  final int orderItemId;
  final String? productName;
  final String? variantTitle;
  final String? image;
  final int initialRating;
  final String? initialTitle;
  final String? initialComment;
  final int? feedbackId;

  const ProductRatingPage({
    super.key,
    required this.orderItemId,
    this.productName,
    this.variantTitle,
    this.image,
    this.initialRating = 0,
    this.initialTitle,
    this.initialComment,
    this.feedbackId,
  });

  @override
  State<ProductRatingPage> createState() => _ProductRatingPageState();
}

class _ProductRatingPageState extends State<ProductRatingPage> {
  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.initialTitle ?? '');
  late final TextEditingController _reviewCtrl =
      TextEditingController(text: widget.initialComment ?? '');
  final List<XFile> _images = [];
  static const int _maxImages = 5;
  late int _rating = widget.initialRating;

  static const Color _starColor = AppTheme.ratingStarColor;

  bool get _canSubmit =>
      _rating > 0 && _titleCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reviewCtrl.dispose();
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
    if (!_canSubmit) return;
    final bloc = context.read<ProductFeedbackBloc>();
    if (widget.feedbackId != null) {
      bloc.add(UpdateProductFeedback(
        feedbackId: widget.feedbackId!,
        title: _titleCtrl.text.trim(),
        description: _reviewCtrl.text.trim(),
        rating: _rating,
        images: _images,
      ));
    } else {
      bloc.add(AddProductFeedback(
        orderItemId: widget.orderItemId,
        title: _titleCtrl.text.trim(),
        description: _reviewCtrl.text.trim(),
        rating: _rating,
        images: _images,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return CustomScaffold(
      showViewCart: false,
      showAppBar: true,
      title: 'Share your experience',
      backgroundColor: scheme.surface,
      body: TabletConstrainedBody(
        child: BlocListener<ProductFeedbackBloc, ProductFeedbackState>(
        listener: (context, state) {
          if (state is ProductFeedbackLoaded) {
            context.read<ProductFeedbackBloc>().add(ResetProductFeedback());
            ToastManager.show(
              context: context,
              message: l10n?.feedbackSubmitted ?? 'Thanks for your feedback!',
            );
            if (context.mounted) GoRouter.of(context).pop(true);
          } else if (state is ProductFeedbackFailure) {
            context.read<ProductFeedbackBloc>().add(ResetProductFeedback());
            ToastManager.show(
              context: context,
              message: state.error,
              type: ToastType.error,
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(scheme, l10n),
              SizedBox(height: 16.h),
              _starsRow(l10n),
              SizedBox(height: 20.h),
              _sectionTitle(scheme, l10n?.writeAReviewLabel ?? 'Write a review'),
              SizedBox(height: 10.h),
              CustomTextFormField(
                controller: _reviewCtrl,
                hintText:
                    l10n?.whatShouldOthersKnow ?? 'What should other customers know?',
                minLines: 6,
                maxLines: 8,
              ),
              SizedBox(height: 22.h),
              _sectionTitle(scheme, l10n?.addPhotos ?? 'Add photos'),
              SizedBox(height: 10.h),
              _photoSection(scheme, l10n),
              SizedBox(height: 22.h),
              _titleLabel(scheme, l10n),
              SizedBox(height: 10.h),
              CustomTextFormField(
                controller: _titleCtrl,
                hintText:
                    l10n?.titleReviewHint ?? "What's most important to know?",
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 36.h),
              SizedBox(
                width: double.infinity,
                child: BlocSelector<ProductFeedbackBloc, ProductFeedbackState,
                    bool>(
                  selector: (s) => s is ProductFeedbackLoading,
                  builder: (context, loading) {
                    return CustomButton(
                      text: l10n?.submit ?? 'Submit',
                      onPressed: _submit,
                      isDisabled: !_canSubmit,
                      isLoading: loading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _header(ColorScheme scheme, AppLocalizations? l10n) {
    final image = widget.image;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: (image != null && image.isNotEmpty)
              ? CustomImageContainer(imagePath: image, fit: BoxFit.cover)
              : Icon(Icons.image_outlined,
                  size: 24.sp, color: Colors.grey.shade400),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.howWasTheItem ?? 'How was the item?',
                style: AppTextStyles.titleLarge.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                widget.productName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _starsRow(AppLocalizations? l10n) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final filled = index < _rating;
            return GestureDetector(
              onTap: () => setState(() => _rating = index + 1),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Icon(
                  filled ? AppTheme.ratingStarIconFilled : AppTheme.ratingStarIcon,
                  size: 30.sp,
                  color: filled ? _starColor : _starColor,
                ),
              ),
            );
          }),
        ),
        const Spacer(),
        if (_rating > 0)
          GestureDetector(
            onTap: () => setState(() => _rating = 0),
            behavior: HitTestBehavior.opaque,
            child: Text(
              l10n?.clear ?? 'Clear',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF007185),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(ColorScheme scheme, String text) {
    return Text(
      text,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
  }

  Widget _titleLabel(ColorScheme scheme, AppLocalizations? l10n) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n?.titleYourReview ?? 'Title your review',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          TextSpan(
            text: ' ${l10n?.requiredLabel ?? '(required)'}',
            style: AppTextStyles.body.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoSection(ColorScheme scheme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty) ...[
          SizedBox(
            height: 66.w,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.file(
                        File(_images[i].path),
                        width: 66.w,
                        height: 66.w,
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
                          child: Icon(Icons.close,
                              size: 12.sp, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
        ],
        if (_images.length < _maxImages)
          GestureDetector(
            onTap: _pickImages,
            behavior: HitTestBehavior.opaque,
            child: DashedContainer(
              radius: 10.r,
              strokeWidth: 1.4,
              dashWidth: 6,
              dashGap: 4,
              color: Colors.grey.shade400,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Icon(Icons.add_a_photo_outlined,
                        size: 26.sp, color: scheme.onSurface),
                  ),
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFEAF6FB),
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                    child: Text(
                      l10n?.addPhotosHint ?? 'Tap to add photos',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
