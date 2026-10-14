import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';
import 'package:hyper_commerce/screens/seller_page/bloc/seller_feedback/seller_feedback_bloc.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_textfield.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class SellerRatingPage extends StatefulWidget {
  final int sellerId;
  final int orderItemId;
  final String storeName;
  final int initialRating;
  final String? initialTitle;
  final String? initialComment;
  final int? feedbackId;

  const SellerRatingPage({
    super.key,
    required this.sellerId,
    required this.orderItemId,
    required this.storeName,
    this.initialRating = 0,
    this.initialTitle,
    this.initialComment,
    this.feedbackId,
  });

  @override
  State<SellerRatingPage> createState() => _SellerRatingPageState();
}

class _SellerRatingPageState extends State<SellerRatingPage> {
  late final TextEditingController _titleCtrl =
      TextEditingController(text: widget.initialTitle ?? '');
  late final TextEditingController _commentCtrl =
      TextEditingController(text: widget.initialComment ?? '');
  late int _rating = widget.initialRating;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) return;
    final bloc = context.read<SellerFeedbackBloc>();
    if (widget.feedbackId != null) {
      bloc.add(UpdateSellerFeedback(
        feedbackId: widget.feedbackId!,
        title: _titleCtrl.text.trim(),
        description: _commentCtrl.text.trim(),
        rating: _rating,
      ));
    } else {
      bloc.add(AddSellerFeedback(
        sellerId: widget.sellerId,
        orderItemId: widget.orderItemId,
        title: _titleCtrl.text.trim(),
        description: _commentCtrl.text.trim(),
        rating: _rating,
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
      title: l10n?.rateSeller ?? 'Rate seller',
      backgroundColor: scheme.surfaceContainer,
      body: TabletConstrainedBody(
        child: BlocListener<SellerFeedbackBloc, SellerFeedbackState>(
        listener: (context, state) {
          if (state is SellerFeedbackLoaded) {
            ToastManager.show(
              context: context,
              message: l10n?.feedbackSubmitted ?? 'Thanks for your feedback!',
            );
            if (context.mounted) GoRouter.of(context).pop(true);
          } else if (state is SellerFeedbackFailure) {
            ToastManager.show(
              context: context,
              message: state.error,
              type: ToastType.error,
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 22.sp, color: scheme.primary),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        widget.storeName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final filled = index < _rating;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = index + 1),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 40.sp,
                          color: filled
                              ? const Color(0xFFEEAB18)
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 20.h),
              _label(context, l10n?.title ?? 'Title'),
              SizedBox(height: 8.h),
              CustomTextFormField(
                controller: _titleCtrl,
                hintText: l10n?.titleOptional ?? 'Add a title (optional)',
              ),
              SizedBox(height: 16.h),
              _label(context, l10n?.writeAReview ?? 'Write a review (optional)'),
              SizedBox(height: 8.h),
              CustomTextFormField(
                controller: _commentCtrl,
                hintText: l10n?.describeTheIssue ?? 'Share your experience',
                minLines: 3,
                maxLines: 5,
              ),
              SizedBox(height: 24.h),
              BlocSelector<SellerFeedbackBloc, SellerFeedbackState, bool>(
                selector: (s) => s is SellerFeedbackLoading,
                builder: (context, loading) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: CustomButton(
                      text: l10n?.submitReview ?? 'Submit review',
                      onPressed: _submit,
                      isDisabled: _rating == 0,
                      isLoading: loading,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
