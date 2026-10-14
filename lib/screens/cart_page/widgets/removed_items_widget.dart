import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/utils/widgets/custom_dotted_divider.dart';
import '../model/get_cart_model.dart';

class RemovedItemsWidget extends StatelessWidget {
  final List<RemovedItem> removedItems;
  final String title;

  const RemovedItemsWidget({
    super.key,
    required this.removedItems,
    this.title = "Not deliverable to this location.",
  });

  @override
  Widget build(BuildContext context) {
    if (removedItems.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Removed Items"
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.trash_off,
                  size: 20.r,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Text(
                  '${removedItems.length} item${removedItems.length > 1 ? 's' : ''}',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Dotted divider
          buildDottedLine(context),

          // List of removed items (disabled style)
          ...removedItems.map((item) => _buildRemovedItem(context, item)),
        ],
      ),
    );
  }

  Widget _buildRemovedItem(BuildContext context, RemovedItem item) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),

            SizedBox(width: 12.w),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.productName ?? 'Unknown Product',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.storeName ?? '',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),

                ],
              ),
            ),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }
}