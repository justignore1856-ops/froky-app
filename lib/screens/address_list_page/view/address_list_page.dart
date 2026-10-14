import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_commerce/screens/address_list_page/model/get_address_list_model.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_snack_bar.dart';

import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/address/selected_address_hive.dart';
import '../widgets/quick_access_widget.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  int? selectedAddressId;

  late final GetAddressListBloc _bloc;

  // Active undo windows keyed by address id; the delete API fires when one
  // elapses without an undo.
  final Map<int, Timer> _undoTimers = {};

  @override
  void initState() {
    super.initState();
    _bloc = context.read<GetAddressListBloc>();
    _bloc.add(FetchUserAddressList());
  }

  void _loadSelectedAddress() {
    final selectedAddress = HiveSelectedAddressHelper.getSelectedAddress();
    setState(() {
      selectedAddressId = selectedAddress?.id;
    });
  }

  @override
  void dispose() {
    // Commit any deletes still in their undo window so leaving the page
    // doesn't silently drop them.
    for (final entry in _undoTimers.entries) {
      entry.value.cancel();
      _bloc.add(CommitRemoveAddress(addressId: entry.key));
    }
    _undoTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      title: 'My Addresses',
      showAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      body: TabletConstrainedBody(
        child: BlocConsumer<GetAddressListBloc, GetAddressListState>(
        listenWhen: (previous, current) =>
            current is GetAddressListLoaded &&
            current.isRemoveFailed &&
            (previous is! GetAddressListLoaded || !previous.isRemoveFailed),
        listener: (context, state) {
          final l10n = AppLocalizations.of(context);
          CustomSnackBar.show(
            context: context,
            message: l10n?.failedToDeleteAddress ?? 'Failed to delete address',
            type: CustomSnackBarType.error,
          );
        },
        builder: (context, state) {
          if (state is GetAddressListLoading) {
            return const CustomCircularProgressIndicator();
          } else if (state is GetAddressListLoaded) {
            return _buildAddressList(state);
          } else if (state is GetAddressListFailed) {
            return _buildErrorState(state.error);
          } else {
            return _buildEmptyState();
          }
        },
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddAddress(),
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          TablerIcons.plus,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildAddressList(GetAddressListLoaded state) {
    if (state.addressList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GetAddressListBloc>().add(FetchUserAddressList());
      },
      child: TabletPairedListView(
        padding: EdgeInsets.all(16.sp),
        itemCount: state.addressList.length,
        itemBuilder: (context, index) {
          final address = state.addressList[index];
          return _buildAddressCard(address);
        },
      ),
    );
  }

  Widget _buildAddressCard(AddressListData address) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDarkMode(context) ? Theme.of(context).colorScheme.onSecondary : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: statusIcon(
                switch (address.addressType?.toLowerCase()) {
                  'work' => AddressStatusType.work,
                  'home' => AddressStatusType.home,
                  _ => AddressStatusType.other,
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          capitalizeFirstLetter(address.addressType ?? ''),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (address.isDefaultShipping == true) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.defaultAddress ??
                                'Default',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatAddress(address),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8,),
            Container(
              height: 30,
              width: 30,
              decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle

              ),
              child: PopupMenuButton<String>(
                icon: Icon(
                  TablerIcons.dots_vertical,
                  size: 12.sp,
                  color: Colors.grey[600],
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditAddress(address);
                  } else if (value == 'delete') {
                    _showDeleteDialog(address);
                  } else if (value == 'default') {
                    _setAsDefault(address);
                  }
                },
                itemBuilder: (context) => [
                  if (address.isDefaultShipping != true)
                    PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16.sp, color: AppTheme.primaryColor),
                          SizedBox(width: 8.sp),
                          Text(AppLocalizations.of(context)!
                              .setAsDefaultAddress),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(TablerIcons.edit, size: 16.sp),
                        SizedBox(width: 8.sp),
                        Text(AppLocalizations.of(context)!.edit,),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(TablerIcons.trash, size: 16.sp, color: AppTheme.errorColor),
                        SizedBox(width: 8.sp),
                        Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.map_pin_off,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.sp),
          Text(
            AppLocalizations.of(context)!.noAddressFound,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            AppLocalizations.of(context)!.addYourFirstAddressToStart,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24.sp),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddAddress(),
            icon: Icon(TablerIcons.plus, size: 16.sp),
            label: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(l10n?.addAddress ?? 'Add Address');
                }
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            TablerIcons.alert_circle,
            size: 80.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.sp),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.somethingWentWrong ?? 'Something went wrong',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              );
            }
          ),
          SizedBox(height: 8.sp),
          Text(
            error,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.sp),
          ElevatedButton.icon(
            onPressed: () => context.read<GetAddressListBloc>().add(FetchUserAddressList()),
            icon: Icon(TablerIcons.refresh, size: 16.sp),
            label: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Text(l10n?.retry ?? 'Retry');
              }
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddAddress() async {
    await GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {
        'isEdit': false,
      },
    );
    _loadSelectedAddress();
  }

  void _navigateToEditAddress(AddressListData address) async {
    await GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {
        'isEdit': true,
        'address': address,
        'isDefaultShipping': address.isDefaultShipping ?? false,
      },
    );
    _loadSelectedAddress();
  }

  void _setAsDefault(AddressListData address) {
    if (address.id == null) return;
    final l10n = AppLocalizations.of(context);
    context
        .read<GetAddressListBloc>()
        .add(SetDefaultShippingRequest(address: address));
    CustomSnackBar.show(
      context: context,
      message: l10n?.setAsDefaultAddress ?? 'Set as default delivery address',
      type: CustomSnackBarType.success,
    );
  }

  void _showDeleteDialog(AddressListData address) {
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
              _deleteAddressWithUndo(address);
            },
            child: Text(l10n?.delete ?? 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteAddressWithUndo(AddressListData address) {
    if (address.id == null) return;
    final id = address.id!;
    final l10n = AppLocalizations.of(context);

    _bloc.add(RemoveAddressOptimistically(addressId: id));

    final controller = CustomSnackBar.show(
      context: context,
      message: l10n?.addressDeleted ?? 'Address deleted',
      type: CustomSnackBarType.success,
      duration: const Duration(hours: 1),
      actionLabel: l10n?.undo ?? 'Undo',
      onAction: () {
        _undoTimers.remove(id)?.cancel();
        _bloc.add(UndoRemoveAddress(addressId: id));
      },
    );

    _undoTimers.remove(id)?.cancel();
    _undoTimers[id] = Timer(const Duration(seconds: 3), () {
      _undoTimers.remove(id);
      controller.close();
      _bloc.add(CommitRemoveAddress(addressId: id));
    });
  }
}