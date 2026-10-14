import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/l10n/app_localizations.dart';

class OrderAddressCard extends StatelessWidget {
  final String mobile;
  final String address;

  const OrderAddressCard({
    super.key,
    required this.mobile,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detail(
            context,
            title: l10n?.contactDetails ?? 'Contact details',
            subtitle: mobile,
            icon: HeroiconsSolid.phone
          ),
          Divider(height: 22.h, color: Colors.grey.withValues(alpha: 0.2)),
          _detail(
            context,
            title: l10n?.deliveryAddress ?? 'Delivery address',
            subtitle: address,
            icon: HeroiconsSolid.mapPin
          ),
        ],
      ),
    );
  }

  Widget _detail(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 18, color: Colors.black87,),
        ),
        const SizedBox(width: 12,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle.trim().isEmpty ? '-' : subtitle,
                style: AppTextStyles.label.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
