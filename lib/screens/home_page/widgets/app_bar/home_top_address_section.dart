import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/address/selected_address_hive.dart';
import '../../../../services/location/location_service.dart';
import '../../../../services/location/user_location_hive.dart';
import '../../../../utils/widgets/address_bottom_sheet.dart';

class HomeTopAddressSection extends StatelessWidget {
  final Color? textColor;

  const HomeTopAddressSection({
    super.key,
    required this.textColor,
  });

  /// Strips Google Plus Codes (e.g. "J675+HJ6" or "87G8H7P8+FH") from address text
  static String cleanPlusCodes(String raw) {
    if (raw.isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'\b[A-Z0-9]{2,8}\+[A-Z0-9]{2,4}\b,?\s*', caseSensitive: false), '')
        .trim();
  }

  String _resolveLabel(AppLocalizations? l10n) {
    final selected = HiveSelectedAddressHelper.getSelectedAddress();

    if (selected != null) {
      final parts = <String>[
        cleanPlusCodes(selected.addressLine1 ?? ''),
        cleanPlusCodes(selected.landmark ?? ''),
        cleanPlusCodes(selected.city ?? ''),
      ].where((e) => e.isNotEmpty).toSet().toList();

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    final location = LocationService.getStoredLocation();
    if (location != null) {
      final area = cleanPlusCodes(location.area);
      final city = cleanPlusCodes(location.city);

      // Best UX for top bar: "Area, City" (e.g. "Kartavya Path, New Delhi")
      if (area.isNotEmpty && city.isNotEmpty && area.toLowerCase() != city.toLowerCase()) {
        return '$area, $city';
      } else if (area.isNotEmpty) {
        return area;
      } else if (city.isNotEmpty) {
        final state = cleanPlusCodes(location.state);
        return (state.isNotEmpty && state.toLowerCase() != city.toLowerCase())
            ? '$city, $state'
            : city;
      }

      final cleanFull = cleanPlusCodes(location.fullAddress);
      if (cleanFull.isNotEmpty) {
        return cleanFull;
      }
    }

    return l10n?.selectDeliveryLocation ?? 'Select Delivery Location';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        HiveSelectedAddressHelper.listenable(),
        HiveLocationHelper.currentLocationListenable(),
      ]),
      builder: (context, _) {
        final label = _resolveLabel(l10n);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => AddressBottomSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TablerIcons.map_pin_filled, size: 18, color: textColor),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: textColor,
                      height: 1.1,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  TablerIcons.chevron_down,
                  size: 14,
                  color: textColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
