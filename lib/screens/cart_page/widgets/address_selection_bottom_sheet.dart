import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_commerce/screens/address_list_page/model/get_address_list_model.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../utils/widgets/custom_toast.dart';
import 'delivery_address_widget.dart';

class AddressSelectionBottomSheet extends StatefulWidget {
  final Function(AddressListData) onAddressSelected;
  final AddressListData? selectedAddress;
  final int? deliveryZoneId;

  const AddressSelectionBottomSheet({
    super.key,
    required this.onAddressSelected,
    this.selectedAddress,
    this.deliveryZoneId,
  });

  @override
  State<AddressSelectionBottomSheet> createState() => _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState extends State<AddressSelectionBottomSheet> {
  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  void _fetchAddresses() {
    context.read<GetAddressListBloc>().add(FetchUserAddressList(deliveryZoneId: widget.deliveryZoneId));
  }

  Future<void> _openAddNewAddress() async {
    await GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {'isEdit': false, 'deliveryZoneId': widget.deliveryZoneId},
    );
    if (!mounted) return;
    _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(theme),
            _buildHeader(theme),
            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline),
            _buildAddNewAddressButton(theme),
            Flexible(
              child: BlocBuilder<GetAddressListBloc, GetAddressListState>(
                builder: (context, state) {
                  if (state is GetAddressListLoading) {
                    return _buildLoadingState(theme);
                  } else if (state is GetAddressListLoaded) {
                    return _buildAddressList(theme, state);
                  } else if (state is GetAddressListFailed) {
                    return _buildErrorState(theme);
                  }
                  return _buildLoadingState(theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.selectDeliveryAddress ?? 'Select Delivery Address',
              style: AppTextStyles.titleLarge.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).closeButtonTooltip,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  TablerIcons.x,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 18.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewAddressButton(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: InkWell(
        onTap: _openAddNewAddress,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(TablerIcons.plus, color: Colors.white, size: 16.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.addNewAddress ?? 'Add New Address',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
              Icon(
                TablerIcons.chevron_right,
                size: 20.sp,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(ThemeData theme, GetAddressListLoaded state) {
    if (state.addressList.isEmpty) {
      return _buildEmptyState(theme);
    }

    final addresses = _sortedAddresses(state.addressList);

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      itemCount: addresses.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) => _buildAddressCard(theme, addresses[index]),
    );
  }

  List<AddressListData> _sortedAddresses(List<AddressListData> list) {
    final sorted = List<AddressListData>.from(list);
    sorted.sort((a, b) {
      final aSelected = widget.selectedAddress?.id == a.id;
      final bSelected = widget.selectedAddress?.id == b.id;
      if (aSelected != bSelected) return aSelected ? -1 : 1;
      final aDefault = a.isDefaultShipping == true;
      final bDefault = b.isDefaultShipping == true;
      if (aDefault != bDefault) return aDefault ? -1 : 1;
      return 0;
    });
    return sorted;
  }

  Widget _buildAddressCard(ThemeData theme, AddressListData address) {
    final isSelected = widget.selectedAddress?.id == address.id;
    final accentColor = isSelected ? AppTheme.primaryColor : theme.colorScheme.onSecondaryContainer;

    return GestureDetector(
      onTap: () {
        widget.onAddressSelected(address);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : theme.colorScheme.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _iconForType(address.addressType),
                size: isTablet(context) ? 22.sp : 18.sp,
                color: accentColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _addressTypeLabel(context, address.addressType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                      if (address.isDefaultShipping == true) ...[
                        SizedBox(width: 8.w),
                        _defaultBadge(context),
                      ],
                      if (isSelected) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          TablerIcons.circle_check_filled,
                          size: isTablet(context) ? 18.sp : 15.sp,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    formatAddressFromModel(address),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      height: 1.35,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  if (address.landmark?.trim().isNotEmpty == true) ...[
                    SizedBox(height: 4.h),
                    _iconLine(
                      theme,
                      TablerIcons.map_2,
                      address.landmark!.trim(),
                    ),
                  ],
                  if (address.mobile?.trim().isNotEmpty == true) ...[
                    SizedBox(height: 6.h),
                    _iconLine(
                      theme,
                      TablerIcons.phone,
                      address.mobile!.trim(),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 4.w),
            _buildActionsMenu(theme, address),
          ],
        ),
      ),
    );
  }

  Widget _iconLine(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: isTablet(context) ? 16.sp : 13.sp, color: theme.colorScheme.onSecondaryContainer),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(ThemeData theme, AddressListData address) {
    final l10n = AppLocalizations.of(context);
    final isDefault = address.isDefaultShipping == true;

    return PopupMenuButton<String>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      padding: EdgeInsets.zero,
      offset: Offset(0, 36.h),
      color: theme.colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      icon: Icon(
        TablerIcons.dots_vertical,
        size: 18.sp,
        color: theme.colorScheme.onSecondaryContainer,
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editAddress(address);
            break;
          case 'default':
            _setAsDefault(address);
            break;
          case 'delete':
            _confirmDelete(address);
            break;
        }
      },
      itemBuilder: (context) => [
        _menuItem(theme, 'edit', TablerIcons.edit, l10n?.edit ?? 'Edit'),
        if (!isDefault)
          _menuItem(theme, 'default', TablerIcons.circle_check,
              l10n?.setAsDefaultAddress ?? 'Set as default'),
        _menuItem(theme, 'delete', TablerIcons.trash, l10n?.delete ?? 'Delete',
            danger: true),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    ThemeData theme,
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger ? theme.colorScheme.error : theme.colorScheme.tertiary;
    return PopupMenuItem<String>(
      value: value,
      height: 44.h,
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 12.w),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editAddress(AddressListData address) async {
    await GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {
        'isEdit': true,
        'address': address,
        'isDefaultShipping': address.isDefaultShipping ?? false,
        'deliveryZoneId': widget.deliveryZoneId,
      },
    );
    if (!mounted) return;
    _fetchAddresses();
  }

  void _setAsDefault(AddressListData address) {
    if (address.id == null) return;
    final l10n = AppLocalizations.of(context);
    // Mark this address as the default shipping address (updates the list + API).
    context.read<GetAddressListBloc>().add(SetDefaultShippingRequest(address: address));
    // Also select it for the current cart / place-order flow so the newly
    // defaulted address is the one actually used when placing the order.
    widget.onAddressSelected(address);
    ToastManager.show(
      context: context,
      message: l10n?.setAsDefaultAddress ?? 'Set as default delivery address',
      type: ToastType.success,
    );
    // Close the sheet, mirroring the tap-to-select behaviour, so the cart
    // immediately reflects the newly selected delivery address.
    Navigator.pop(context);
  }

  void _confirmDelete(AddressListData address) {
    if (address.id == null) return;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          l10n?.deleteAddress ?? 'Delete Address',
          style: AppTextStyles.titleLarge.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
        content: Text(
          l10n?.areYouSureYouWantToDeleteThisAddress ??
              'Are you sure you want to delete this address?',
          style: AppTextStyles.body.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: TextStyle(color: theme.colorScheme.tertiary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context
                  .read<GetAddressListBloc>()
                  .add(RemoveAddressRequest(addressId: address.id!));
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        AppLocalizations.of(context)?.defaultAddress ?? 'Default',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    final baseColor = isDarkMode(context)
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.outlineVariant;
    final highlightColor = isDarkMode(context)
        ? theme.colorScheme.onSecondary
        : theme.colorScheme.surfaceContainer;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: 96.h,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return _buildMessageState(
      theme: theme,
      icon: TablerIcons.alert_triangle,
      iconColor: AppTheme.errorColor,
      title: l10n?.somethingWentWrong ?? 'Something went wrong',
      subtitle: l10n?.tryAgain ?? 'Please try again',
      buttonLabel: l10n?.retry ?? 'Retry',
      buttonIcon: TablerIcons.refresh,
      onPressed: _fetchAddresses,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return _buildMessageState(
      theme: theme,
      icon: TablerIcons.map_pin_off,
      iconColor: theme.colorScheme.onSecondaryContainer,
      title: l10n?.noSavedAddresses ?? 'No saved addresses yet.',
      subtitle: l10n?.addAddressToContinue ?? 'Add an address to continue',
      buttonLabel: l10n?.addNewAddress ?? 'Add New Address',
      buttonIcon: TablerIcons.plus,
      onPressed: _openAddNewAddress,
    );
  }

  Widget _buildMessageState({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40.sp, color: iconColor),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.tertiary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon, size: 18.sp),
            label: Text(
              buttonLabel,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'home':
        return TablerIcons.home;
      case 'work':
      case 'office':
        return TablerIcons.building_skyscraper;
      default:
        return TablerIcons.map_pin;
    }
  }

  String _addressTypeLabel(BuildContext context, String? type) {
    final l10n = AppLocalizations.of(context);
    switch (type?.toLowerCase()) {
      case 'home':
        return l10n?.home ?? 'Home';
      case 'work':
        return l10n?.work ?? 'Work';
      case 'office':
        return l10n?.office ?? 'Office';
      case 'other':
        return l10n?.other ?? 'Other';
      default:
        return (type?.trim().isNotEmpty == true)
            ? capitalizeFirstLetter(type!.trim())
            : (l10n?.other ?? 'Other');
    }
  }
}
