import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/config/theme.dart';

import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import '../../screens/address_list_page/model/get_address_list_model.dart';
import '../../screens/address_list_page/widgets/saved_address_list_widget.dart';
import '../../services/location/location_service.dart';
import 'custom_circular_progress_indicator.dart';
import 'custom_toast.dart';

class AddressBottomSheet extends StatefulWidget {
  const AddressBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => const AddressBottomSheet(),
    );
  }

  @override
  State<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<AddressBottomSheet> {
  int? _applyingId;
  bool _locating = false;

  bool get _isLoggedIn => Global.userData != null;

  @override
  void initState() {
    super.initState();
    if (_isLoggedIn) {
      context.read<GetAddressListBloc>().add(FetchUserAddressList());
    }
  }

  Future<void> _selectAddress(AddressListData address) async {
    setState(() => _applyingId = address.id);

    // Persist locally (selected + delivery location) and sync to backend as
    // the default shipping address — handled in GetAddressListBloc.
    context
        .read<GetAddressListBloc>()
        .add(SetDefaultShippingRequest(address: address));

    setState(() => _applyingId = null);
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();
    ToastManager.show(
      context: context,
      message:
          '${l10n?.deliverTo ?? 'Deliver to'} ${address.addressLine1 ?? address.city ?? ''}'
              .trim(),
      type: ToastType.success,
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final location = await LocationService.requestAndStoreLocationWithRetry();
    if (!mounted) return;
    setState(() => _locating = false);

    final l10n = AppLocalizations.of(context);
    if (location != null) {
      Navigator.of(context).pop();
      ToastManager.show(
        context: context,
        message: location.fullAddress.isNotEmpty
            ? '${l10n?.deliverTo ?? 'Deliver to'} ${location.fullAddress}'
            : (l10n?.useCurrentLocation ?? 'Use current location'),
        type: ToastType.success,
      );
    } else {
      ToastManager.show(
        context: context,
        message: l10n?.couldNotGetLocation ??
            "Couldn't get your current location",
        type: ToastType.error,
      );
    }
  }

  void _addNewAddress() {
    Navigator.of(context).pop();
    GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {'isEdit': false},
    );
  }

  // Opens the map picker only to pick/browse a location (not to add an address).
  void _searchLocationOnMap() {
    Navigator.of(context).pop();
    GoRouter.of(context).push(
      AppRoutes.locationPicker,
      extra: {'isFromAddressPage': false, 'isEdit': false},
    );
  }

  void _editAddress(AddressListData address) {
    Navigator.of(context).pop();
    GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {
        'isEdit': true,
        'address': address,
        'isDefaultShipping': address.isDefaultShipping ?? false,
      },
    );
  }

  void _confirmDelete(AddressListData address) {
    if (address.id == null) return;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n?.deleteAddress ?? 'Delete Address'),
        content: Text(l10n?.areYouSureYouWantToDeleteThisAddress ??
            'Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.r),
        topRight: Radius.circular(20.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Text(
                  l10n?.selectDeliveryLocation ?? 'Select Delivery Location',
                  style: AppTextStyles.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Divider(
            height: 1.h,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentLocationTile(l10n),
                  _buildSearchLocationTile(l10n),
                  if (_isLoggedIn) _buildAddNewAddressTile(l10n),
                  _buildSavedSection(l10n),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationTile(AppLocalizations? l10n) {
    return ListTile(
      onTap: _locating ? null : _useCurrentLocation,
      leading: const Icon(TablerIcons.focus_2,),
      title: Text(
        _locating
            ? (l10n?.gettingYourLocation ?? 'Getting your location…')
            : (l10n?.useCurrentLocation ?? 'Use current location'),
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        l10n?.useCurrentLocationHint ?? 'See delivery dates for your area',
        style: AppTextStyles.label.copyWith(color: Colors.grey[600]),
      ),
      trailing: _locating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CustomCircularProgressIndicator(),
            )
          : const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
    );
  }

  Widget _buildSearchLocationTile(AppLocalizations? l10n) {
    return ListTile(
      onTap: _searchLocationOnMap,
      leading:
          const Icon(Icons.travel_explore,),
      title: Text(
        l10n?.searchLocationOnMap ?? 'Search location',
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      dense: true,
    );
  }

  Widget _buildAddNewAddressTile(AppLocalizations? l10n) {
    return ListTile(
      onTap: _addNewAddress,
      leading: const Icon(TablerIcons.plus,),
      title: Text(
        l10n?.addNewAddress ?? 'Add New Address',
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      dense: true,
    );
  }

  Widget _buildSavedSection(AppLocalizations? l10n) {
    if (!_isLoggedIn) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        child: Text(
          l10n?.loginToSaveAddress ?? 'Sign in to save and pick addresses.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
        ),
      );
    }

    return BlocBuilder<GetAddressListBloc, GetAddressListState>(
      builder: (context, state) {
        if (state is GetAddressListLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CustomCircularProgressIndicator()),
          );
        }

        if (state is GetAddressListFailed) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            child: Text(
              state.error,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),
          );
        }

        if (state is GetAddressListLoaded) {
          if (state.addressList.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              child: Text(
                l10n?.noSavedAddresses ?? 'No saved addresses yet.',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                child: Text(
                  l10n?.savedAddresses ?? 'Saved Addresses',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                itemCount: state.addressList.length,
                itemBuilder: (context, index) =>
                    _buildAddressCard(state.addressList[index]),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAddressCard(AddressListData address) {
    final l10n = AppLocalizations.of(context);
    final isApplying = _applyingId == address.id;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: InkWell(
        onTap: _applyingId == null ? () => _selectAddress(address) : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: isDarkMode(context)
                ? Theme.of(context).colorScheme.onSecondary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: statusIcon(
                  switch (address.addressType?.toLowerCase()) {
                    'work' => AddressStatusType.work,
                    'home' => AddressStatusType.home,
                    _ => AddressStatusType.other,
                  },
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
                            capitalizeFirstLetter(address.addressType ?? ''),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (address.isDefaultShipping == true) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              l10n?.defaultAddress ?? 'Default',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      formatAddress(address),
                      style: AppTextStyles.label.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isApplying)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CustomCircularProgressIndicator(),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: Icon(
                    TablerIcons.dots_vertical,
                    size: 18.sp,
                    color: Colors.grey[600],
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editAddress(address);
                    } else if (value == 'delete') {
                      _confirmDelete(address);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(TablerIcons.edit, size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(l10n?.edit ?? 'Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(TablerIcons.trash,
                              size: 16.sp,
                              color: Theme.of(context).colorScheme.error),
                          SizedBox(width: 8.w),
                          Text(
                            l10n?.delete ?? 'Delete',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
