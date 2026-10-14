import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_commerce/config/app_colors.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_commerce/screens/wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import '../../../config/helper.dart';
import '../../../utils/money_format.dart';
import '../../../utils/widgets/price_utils.dart';

class WalletUsageWidget extends StatefulWidget {
  final bool isWalletEnabled;
  final Function(bool) onWalletToggle;
  final bool isLoading;
  final String? currencySymbol;
  final MoneyFormat? format;

  const WalletUsageWidget({
    super.key,
    required this.isWalletEnabled,
    required this.onWalletToggle,
    this.isLoading = false,
    this.currencySymbol,
    this.format,
  });

  @override
  State<WalletUsageWidget> createState() => _WalletUsageWidgetState();
}

class _WalletUsageWidgetState extends State<WalletUsageWidget> {
  double balance = 0.00;
  double remainingBalance = 0.00;
  double usedBalance = 0.00;
  @override
  Widget build(BuildContext context) {
    final currency = widget.currencySymbol ?? AppHelpers.currency;

    String formatPrice(double amount) {
      if (widget.format != null) {
        return PriceUtils.formatWithFormat(amount, widget.format!, currency);
      }
      return PriceUtils.formatWithSymbol(amount, currency);
    }

    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.colorScheme.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + title/subtitle + toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  TablerIcons.wallet,
                  color: AppTheme.primaryColor,
                  size: isTablet(context) ? 24 : 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Use wallet balance',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    BlocBuilder<UserWalletBloc, UserWalletState>(
                      builder: (context, state) {
                        if (state is UserWalletLoaded && state.userWallet.isNotEmpty) {
                          balance = double.tryParse(state.userWallet.first.balance ?? '0.00') ?? 0.00;
                        }
                        return Text(
                          '${formatPrice(balance)} available',
                          style: AppTextStyles.label.copyWith(
                            color: mutedColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              BlocBuilder<GetUserCartBloc, GetUserCartState>(
                builder: (context, state) {
                  if (state is GetUserCartLoaded) {
                    usedBalance = double.parse(state.cartData.first.data!.paymentSummary!.walletAmountUsed!.toStringAsFixed(2));
                    remainingBalance = double.parse(state.cartData.first.data!.paymentSummary!.walletBalance!.toStringAsFixed(2)) - usedBalance;
                  }

                  return (state is GetUserCartLoading || widget.isLoading)
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CustomCircularProgressIndicator(),
                        )
                      : Switch(
                          value: widget.isWalletEnabled,
                          onChanged: balance > 0.0
                              ? (value) => widget.onWalletToggle(value)
                              : (value) {},
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppTheme.primaryColor,
                        );
                },
              ),
            ],
          ),

          // Breakdown — only shown when the wallet is actually applied
          BlocBuilder<UserWalletBloc, UserWalletState>(
            builder: (context, state) {
              if (state is UserWalletLoaded && state.userWallet.isNotEmpty) {
                balance = double.tryParse(state.userWallet.first.balance ?? '0.00') ?? 0.00;

                if (balance <= 0) {
                  return Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.appColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(TablerIcons.info_circle, size: 16.r, color: context.appColors.warning),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Insufficient wallet balance',
                              style: AppTextStyles.label.copyWith(
                                color: context.appColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!widget.isWalletEnabled) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.h),
                    Divider(height: 1, color: theme.colorScheme.outline),
                    SizedBox(height: 12.h),
                    _breakdownRow(context, 'Wallet amount used',
                        '- ${formatPrice(usedBalance)}',
                        valueColor: context.appColors.success),
                    SizedBox(height: 8.h),
                    _breakdownRow(context, 'Remaining wallet balance',
                        formatPrice(remainingBalance)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }
}

