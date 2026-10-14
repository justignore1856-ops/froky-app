import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../config/helper.dart';
import '../../../../l10n/app_localizations.dart';

class BackToTopButton extends StatelessWidget {
  final ValueListenable<bool> isVisibleListenable;
  final VoidCallback onTap;
  final double topOffset;

  BackToTopButton({
    super.key,
    required this.isVisibleListenable,
    required this.onTap,
    this.topOffset = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<bool>(
        valueListenable: isVisibleListenable,
        builder: (context, showBackToTop, child) {
          return AnimatedSlide(
            duration: Duration(milliseconds: showBackToTop ? 220 : 180),
            curve: showBackToTop ? Curves.easeOutCubic : Curves.easeInCubic,
            offset: showBackToTop
                ? const Offset(0, 0.25)
                : const Offset(0, -1.2),
            child: IgnorePointer(
              ignoring: !showBackToTop,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: showBackToTop ? 1.0 : 0.0,
                child: child,
              ),
            ),
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode(context)
                        ? Colors.black.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: isDarkMode(context) ? 10 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(20.r),
                color: isDarkMode(context) ? Colors.white : Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.backToTop,
                    style: TextStyle(
                      color: isDarkMode(context)
                          ? Colors.black
                          : Colors.white,
                      fontSize: 12.sp,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCircleArrowUp02,
                    size: 16.sp,
                    color:
                        isDarkMode(context) ? Colors.black : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
