import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../address_list_page/model/get_address_list_model.dart';

class DeliveryAddressWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final AddressListData? selectedAddress;

  const DeliveryAddressWidget({
    super.key,
    this.onTap,
    this.selectedAddress,
  });

  @override
  State<DeliveryAddressWidget> createState() => _DeliveryAddressWidgetState();
}

class _DeliveryAddressWidgetState extends State<DeliveryAddressWidget> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final displayAddress = widget.selectedAddress != null
        ? formatAddressFromModel(widget.selectedAddress!)
        : null;
    final addressType = widget.selectedAddress?.addressType;
    final deliverToLabel = (addressType != null && addressType.trim().isNotEmpty)
        ? '${l10n?.deliverTo ?? 'Deliver to'} · $addressType'
        : (l10n?.deliverTo ?? 'Deliver to');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            // Location pin icon
            Icon(
              TablerIcons.map_pin_filled,
              size: 20.r,
            ),
            const SizedBox(width: 12),
            // Address content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliverToLabel,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    displayAddress ?? '',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.tertiary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 15),
            // Change button
            GestureDetector(
              onTap: widget.onTap,
              child: Text(
                l10n?.change ?? 'Change',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


String formatAddressFromModel(AddressListData address) {
  List<String> addressParts = [];

  if (address.addressLine1?.isNotEmpty == true) {
    addressParts.add(address.addressLine1!);
  }
  if (address.addressLine2?.isNotEmpty == true) {
    addressParts.add(address.addressLine2!);
  }
  if (address.city?.isNotEmpty == true) {
    addressParts.add(address.city!);
  }
  if (address.state?.isNotEmpty == true) {
    addressParts.add(address.state!);
  }
  if (address.zipcode?.isNotEmpty == true) {
    addressParts.add(address.zipcode!);
  }
  if (address.country?.isNotEmpty == true) {
    addressParts.add(address.country!);
  }

  return addressParts.join(', ');
}