import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_commerce/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_commerce/config/app_text_styles.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/config/theme.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/clear_cart/clear_cart_bloc.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_bloc.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_event.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/update_item_quantity/update_item_quantity_bloc.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/update_item_quantity/update_item_quantity_event.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/update_item_quantity/update_item_quantity_state.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/remove_item_from_cart/remove_item_from_cart_state.dart';
import 'package:hyper_commerce/screens/cart_page/widgets/bill_summary_widget.dart';
import 'package:hyper_commerce/screens/cart_page/widgets/delivery_address_widget.dart';
import 'package:hyper_commerce/screens/cart_page/widgets/address_selection_bottom_sheet.dart';
import 'package:hyper_commerce/screens/product_detail_page/widgets/product_detail_shimmer.dart';
import 'package:hyper_commerce/utils/widgets/custom_button.dart';
import 'package:hyper_commerce/utils/widgets/price_utils.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import '../../../bloc/user_cart_bloc/user_cart_state.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../services/address/selected_address_hive.dart';
import '../../../services/market/market_service.dart';
import '../../../services/user_cart/cart_validation.dart';
import '../../../utils/widgets/whole_page_progress.dart';
import '../../../l10n/app_localizations.dart';
import '../../payment_options/bloc/payment_bloc.dart';
import '../../payment_options/bloc/payment_state.dart';
import '../../product_detail_page/bloc/similar_product_bloc/similar_product_bloc.dart';
import '../../address_list_page/model/get_address_list_model.dart';
import '../../address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import '../../wallet_page/bloc/user_wallet/user_wallet_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_bloc.dart';
import '../../save_for_later_page/bloc/save_for_later_bloc/save_for_later_state.dart';
import '../../../router/app_routes.dart';
import '../bloc/attachment/attachment_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_bloc.dart';
import '../bloc/cart_ui_bloc/cart_ui_event.dart';
import '../bloc/get_user_cart/get_user_cart_bloc.dart';
import '../bloc/promo_code/promo_code_bloc.dart';
import '../bloc/promo_code/promo_code_event.dart';
import '../bloc/promo_code/promo_code_state.dart';
import '../bloc/clear_cart/clear_cart_state.dart';
import '../model/get_cart_model.dart';
import '../widgets/cart_product_item.dart';
import '../widgets/delivery_type_widget.dart';
import '../widgets/order_note_widget.dart';
import '../widgets/removed_items_widget.dart';
import '../widgets/trust_section_widget.dart';
import '../widgets/you_might_also_like_product_widget.dart';
import 'package:hyper_commerce/utils/widgets/tablet_constrained_body.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  AddressListData? selectedAddress;
  double totalAmount = 0.0;
  String? selectedPaymentMethod;
  dynamic selectedPaymentMethodType;
  bool isCartLoading = true;
  bool _isInitialFetch = true;
  bool isClearingCart = false;
  bool isWholePageProgress = false;
  DeliveryType selectedDeliveryType = DeliveryType.regular;
  int? cartId;
  late bool _userWantsWallet = false;
  List<CartModel> stateData = [];
  int? addressId;
  int? previousAddressId;
  bool _didFetchAddressList = false;
  String? promoCode;
  String orderNote = '';

  @override
  void initState() {
    super.initState();
    isCartLoading = true;
    _isInitialFetch = true;
    _userWantsWallet = false;
    context.read<GetUserCartBloc>().add(FetchUserCart());
    context.read<SettingsBloc>().add(FetchSettingsData(context: context));
    context.read<SimilarProductBloc>().add(FetchSimilarProduct(
        excludeProductSlug: context.read<GetUserCartBloc>().productSlug)
    );
    context.read<PromoCodeBloc>().add(RemovePromoCode());
    context.read<UserWalletBloc>().add(FetchUserWallet());
    context.read<AttachmentBloc>().add(ClearAllAttachments());
  }

  bool get canUseWallet {
    final settingsState = context.read<SettingsBloc>().state;
    return settingsState is SettingsLoaded &&
        (SettingsData.instance.payment?.wallet ?? false);
  }
  bool get effectiveUseWallet => canUseWallet && _userWantsWallet;

  void _refreshCart({bool resetWalletPreference = false}) {
    if (resetWalletPreference) {
      _userWantsWallet = false;
    }

    context.read<GetUserCartBloc>().add(
      FetchUserCart(
        addressId: selectedAddress?.id,
        useWallet: effectiveUseWallet,
        promoCode: promoCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (BuildContext context, PaymentState state) {
        return Stack(
          children: [
            CustomScaffold(
                showViewCart: false,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                title: l10n?.shoppingBag ?? 'Shopping Bag',
                appBarActions: [
                  BlocBuilder<GetUserCartBloc, GetUserCartState>(
                    builder: (BuildContext context, GetUserCartState state) {
                      if(state is GetUserCartLoaded && state.cartData.isNotEmpty){
                        stateData = state.cartData;
                      } else if (state is GetUserCartEmpty) {
                        stateData = [];
                      }
                      final hasItems = stateData.isNotEmpty &&
                          (stateData.first.data?.items.isNotEmpty ?? false);

                      if(!_isInitialFetch && hasItems) {
                        return Container(
                          padding: const EdgeInsets.only(right: 10),
                          child: IconButton(
                              onPressed: () async {
                                GoRouter.of(context).push(AppRoutes.wishlistPage);
                              },

                              icon: const Icon(TablerIcons.heart)
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
                showAppBar: true,
                body: TabletConstrainedBody(
        child: MultiBlocListener(
                  listeners: [
                    BlocListener<SettingsBloc, SettingsState>(
                      listener: (context, settingsState) {
                        if(settingsState is SettingsLoaded) {
                          final walletAllowed = SettingsData.instance.payment?.wallet ?? false;
                          if (!walletAllowed && _userWantsWallet) {
                            setState(() {
                              _userWantsWallet = false;
                            });

                            // Refresh cart immediately with wallet off
                            _refreshCart();
                          }
                        }
                      },
                    ),
                    BlocListener<GetAddressListBloc, GetAddressListState>(
                      listener: (context, addressState) {
                        // Auto-select first address when addresses are loaded
                        if (addressState is GetAddressListLoaded &&
                            selectedAddress == null &&
                            addressState.addressList.isNotEmpty) {
                          setState(() {
                            selectedAddress = addressState.addressList.first;
                            isCartLoading = true;
                          });
                          // Save selected address to Hive
                          HiveSelectedAddressHelper.setSelectedAddress(addressState.addressList.first);
                          // Update cart with selected address
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode
                          ));
                        }
                      },
                    ),
                    BlocListener<GetUserCartBloc, GetUserCartState>(
                      listener: (context, state) {
                        if(state is GetUserCartLoaded) {
                          final apiAddressId = state.cartData.isNotEmpty
                              ? state.cartData.first.data?.addressId ?? ''
                              : '';

                          final int? newAddressId = apiAddressId.isNotEmpty
                              ? int.tryParse(apiAddressId)
                              : null;

                          setState(() {
                            isCartLoading = false;
                            _isInitialFetch = false;
                            stateData = state.cartData;
                            if (state.cartData.isNotEmpty) {
                              addressId = newAddressId;
                            }
                          });

                          if (state.cartData.isNotEmpty) {
                            final bool isFirstLoad = !_didFetchAddressList;
                            final bool addressChanged =
                                newAddressId != previousAddressId;
                            if (isFirstLoad || addressChanged) {
                              _didFetchAddressList = true;
                              previousAddressId = newAddressId;
                              context.read<GetAddressListBloc>().add(
                                FetchUserAddressList(
                                    deliveryZoneId: newAddressId),
                              );
                            }
                          }
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                        }
                        else if(state is GetUserCartEmpty) {
                          setState(() {
                            isCartLoading = false;
                            _isInitialFetch = false;
                            stateData = [];
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                        }
                        else if(state is GetUserCartLoading) {
                          setState(() {
                            isCartLoading = true;
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                        }
                        else if(state is GetUserCartFailed) {
                          setState(() {
                            isCartLoading = false;
                            _isInitialFetch = false;
                            stateData = [];
                          });
                          context.read<CartUIBloc>().add(SetWalletLoading(false));
                        }
                      }
                    ),
                    BlocListener<RemoveItemFromCartBloc, RemoveItemFromCartState>(
                      listener: (context, state){
                        if(state is RemoveItemFromCartLoading){
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if(state is RemoveItemFromCartSuccess){
                          // Keep loading true, will be set to false when cart loads
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode
                          ));
                        }
                        if(state is RemoveItemFromCartFailed) {
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                      },
                    ),
                    BlocListener<ClearCartBloc, ClearCartState>(
                      listener: (context, state) {
                        if(state is ClearCartLoading) {
                          setState(() {
                            isCartLoading = true;
                            isClearingCart = true;
                          });
                        } else if(state is ClearCartSuccess || state is ClearCartFailed) {
                          setState(() {
                            isCartLoading = false;
                            isClearingCart = false;
                          });
                        }
                      },
                    ),
                    BlocListener<SaveForLaterBloc, SaveForLaterState>(
                      listener: (context, state) {
                        if(state is SaveForLaterLoading) {
                          setState(() {
                            isCartLoading = true;
                          });
                        } else if(state is ProductSavedSuccess) {
                          // Cart will be refreshed automatically
                          setState(() {
                            isCartLoading = false;
                          });

                          ToastManager.show(
                              context: context,
                              message: '${state.productName} is saved for later'
                          );
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode
                          ));
                        } else if(state is SaveForLaterFailed) {
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                      },
                    ),
                    BlocListener<UpdateItemQuantityBloc, UpdateItemQuantityState>(
                      listener: (context, state){
                        if(state is UpdateItemQuantityLoading){
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if(state is UpdateItemQuantitySuccess) {
                          // Keep loading true, will be set to false when cart loads
                          context.read<GetUserCartBloc>().add(FetchUserCart(
                              addressId: selectedAddress?.id,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode
                          ));
                        }
                        if(state is UpdateItemQuantityFailed){
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                      },
                    ),
                    BlocListener<PromoCodeBloc, PromoCodeState>(
                      listener: (context, state){
                        if(state is PromoCodeRemoving || state is PromoCodeApplying || state is PromoCodeLoading){
                          setState(() {
                            isCartLoading = true;
                          });
                        }
                        if(state is PromoCodeLoaded) {
                          setState(() {
                            isCartLoading = false;
                          });
                        }
                        if(state is PromoCodeFailed){
                          setState(() {
                            isCartLoading = false;
                          });
                          ToastManager.show(
                              context: context,
                              message: AppLocalizations.of(context)!.promoCodeAppliedOnYourCart
                          );
                        }
                        if(state is PromoCodeSelected){
                          setState(() {
                            promoCode = state.promoCode;
                            isCartLoading = false;
                          });
                          if(state.promoCode.isNotEmpty) {
                            ToastManager.show(
                                context: context,
                                message: AppLocalizations.of(context)!.promoCodeAppliedOnYourCart
                            );
                          }
                        }
                        if(state is PromoCodeRemoved){
                          setState(() {
                            promoCode = state.promoCode;
                            isCartLoading = false;
                          });
                        }
                      },
                    )
                  ],
                  child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                    builder: (BuildContext context, GetUserCartState state) {
                      if (state is GetUserCartEmpty) {
                        return CustomRefreshIndicator(
                          onRefresh: () async {
                            context.read<GetUserCartBloc>().add(RefreshUserCart(
                                addressId: selectedAddress?.id,
                                useWallet: _userWantsWallet,
                                promoCode: promoCode
                            ));
                            context.read<SettingsBloc>().add(FetchSettingsData(context: context));
                            context.read<GetAddressListBloc>().add(FetchUserAddressList(deliveryZoneId: addressId));
                            context.read<UserWalletBloc>().add(FetchUserWallet());
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: _buildEmptyCartState(),
                          ),
                        );
                      }

                      if (_isInitialFetch || state is UserCartInitialLoading) {
                        log('Get User Cart $state');
                        return const CustomCircularProgressIndicator();
                      }

                      if (state is GetUserCartLoaded) {
                        stateData = state.cartData;
                      }

                      final bool hasItems = stateData.isNotEmpty &&
                          (stateData.first.data?.items.isNotEmpty ?? false);

                      if (!hasItems) {
                        return CustomRefreshIndicator(
                          onRefresh: () async {
                            context.read<GetUserCartBloc>().add(RefreshUserCart(
                                addressId: selectedAddress?.id,
                                useWallet: _userWantsWallet,
                                promoCode: promoCode
                            ));
                            context.read<SettingsBloc>().add(FetchSettingsData(context: context));
                            context.read<GetAddressListBloc>().add(FetchUserAddressList(deliveryZoneId: addressId));
                            context.read<UserWalletBloc>().add(FetchUserWallet());
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: _buildEmptyCartState(),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            child: CustomRefreshIndicator(
                        onRefresh: () async {
                          context.read<GetUserCartBloc>().add(RefreshUserCart(
                              addressId: selectedAddress?.id,
                              useWallet: _userWantsWallet,
                              promoCode: promoCode
                          ));
                          context.read<SettingsBloc>().add(FetchSettingsData(context: context));
                          context.read<GetAddressListBloc>().add(FetchUserAddressList(deliveryZoneId: addressId));
                          context.read<UserWalletBloc>().add(FetchUserWallet());
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                            builder: (BuildContext context, GetUserCartState state) {
                              if(state is GetUserCartLoaded) {
                                stateData = state.cartData;
                              } else if (state is GetUserCartEmpty) {
                                stateData = [];
                                return _buildEmptyCartState();
                              }
                              if (isClearingCart) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(height: 50.h),
                                      const CustomCircularProgressIndicator(),
                                      SizedBox(height: 10.h),
                                      Text(AppLocalizations.of(context)!.clearingYourCart, style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }
                              final bool currentHasItems = stateData.isNotEmpty &&
                                  (stateData.first.data?.items.isNotEmpty ?? false);

                              if (!currentHasItems) {
                                final localCartState = context.read<CartBloc>().state;
                                bool hasLocalItems = false;
                                if (localCartState is CartLoaded) {
                                  hasLocalItems = localCartState.items.isNotEmpty;
                                }

                                if (isCartLoading && hasLocalItems) {
                                  // We have local items but server/stateData is empty => SYNCING
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: 50.h),
                                        const CustomCircularProgressIndicator(),
                                        SizedBox(height: 10.h),
                                        const Text("Syncing your cart...", style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                }

                                return _buildEmptyCartState();
                              }

                              isCartLoading = false;
                              if(stateData.first.data?.items != null && stateData.first.data!.items.isNotEmpty) {
                                isCartLoading = false;
                                cartId = stateData.first.data?.id;
                                final cartData = stateData;
                                final billSummaryData = cartData.first.data!.paymentSummary;
                                addressId = cartData.first.data?.deliveryZone?.zoneId;
                                totalAmount = billSummaryData?.payableAmount?.toDouble() ?? 0.0;
                                return Column(
                                  children: [
                                    /// Address Selection Section
                                    if (hasItems) _buildDeliveryAddressBar(),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 16, top: 16),
                                      child: Column(
                                        children: [
                                          RemovedItemsWidget(
                                            removedItems: cartData.first.data?.removedItems ?? [],
                                          ),

                                          CartWidget(
                                            items: cartData.first.data!.items,
                                            deliveryTime: '',
                                            onQuantityChanged: _handleQuantityChanged,
                                            onRemoveItem: _handleRemoveItem,
                                            onAddMoreItems: _handleAddMoreItems,
                                            backgroundColor: Theme.of(context).colorScheme.surface,
                                            quantityButtonColor: AppTheme.primaryColor,
                                            priceColor: Theme.of(context).colorScheme.tertiary,
                                            originalPriceColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                            totalItem: cartData.first.data!.totalQuantity,
                                            addressId: selectedAddress?.id,
                                            rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                            useWallet: _userWantsWallet,
                                            promoCode: promoCode,
                                            sellerShippingCosts: billSummaryData?.sellerShippingCosts ?? const [],
                                            onAddAddressTap: _showAddressSelectionBottomSheet,
                                          ),

                                          OrderNoteWidget(
                                            onNoteChanged: (note) {
                                              setState(() {
                                                orderNote = note;
                                              });
                                            },
                                            isEnabled: !isCartLoading,
                                          ),
                                          BillSummaryWidget(
                                            itemsOriginalPrice: 0,
                                            itemsDiscountedPrice: billSummaryData?.itemsTotal?.toDouble() ?? 0,
                                            itemsSavings: 0,
                                            deliveryChargeOriginal: billSummaryData?.deliveryCharges?.toDouble() ?? 0,
                                            platformFee: billSummaryData?.platformFee?.toDouble() ?? 0,
                                            codFee: billSummaryData?.codFee?.toDouble() ?? 0,
                                            grandTotal: billSummaryData?.payableAmount?.toDouble() ?? 0,
                                            totalSavings: billSummaryData?.totalSavings?.toDouble() ?? 0,
                                            promoCode: billSummaryData?.promoCode,
                                            promoDiscount: double.tryParse(billSummaryData?.promoDiscount ?? '0') ?? 0.0,
                                            promoError: billSummaryData?.promoError,
                                            removeCoupon: (){
                                              setState(() {
                                                isCartLoading = true;
                                                promoCode = '';
                                              });
                                              context.read<PromoCodeBloc>().add(RemovePromoCode());
                                              context.read<GetUserCartBloc>().add(FetchUserCart(
                                                  addressId: selectedAddress?.id,
                                                  useWallet: _userWantsWallet,
                                                  promoCode: promoCode ?? ''
                                              ));
                                            },
                                            promoMode: billSummaryData?.promoApplied?.promoMode ?? '',
                                            discountAmount: billSummaryData?.promoApplied?.discountAmount ?? '',
                                            promoApplied: billSummaryData?.promoApplied,
                                            sellerShippingCosts: billSummaryData?.sellerShippingCosts ?? const [],
                                            taxBreakdown: billSummaryData?.taxBreakdown ?? const [],
                                            taxTotal: billSummaryData?.taxTotal,
                                            pendingCharges: billSummaryData?.pendingCharges ?? const [],
                                            pendingChargesTotal: billSummaryData?.pendingChargesTotal,
                                            currencySymbol: billSummaryData?.currencySymbol,
                                            format: billSummaryData?.format,
                                          ),
                                          SizedBox(height: 9.h,),
                                          BlocBuilder<SimilarProductBloc, SimilarProductState>(
                                              builder: (context, state) {
                                                if(state is SimilarProductLoaded) {
                                                  if(state.similarProduct.isNotEmpty) {
                                                    return Column(
                                                      children: [
                                                        YouMightAlsoLikeProductWidget(
                                                            productData: state.similarProduct,
                                                            addressId: selectedAddress?.id,
                                                            rushDelivery: selectedDeliveryType == DeliveryType.rush,
                                                            useWallet: _userWantsWallet,
                                                            promoCode: promoCode,
                                                            isFromCartPage: true
                                                        ),
                                                        SizedBox(height: 9.h,),
                                                      ],
                                                    );
                                                  } else {
                                                    return const SizedBox.shrink();
                                                  }
                                                } else if(state is SimilarProductLoading) {
                                                  return productListShimmer(3);
                                                }
                                                return const SizedBox.shrink();
                                              }
                                          ),
                                          const TrustSectionWidget(),
                                        ],
                                      ),
                                    ),

                                  ],
                                );
                              }
                              else {
                                isCartLoading = false;
                                return _buildEmptyCartState();
                              }
                            },
                          ),
                        ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
      ),
                bottomNavigationBar: BlocBuilder<GetUserCartBloc, GetUserCartState>(
                  builder: (context, state) {
                    if (state is GetUserCartLoaded) {
                      stateData = state.cartData;
                    } else if (state is GetUserCartEmpty) {
                      stateData = [];
                    }
                    final hasItems = stateData.isNotEmpty &&
                        (stateData.first.data?.items.isNotEmpty ?? false);

                    if(!_isInitialFetch && hasItems){
                      if (stateData.isNotEmpty) {
                        totalAmount = stateData.first.data?.paymentSummary?.payableAmount?.toDouble() ?? 0.0;
                      } else {
                        totalAmount = 0.0;
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCheckoutSection(),
                        ],
                      );
                    }
                    else {
                      return const SizedBox.shrink();
                    }
                  },
                )
            ),
            if(isWholePageProgress)
              const WholePageProgress(),
          ],
        );
      },
    );
  }

  List<CartItem> _getProductsMissingRequiredAttachment(
      BuildContext context,
      List<CartItem> cartItems,
      ) {
    final attachmentState = context.read<AttachmentBloc>().state;
    final attachmentsMap = attachmentState is AttachmentLoaded
        ? attachmentState.attachments
        : <int, CartItemAttachment?>{};

    return cartItems.where((item) {
      // Only check products that require attachment
      if(item.product?.isAttachmentRequired == true) {
        if (item.product?.attachmentMode != 'required') {
          return false;
        } else {
          final attachment = attachmentsMap[item.productId ?? -1];
          return attachment == null;
        }
      } else {
        return false;
      }
    }).toList();
  }

  void _handleQuantityChanged(String itemId, int newQuantity) {
    setState(() {
      isCartLoading = true;
    });
    context.read<UpdateItemQuantityBloc>().add(UpdateItemQuantityRequest(
        cartItemId: int.parse(itemId),
        quantity: newQuantity,
    ));
  }

  void _handleRemoveItem(String itemId) {
    setState(() {
      isCartLoading = true;
    });
    context.read<RemoveItemFromCartBloc>().add(RemoveItemFromCartRequest(cartItemId: int.parse(itemId)));
  }

  void _handleAddMoreItems() {
    final l10n = AppLocalizations.of(context);
    // Navigate to products page or show add items dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n?.addMoreItemsTapped ?? 'Add more items tapped!')),
    );
  }

  Widget _buildDeliveryAddressBar() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (selectedAddress != null) {
      return DeliveryAddressWidget(
        selectedAddress: selectedAddress,
        onTap: _showAddressSelectionBottomSheet,
      );
    }
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: _showAddressSelectionBottomSheet,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.map_pin_plus, size: 20.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  l10n?.chooseAddressForDelivery ?? 'Choose delivery address',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => AddressSelectionBottomSheet(
        selectedAddress: selectedAddress,
        deliveryZoneId: addressId,
        onAddressSelected: (address) async {
          if(selectedAddress == null || address.id != selectedAddress!.id) {
            final cartBloc = context.read<GetUserCartBloc>();
            final addressBloc = context.read<GetAddressListBloc>();
            setState(() {
              selectedAddress = address;
              selectedDeliveryType = DeliveryType.regular;
              isCartLoading = true;
            });
            // Save selected address to Hive
            HiveSelectedAddressHelper.setSelectedAddress(address);
            // Align the active market/country with the chosen address before refetching.
            await MarketService.switchAndCacheForCountry(
              iso2: address.countryCode ?? '',
              fallbackName: address.country,
            );
            if (!mounted) return;
            // Choosing an address in the cart also makes it the default shipping address.
            addressBloc.add(SetDefaultShippingRequest(address: address));
            cartBloc.add(FetchUserCart(
                addressId: address.id,
                useWallet: _userWantsWallet,
                promoCode: promoCode
            ));
          }
        },
      ),
    );
  }

  void _proceedToPayment() {
    if (selectedAddress == null) {
      _navigateToAddAddress();
      return;
    }
    if (!_runPreCheckoutValidations(requireVerification: true)) return;
    context.push(AppRoutes.orderConfirmation, extra: {
      'selectedAddress': selectedAddress,
      'promoCode': promoCode,
      'useWallet': _userWantsWallet,
    });
  }

  Widget _buildCheckoutSection() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final BoxDecoration barDecoration = BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border(
        top: BorderSide(color: theme.colorScheme.outline, width: 0.5),
      ),
    );

    // No address yet → single full-width CTA.
    if (selectedAddress == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: barDecoration,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: CustomButton(
            onPressed: _navigateToAddAddress,
            child: Text(
              AppLocalizations.of(context)!.chooseAddressForDelivery,
              style: AppTextStyles.titleMedium,
            ),
          ),
        ),
      );
    }

    final summary =
        stateData.isNotEmpty ? stateData.first.data?.paymentSummary : null;
    final String formattedTotal = (summary?.format != null)
        ? PriceUtils.formatWithFormat(
            totalAmount, summary!.format!, summary.currencySymbol)
        : PriceUtils.formatWithSymbol(
            totalAmount, summary?.currencySymbol ?? AppHelpers.currency);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 25),
      decoration: barDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Total on the left, primary CTA on the right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (l10n?.toPay ?? 'To pay').toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    formattedTotal,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: CustomButton(
                    isLoading: isCartLoading,
                    onPressed: isCartLoading ? () {} : _proceedToPayment,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            l10n?.proceedToPayment ?? 'Proceed to Payment',
                            maxLines: 1,
                            style: AppTextStyles.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isVerifiedValue(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.toLowerCase() != 'null';
  }

  bool _runPreCheckoutValidations({required bool requireVerification}) {
    final l10n = AppLocalizations.of(context);
    final user = Global.userData;
    if (requireVerification) {
      if(SettingsData.instance.authentication!.identifierMode == 'mobile_primary'){
        final bool mobileOk = _isVerifiedValue(user?.mobileVerified);
        if (!mobileOk) {
          ToastManager.show(
            context: context,
            message: l10n?.pleaseVerifyMobileBeforePlacingOrder ??
                'Please verify your mobile number before placing the order.',
            type: ToastType.error,
          );
          GoRouter.of(context).push(AppRoutes.userProfile);
          return false;
        }
      } else if(SettingsData.instance.authentication!.identifierMode == 'email_primary') {
        final bool emailOk = _isVerifiedValue(user?.emailVerified);
        if (!emailOk) {
          ToastManager.show(
            context: context,
            message: l10n?.pleaseVerifyEmailBeforePlacingOrder ??
                'Please verify your email before placing the order.',
            type: ToastType.error,
          );
          GoRouter.of(context).push(AppRoutes.userProfile);
          return false;
        }
      } else {
        final bool emailOk = _isVerifiedValue(user?.emailVerified);
        final bool mobileOk = _isVerifiedValue(user?.mobileVerified);
        if (!emailOk || !mobileOk) {
          ToastManager.show(
            context: context,
            message: l10n?.pleaseVerifyEmailAndMobileBeforePlacingOrder ??
                'Please verify your email and mobile number before placing the order.',
            type: ToastType.error,
          );
          GoRouter.of(context).push(AppRoutes.userProfile);
          return false;
        }
      }
    }

    if (stateData.isEmpty || stateData.first.data == null) {
      return false;
    }
    final cartData = stateData.first.data!;

    final storeIds = cartData.items
        .map((item) => item.storeId)
        .where((id) => id != null)
        .cast<int>()
        .toSet();

    // Check if any store is not fulfillable (deliverable)
    final billSummaryData = cartData.paymentSummary;
    if (billSummaryData != null) {
      final bool hasUnfulfillableStore = billSummaryData.sellerShippingCosts
          .any((s) => s.isFulfillable == false);
      if (hasUnfulfillableStore) {
        final storeName = billSummaryData.sellerShippingCosts
            .firstWhere((s) => s.isFulfillable == false)
            .storeName;
        ToastManager.show(
          context: context,
          message:
              'Some items in your cart from $storeName are not deliverable to your address. Please remove them to proceed.',
          type: ToastType.error,
        );
        return false;
      }
    }

    final summary = cartData.paymentSummary;
    final double totalItemAmount = summary?.itemsTotal?.toDouble() ?? 0.0;
    final cartValidationError = CartValidation.validateCartForCheckout(
      context: context,
      cartItemTotal: totalItemAmount,
      totalItemsCount: cartData.items.length,
      storeIds: storeIds,
      minimumCartAmount: summary?.minimumCartAmount,
      currencySymbol: summary?.currencySymbol,
      format: summary?.format,
    );

    if (cartValidationError != null) {
      ToastManager.show(
        context: context,
        message: cartValidationError,
      );
      return false;
    }

    final missingAttachmentProducts = _getProductsMissingRequiredAttachment(
      context,
      cartData.items,
    );

    if (missingAttachmentProducts.isNotEmpty) {
      final productNames = missingAttachmentProducts
          .map((p) => "• ${p.product?.name ?? 'Item'}")
          .join("\n");

      ToastManager.show(
        context: context,
        message:
            "Attachment required for:\n$productNames\nPlease add the required file(s).",
        type: ToastType.error,
        duration: const Duration(seconds: 5),
      );
      return false;
    }

    return true;
  }

  Widget _buildEmptyCartState() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.yourShoppingBagIsEmpty ?? 'Your shopping bag is empty',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.looksLikeYouHaventAddedAnythingYet ?? 'Looks like you haven\'t added anything yet',
              style: AppTextStyles.body.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 44,
              child: CustomButton(
                onPressed: () {
                  context.go(AppRoutes.home);
                },
                child: Text(
                  l10n?.browseProducts ?? 'Browse products',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddAddress() async {
    await GoRouter.of(context).push(
      AppRoutes.addEditAddress,
      extra: {
        'isEdit': false,
        'deliveryZoneId': addressId,
      },
    );
  }
}