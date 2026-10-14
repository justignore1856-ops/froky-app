import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_commerce/config/global.dart';
import 'package:hyper_commerce/config/global_keys.dart';
import 'package:hyper_commerce/config/helper.dart';
import 'package:hyper_commerce/screens/auth/bloc/apply_referral/apply_referral_bloc.dart';
import 'package:hyper_commerce/screens/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_commerce/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_commerce/screens/auth/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:hyper_commerce/screens/auth/view/forgot_password.dart';
import 'package:hyper_commerce/screens/auth/view/login_page.dart';
import 'package:hyper_commerce/screens/auth/view/continue_with_otp_page.dart';
import 'package:hyper_commerce/screens/auth/view/email_otp_verification_page.dart';
import 'package:hyper_commerce/screens/auth/view/otp_verification_page.dart';
import 'package:hyper_commerce/screens/auth/view/referral_code_entry_page.dart';
import 'package:hyper_commerce/screens/auth/view/register_page.dart';
import 'package:hyper_commerce/screens/cart_page/view/cart_page.dart';
import 'package:hyper_commerce/screens/cart_page/view/order_confirmation_page.dart';
import 'package:hyper_commerce/screens/cart_page/view/promo_code_page.dart';
import 'package:hyper_commerce/screens/payment_confirmation/view/payment_confirmation_page.dart';
import 'package:hyper_commerce/screens/payment_options/model/payment_response_model.dart';
import 'package:hyper_commerce/screens/address_list_page/model/get_address_list_model.dart';
import 'package:hyper_commerce/screens/category_list_page/view/category_list_page.dart';
import 'package:hyper_commerce/screens/home_page/view/home_page.dart';
import 'package:hyper_commerce/screens/introduction_pages/view/introduction_page.dart';
import 'package:hyper_commerce/screens/my_orders/view/order_timeline_page.dart';
import 'package:hyper_commerce/screens/my_orders/view/return_timeline_page.dart';
import 'package:hyper_commerce/screens/my_orders/model/order_detail_model.dart';
import 'package:hyper_commerce/screens/my_orders/view/product_rating_page.dart';
import 'package:hyper_commerce/screens/my_orders/view/seller_rating_page.dart';
import 'package:hyper_commerce/screens/near_by_stores/view/nearby_store_details.dart';
import 'package:hyper_commerce/screens/near_by_stores/view/nearyby_stores_page.dart';
import 'package:hyper_commerce/screens/order__transaction/view/order_transaction_page.dart';
import 'package:hyper_commerce/screens/product_detail_page/view/faq_list_page/faq_list_page.dart';
import 'package:hyper_commerce/screens/product_detail_page/view/review_rating_list_page/review_rating_list_page.dart';
import 'package:hyper_commerce/screens/shopping_list_page/view/shopping_list_result_page.dart';
import 'package:hyper_commerce/screens/splash_screen/splash_screen.dart';
import 'package:hyper_commerce/screens/sub_category_page/view/sub_category_page.dart';
import 'package:hyper_commerce/screens/support_page/view/support_page.dart';
import 'package:hyper_commerce/screens/email_verification/view/email_verification_page.dart';
import 'package:hyper_commerce/screens/mobile_verification/view/mobile_verification_page.dart';
import 'package:hyper_commerce/screens/user_profile/view/user_profile_page.dart';
import 'package:hyper_commerce/screens/wallet_page/bloc/wallet_transactions/wallet_transactions_bloc.dart';
import 'package:hyper_commerce/screens/wallet_page/view/transaction_page.dart';
import 'package:hyper_commerce/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_commerce/utils/widgets/custom_toast.dart';
import 'package:hyper_commerce/utils/widgets/empty_states_page.dart';
import 'package:hyper_commerce/utils/widgets/no_internet_connection.dart';
import '../config/map_code.dart';
import '../config/settings_data_instance.dart';
import '../screens/account_page/view/account_page.dart';
import '../screens/address_list_page/view/add_edit_address_page.dart';
import '../screens/auth/view/mobile_otp_login.dart';
import '../screens/brand_list_page/view/brands_list_page.dart';
import '../screens/section_see_all/view/section_see_all_page.dart';
import '../screens/product_section_see_all/view/product_section_see_all_page.dart';
import '../screens/dashboard/view/dashboard.dart';
import '../screens/delivery_zone_list/view/delivery_zone_detail_page.dart';
import '../screens/delivery_zone_list/view/delivery_zone_listing_page.dart';
import '../screens/my_orders/view/order_list_page.dart';
import '../screens/my_orders/view/order_item_detail_page.dart';
import '../screens/my_orders/view/order_success_page.dart';
import '../screens/policies/view/app_policies_page.dart';
import '../screens/product_detail_page/view/product_detail_page.dart';
import '../screens/address_list_page/view/address_list_page.dart';
import '../screens/payment_options/view/payment_options_page.dart';
import '../screens/product_listing_page/model/product_listing_type.dart';
import '../screens/product_listing_page/view/product_listing_page.dart';
import '../screens/refer_and_earn/view/refer_and_earn_page.dart';
import '../screens/save_for_later_page/view/save_for_later_page.dart';
import '../screens/search_page/view/search_page.dart';
import '../screens/shopping_list_page/view/shopping_list_page.dart';
import '../screens/wallet_page/view/add_money_page.dart';
import '../screens/wallet_page/view/wallet_page.dart';
import '../screens/notification_page/view/notification_page.dart';
import '../screens/wishlist_page/view/wishlist_page.dart';
import '../screens/wishlist_page/view/wishlist_product_listing_page.dart';
import '../screens/watch_and_buy_page/view/watch_and_buy_page.dart';
import '../screens/watch_and_buy_page/view/watch_and_buy_feed_page.dart';
import '../screens/watch_and_buy_page/view/status_viewer_page.dart';
import '../screens/watch_and_buy_page/view/seller_profile_page.dart';
import '../screens/watch_and_buy_page/model/watch_status_model.dart';
import '../screens/watch_and_buy_page/model/watch_and_buy_model.dart';
import '../utils/widgets/page_animation.dart';

Page platformPage(Widget child, {BuildContext? context, GoRouterState? state}) {
  if (Platform.isIOS) {
    // iOS: Keep native Cupertino transition (or wrap with CustomTransitionPage if you want same animation on both platforms)
    return CupertinoPage(child: child);
  } else {
    // Android & others: Use custom animation
    if (context != null && state != null) {
      return buildAnimatedPage(context, state, child);
    }
    return MaterialPage(child: child);
  }
}



class AppRoutes {
  static const String splashScreen = '/';
  static const String introSlider = '/intro-slider';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String orderAgain = '/order-again';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String locationPicker = '/location-picker';
  static const String account = '/account';
  static const String productListing = '/product-listing';
  static const String productDetailPage = '/product-detail';
  static const String reviewRatingPage = '/review-rating';
  static const String faqPage = '/faq';
  static const String addressList = '/address-list';
  static const String addEditAddress = '/add-edit-address';
  static const String paymentOptions = '/payment-options';
  static const String orderSuccess = '/order-success';
  static const String orderConfirmation = '/order-confirmation';
  static const String paymentConfirmation = '/payment-confirmation';
  static const String userProfile = '/user-profile';
  static const String promoCode = '/promo-code';
  static const String myOrders = '/my-orders';
  static const String orderDetail = '/order-detail';
  static const String orderItemDetail = '/order-item-detail';
  static const String orderTimeline = '/order-timeline';
  static const String returnTimeline = '/return-timeline';
  static const String shoppingList = '/shopping-list';
  static const String wallet = '/wallet';
  static const String addMoney = '/add-money';
  static const String transactions = '/transactions';
  static const String deliveryTracking = '/delivery-tracking';
  static const String shoppingListResult = '/shopping-list-result';
  static const String wishlistPage = '/wishlist';
  static const String noInternet = '/no-internet';
  static const String search = '/search';
  static const String wishlistProduct = '/wishlist-product';
  static const String saveForLater = '/save-for-later';
  static const String policyPage = '/policy-page';
  static const String supportPage = '/support-page';
  static const String nearbyStores = '/near-by-store';
  static const String nearbyStoreDetails = '/near-by-store-details';
  static const String productRating = '/product-rating';
  static const String sellerRating = '/seller-rating';
  static const String forgotPassword = '/forgot-password';
  static const String maintenancePage = '/maintenance-page';
  static const String brandsListPage = '/brands-list-page';
  static const String sectionSeeAll = '/section-see-all';
  static const String productSectionSeeAll = '/product-section-see-all';
  static const String mobileOtpLoginPage = '/mobile-otp-login-page';
  static const String continueWithOtp = '/continue-with-otp';
  static const String emailOtpVerification = '/email-otp-verification';
  static const String orderDelivered = '/order-delivered';
  static const String deliveryZoneList = '/delivery-zones';
  static const String deliveryZoneDetail = '/delivery-zone-detail';
  static const String notifications = '/notifications';
  static const String forceUpdateWaitingScreen = '/force-update-waiting-screen';
  static const String referAndEarnPage = '/refer-and-earn-page';
  static const String subCategoryListPage = '/sub-category-list-page';
  static const String orderTransactionsPage = '/order-transaction-page';
  static const String emailVerification = '/email-verification';
  static const String mobileVerification = '/mobile-verification';
  static const String referralCodeEntry = '/referral-code-entry';
  static const String watchAndBuy = '/watch-and-buy';
  static const String watchAndBuyPlayer = '/watch-and-buy-player';
  static const String storyViewer = '/story-viewer';
  static const String statusViewer = '/status-viewer';
  static const String sellerProfile = '/seller-profile';

  //test
  static const String sectionGallery = '/section-gallery';
}

class MyAppRoute {
  static GoRouter router = GoRouter(
      navigatorKey: GlobalKeys.navigatorKey,
      initialLocation: AppRoutes.splashScreen,
      routes: [
        GoRoute(
          name: '/',
          path: AppRoutes.splashScreen,
          pageBuilder: (context, state) => platformPage(const SplashScreen()),
        ),
        GoRoute(
          name: '/intro-slider',
          path: AppRoutes.introSlider,
          pageBuilder: (context, state) => platformPage(const IntroductionPage()),
        ),
        GoRoute(
          path: '/link',
          name: 'firebase-link',
          redirect: (context, state) {
            final authBloc = BlocProvider.of<AuthBloc>(
                GlobalKeys.navigatorKey.currentContext!);
            final authState = authBloc.state;

            // If we have pending registration data → go to OTP
            if (authState is LoginPhoneCodeSentState) {
              final pendingData = authBloc.getPendingRegistrationData();
              if (pendingData != null) {
                // Don't redirect here — let the pageBuilder push to OTP
                return null; // stay on /link temporarily
              } else {
                // No pending data → redirect to register
                return AppRoutes.register;
              }
            }

            // If auth failed → go to register
            if (authState is AuthFailed) {
              return AppRoutes.register;
            }

            // Otherwise stay on /link to show loading
            return null;
          },
          pageBuilder: (context, state) {
            return platformPage(
              BlocListener<AuthBloc, AuthState>(
                listener: (context, authState) async {
                  if (authState is LoginPhoneCodeSentState) {
                    final bloc = context.read<AuthBloc>();
                    final pendingData = bloc.getPendingRegistrationData();

                    if (pendingData != null && context.mounted) {
                      context.pushReplacement(
                        // ← Use pushReplacement!
                        AppRoutes.otpVerification,
                        extra: {
                          'phoneNumber': bloc.getPendingPhoneNumber(),
                          'registrationData': pendingData,
                          'verificationId': authState.verificationId,
                          'userNumber': bloc.getPendingPhoneNumber(),
                          'countryCode': bloc.getPendingCountryCode(),
                          'isoCode': bloc.getPendingIsoCode(),
                        },
                      );
                    }
                  }
                  if (authState is AuthFailed && context.mounted) {
                    ToastManager.show(
                      context: context,
                      message: authState.error,
                      type: ToastType.error,
                    );

                    // This will now work reliably because redirect handles fallback
                    context.go(AppRoutes.register);
                  }
                },
                child: const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomCircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        GoRoute(
            name: 'otp-verification',
            path: AppRoutes.otpVerification,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(OTPVerificationPage(
                phoneNumber: extra['phoneNumber'] ?? '',
                registrationData: extra['registrationData'] ?? {},
                verificationId: extra['verificationId'] ?? '',
                number: extra['userNumber'] ?? '',
                countryCode: extra['countryCode'] ?? '',
                isoCode: extra['isoCode'] ?? '',
                isLogin: extra['isLogin'] ?? false,
                userName: extra['userName'] ?? '',
                referralCode: extra['referralCode'] ?? '',
                isUpdate: extra['isUpdate'] ?? false,
                popOnSuccess: extra['popOnSuccess'] ?? false,
              ));
            }),
        GoRoute(
          name: 'login',
          path: AppRoutes.login,
          pageBuilder: (context, state) => platformPage(
            const LoginPage(),
            context: context,
            state: state
          ),
        ),
        GoRoute(
          name: 'forgot-password',
          path: AppRoutes.forgotPassword,
          pageBuilder: (context, state) => platformPage(
            BlocProvider(
              create: (_) => ForgotPasswordBloc(),
              child: const ForgotPassword(),
            ),
            context: context,
            state: state
          ),
        ),
        GoRoute(
          name: 'referral-code-entry',
          path: AppRoutes.referralCodeEntry,
          pageBuilder: (context, state) => platformPage(
            BlocProvider(
              create: (_) => ApplyReferralBloc(),
              child: const ReferralCodeEntryPage(),
            ),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'no-internet',
          path: AppRoutes.noInternet,
          pageBuilder: (context, state) =>
              platformPage(
                const NoInternetConnection(),
                context: context,
                state: state
              ),
        ),
        GoRoute(
          name: 'register',
          path: AppRoutes.register,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              RegisterPage(
                userName: extra['name'] ?? '',
                userEmail: extra['email'] ?? '',
              ),
            );
          },
        ),

        StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return Dashboard(
                index: navigationShell.currentIndex,
                navigationShell: navigationShell,
              );
            },
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'home',
                  path: AppRoutes.home,
                  pageBuilder: (context, state) => platformPage(
                    const HomePage(),
                  ),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'category-list-page',
                  path: AppRoutes.categories,
                  pageBuilder: (context, state) =>
                      platformPage(
                        const CategoryListPage(),
                      ),
                ),
              ]),

              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'watch-and-buy',
                  path: AppRoutes.watchAndBuy,
                  redirect: (context, state) {
                    if (SettingsData.instance.watchAndBuy?.enabled != true) {
                      return AppRoutes.home;
                    }
                    return null;
                  },
                  pageBuilder: (context, state) => platformPage(
                    const WatchAndBuyFeedPage(),
                    context: context,
                    state: state,
                  ),
                ),
              ]),

              StatefulShellBranch(routes: [
                GoRoute(
                  name: 'account',
                  path: AppRoutes.account,
                  pageBuilder: (context, state) => platformPage(
                      const AccountPage(),
                      context: context,
                      state: state
                  ),
                ),
              ]),

            ]),

        GoRoute(
          name: 'watch-and-buy-player',
          path: AppRoutes.watchAndBuyPlayer,
          redirect: (context, state) {
            if (SettingsData.instance.watchAndBuy?.enabled != true) {
              return AppRoutes.home;
            }
            return null;
          },
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomTransitionPage(
              key: state.pageKey,
              transitionDuration: const Duration(milliseconds: 320),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              child: WatchAndBuyPage(
                shortsSlug: extra['shortsSlug'] ?? '',
                initialIndex: extra['initialIndex'] ?? 0,
                initialItem: extra['initialItem'] as WatchAndBuyItem?,
                frameThumbnail: extra['frameThumbnail'] as Uint8List?,
                onShortsTap: true,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          name: 'status-viewer',
          path: AppRoutes.statusViewer,
          redirect: (context, state) {
            if (SettingsData.instance.watchAndBuy?.enabled != true) {
              return AppRoutes.home;
            }
            return null;
          },
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final statusProfiles =
                (extra['statusProfiles'] as List<WatchStatusFeedItem>?) ?? [];
            final initialProfileIndex =
                (extra['initialProfileIndex'] as int?) ?? 0;
            return CustomTransitionPage(
              key: state.pageKey,
              opaque: false,
              barrierDismissible: false,
              barrierColor: Colors.black,
              transitionDuration: const Duration(milliseconds: 280),
              reverseTransitionDuration: const Duration(milliseconds: 250),
              child: StatusViewerPage(
                statusProfiles: statusProfiles,
                initialProfileIndex: initialProfileIndex,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          name: 'story-viewer',
          path: AppRoutes.storyViewer,
          redirect: (context, state) {
            if (SettingsData.instance.watchAndBuy?.enabled != true) {
              return AppRoutes.home;
            }
            return null;
          },
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final statusProfiles =
                (extra['statusProfiles'] as List<WatchStatusFeedItem>?) ?? [];
            final initialProfileIndex =
                (extra['initialProfileIndex'] as int?) ?? 0;
            return CustomTransitionPage(
              key: state.pageKey,
              opaque: false,
              barrierDismissible: false,
              barrierColor: Colors.black,
              transitionDuration: const Duration(milliseconds: 280),
              reverseTransitionDuration: const Duration(milliseconds: 250),
              child: StatusViewerPage(
                statusProfiles: statusProfiles,
                initialProfileIndex: initialProfileIndex,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: child,
                );
              },
            );
          },
        ),

        GoRoute(
          name: 'seller-profile',
          path: AppRoutes.sellerProfile,
          redirect: (context, state) {
            if (SettingsData.instance.watchAndBuy?.enabled != true) {
              return AppRoutes.home;
            }
            return null;
          },
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final username = (extra['username'] as String?) ?? '';
            return platformPage(
              SellerProfilePage(
                username: username,
              ),
              context: context,
              state: state,
            );
          },
        ),

        GoRoute(
          name: 'watch-and-buy-direct',
          path: '/watch-and-buy-direct',
          redirect: (context, state) {
            if (SettingsData.instance.watchAndBuy?.enabled != true) {
              return AppRoutes.home;
            }
            return null;
          },
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              WatchAndBuyPage(
                shortsSlug: extra['shortsSlug'] ?? '',
                initialIndex: extra['initialIndex'] ?? 0,
                initialItem: extra['initialItem'] as WatchAndBuyItem?,
                frameThumbnail: extra['frameThumbnail'] as Uint8List?,
                onShortsTap: true,
              ),
              context: context,
              state: state,
            );
          },
        ),

        GoRoute(
          name: 'cart',
          path: AppRoutes.cart,
          pageBuilder: (context, state) => platformPage(
              const CartPage(),
              context: context,
              state: state
          ),
        ),

        GoRoute(
          name: 'near-by-store',
          path: AppRoutes.nearbyStores,
          pageBuilder: (context, state) =>
              platformPage(
                  const NearbyStoresPage(),
                  context: context,
                  state: state
              ),
        ),

        GoRoute(
          name: 'my-orders',
          path: AppRoutes.myOrders,
          pageBuilder: (context, state) => platformPage(
              const OrderListPage(),
              context: context,
              state: state
          ),
        ),

        GoRoute(
          name: 'location-picker',
          path: AppRoutes.locationPicker,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            return LocationPickerWidget(
              initialLatitude: args?['lat'],
              initialLongitude: args?['lng'],
              initialAddress: args?['address'],
              isFromAddressPage: args?['isFromAddressPage'],
              isEdit: args?['isEdit'],
              addressId: args?['addressId'],
              addressType: args?['addressType'],
              isFromCartPage: args?['isFromCartPage'],
              deliveryZoneId: args?['deliveryZoneId'],
              isDefaultShipping: args?['isDefaultShipping'],
            );
          },
        ),

        GoRoute(
          name: 'product-listing',
          path: AppRoutes.productListing,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final isTheirMoreCategory = extra['isTheirMoreCategory'] as bool? ??
                false; // Default to false if null
            final dynamic rawType = extra['type'];
            final ProductListingType listingType = rawType is ProductListingType
                ? rawType
                : rawType is String
                ? ProductListingType.values.firstWhere(
                  (e) => e.name == rawType,
              orElse: () => ProductListingType.category,
            )
                : ProductListingType.category;
            final String identifier = (extra['identifier']?.toString() ??
                extra['categorySlug']?.toString() ??
                state.uri.queryParameters['identifier'] ??
                state.uri.queryParameters['category-slug'] ??
                '');
            return platformPage(
              ProductListingPage(
                key: ValueKey('product-listing-$identifier-${state.pageKey}'),
                isTheirMoreCategory: isTheirMoreCategory,
                title: extra['title']?.toString() ?? '',
                logo: extra['logo']?.toString() ?? '',
                totalProduct: extra['totalProduct']?.toString() ?? '',
                type: listingType,
                identifier: identifier,
              ),
            );
          },
        ),

        GoRoute(
            name: 'product-detail',
            path: AppRoutes.productDetailPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final productSlug = extra['productSlug']?.toString() ??
                  state.uri.queryParameters['productSlug'] ?? '';
              final title = extra['title']?.toString() ?? '';
              final mainImage = extra['mainImage']?.toString() ?? '';

              return platformPage(
                ProductDetailPage(
                  key: ValueKey('product-detail-$productSlug'),
                  productSlug: productSlug,
                  initialData:
                  ProductInitialData(title: title, mainImage: mainImage),
                ),

              );
            }),

        GoRoute(
            name: 'review-rating',
            path: AppRoutes.reviewRatingPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, String>;
              return platformPage(
                  ReviewRatingListPage(
                    productSlug: extra['productSlug']!,
                  ),
                  context: context,
                  state: state
              );
            }),

        GoRoute(
            name: 'faq',
            path: AppRoutes.faqPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, String>;
              return platformPage(
                  FaqListPage(
                    productSlug: extra['productSlug']!,
                  ),
                  context: context,
                  state: state
              );
            }),

        GoRoute(
          name: 'address-list',
          path: AppRoutes.addressList,
          pageBuilder: (context, state) => platformPage(
              const AddressListPage(),
              context: context,
              state: state
          ),
        ),

        GoRoute(
          name: 'add-edit-address',
          path: AppRoutes.addEditAddress,
          pageBuilder: (context, state) {
            final args = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              AddEditAddressPage(
                isEdit: args['isEdit'] as bool? ?? false,
                address: args['address'] as AddressListData?,
                isDefaultShipping: args['isDefaultShipping'] as bool? ?? false,
                deliveryZoneId: args['deliveryZoneId'] as int?,
              ),
              context: context,
              state: state,
            );
          },
        ),

        GoRoute(
          name: 'payment-options',
          path: AppRoutes.paymentOptions,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                PaymentOptionsPage(
                  totalAmount: extra['totalAmount']?.toDouble() ?? 0.0,
                  isFromAddMoney: extra['isFromAddMoney'] as bool? ?? false,
                  codAvailable: extra['codAvailable'] as bool? ?? true,
                ),
                context: context,
                state: state
            );
          },
        ),

        GoRoute(
            name: 'order-confirmation',
            path: AppRoutes.orderConfirmation,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(
                OrderConfirmationPage(
                  selectedAddress: extra['selectedAddress'] as AddressListData?,
                  promoCode: extra['promoCode'] as String?,
                  useWallet: extra['useWallet'] as bool? ?? false,
                ),
                context: context,
                state: state,
              );
            }),
        GoRoute(
            name: 'order-success',
            path: AppRoutes.orderSuccess,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(
                  OrderSuccessPage(
                    address: extra['address'].toString(),
                    addressType: extra['addressType'].toString(),
                    orderSlug: extra['orderSlug'].toString(),
                    orderItemId: parseInt(extra['orderItemId']),
                  ),
                  context: context,
                  state: state
              );
            }),
        GoRoute(
            name: 'payment-confirmation',
            path: AppRoutes.paymentConfirmation,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(
                  PaymentConfirmationPage(
                    orderSlug: extra['orderSlug'].toString(),
                    orderItemId: parseInt(extra['orderItemId']),
                    paymentType: extra['paymentType'].toString(),
                    paymentResponse:
                        extra['paymentResponse'] as PaymentResponse,
                    address: extra['address']?.toString() ?? '',
                    addressType: extra['addressType']?.toString() ?? '',
                    contact: extra['contact']?.toString(),
                    email: extra['email']?.toString(),
                  ),
                  context: context,
                  state: state);
            }),
        GoRoute(
          name: 'user-profile',
          path: AppRoutes.userProfile,
          pageBuilder: (context, state) => platformPage(
              const UserProfilePage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'email-verification',
          path: AppRoutes.emailVerification,
          pageBuilder: (context, state) => platformPage(
            const EmailVerificationPage(),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'mobile-verification',
          path: AppRoutes.mobileVerification,
          pageBuilder: (context, state) => platformPage(
            const MobileVerificationPage(),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'promo-code',
          path: AppRoutes.promoCode,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                PromoCodePage(
                  cartAmount: extra['cartAmount']?.toDouble(),
                  deliveryCharges: extra['deliveryCharges']?.toDouble(),
                ),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'order-item-detail',
          path: AppRoutes.orderItemDetail,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final orderSlug = extra['order-slug'] ??
                state.uri.queryParameters['order-slug'];
            final rawItemId =
                extra['order-item-id'] ?? state.uri.queryParameters['order-item-id'];
            final orderItemId = rawItemId is int
                ? rawItemId
                : int.tryParse(rawItemId?.toString() ?? '');
            return platformPage(
                OrderItemDetailPage(
                  orderSlug: orderSlug,
                  orderItemId: orderItemId,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'order-timeline',
          path: AppRoutes.orderTimeline,
          pageBuilder: (context, state) {
            final timeline = state.extra is List<OrderTimelineStage>
                ? state.extra as List<OrderTimelineStage>
                : const <OrderTimelineStage>[];
            return platformPage(
                OrderTimelinePage(timeline: timeline),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'return-timeline',
          path: AppRoutes.returnTimeline,
          pageBuilder: (context, state) {
            final returnData = state.extra is ItemReturn
                ? state.extra as ItemReturn
                : ItemReturn();
            return platformPage(
                ReturnTimelinePage(returnData: returnData),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'shopping-list',
          path: AppRoutes.shoppingList,
          pageBuilder: (context, state) => platformPage(
              const ShoppingListPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'wallet',
          path: AppRoutes.wallet,
          pageBuilder: (context, state) => platformPage(
              const WalletPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'add-money',
          path: AppRoutes.addMoney,
          pageBuilder: (context, state) => platformPage(
              const AddMoneyPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'transactions',
          path: AppRoutes.transactions,
          pageBuilder: (context, state) => platformPage(
              BlocProvider(
                create: (_) => WalletTransactionsBloc(),
                child: const TransactionPage(),
              ),
              context: context,
              state: state
          ),
        ),

        GoRoute(
          name: 'shopping-list-result',
          path: AppRoutes.shoppingListResult,
          pageBuilder: (context, state) =>
              platformPage(
                  const ShoppingListResultPage(),
                  context: context,
                  state: state
              ),
        ),
        GoRoute(
          name: 'wishlist',
          path: AppRoutes.wishlistPage,
          pageBuilder: (context, state) => platformPage(
              const WishlistPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'search',
          path: AppRoutes.search,
          pageBuilder: (context, state) => platformPage(
              const SearchPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'wishlist-product',
          path: AppRoutes.wishlistProduct,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final wishlistId = extra['wishlist-id'] ??
                state.uri.queryParameters['wishlist-id'];
            return platformPage(
                WishlistProductListingPage(
                  wishlistId: wishlistId,
                ),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'save-for-later',
          path: AppRoutes.saveForLater,
          pageBuilder: (context, state) => platformPage(
              const SaveForLaterPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
            name: 'policy-page',
            path: AppRoutes.policyPage,
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return platformPage(PolicyPage(
                policyType: extra['policy-type'] ?? PolicyType.aboutUs,
              ),
                  context: context,
                  state: state
              );
            }),
        GoRoute(
          name: 'support-page',
          path: AppRoutes.supportPage,
          redirect: (_, __) =>
              Global.userData == null ? AppRoutes.login : null,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? const {};
            final rawOrderId =
                extra['order-id'] ?? state.uri.queryParameters['order-id'];
            final orderId = rawOrderId is int
                ? rawOrderId
                : int.tryParse(rawOrderId?.toString() ?? '');
            final ticketSlug = extra['ticket-slug']?.toString() ??
                state.uri.queryParameters['ticket-slug'];
            return platformPage(
              SupportPage(
                initialOrderId: orderId,
                ticketSlug: ticketSlug,
              ),
              context: context,
              state: state,
            );
          },
        ),
        GoRoute(
          name: 'near-by-store-details',
          path: AppRoutes.nearbyStoreDetails,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>? ?? {};
            final storeSlug = map['store-slug'] ??
                state.uri.queryParameters['store-slug'] ?? '';
            final storeName = map['store-name'] ?? '';
            return platformPage(
                NearbyStoreDetails(
                  storeSlug: storeSlug,
                  storeName: storeName,
                ),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'product-rating',
          path: AppRoutes.productRating,
          pageBuilder: (context, state) {
            final m = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                ProductRatingPage(
                  orderItemId: m['orderItemId'] as int,
                  productName: m['productName'] as String?,
                  variantTitle: m['variantTitle'] as String?,
                  image: m['image'] as String?,
                  initialRating: (m['initialRating'] as int?) ?? 0,
                  initialTitle: m['initialTitle'] as String?,
                  initialComment: m['initialComment'] as String?,
                  feedbackId: m['feedbackId'] as int?,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'seller-rating',
          path: AppRoutes.sellerRating,
          pageBuilder: (context, state) {
            final m = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                SellerRatingPage(
                  sellerId: m['sellerId'] as int,
                  orderItemId: m['orderItemId'] as int,
                  storeName: (m['storeName'] as String?) ?? '',
                  initialRating: (m['initialRating'] as int?) ?? 0,
                  initialTitle: m['initialTitle'] as String?,
                  initialComment: m['initialComment'] as String?,
                  feedbackId: m['feedbackId'] as int?,
                ),
                context: context,
                state: state);
          },
        ),
        GoRoute(
          name: 'maintenance-page',
          path: AppRoutes.maintenancePage,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final message = map["message"];
            return platformPage(
                MaintenancePage(description: message),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'brands-list-page',
          path: AppRoutes.brandsListPage,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            final categorySlug = map["category-slug"];
            return platformPage(
                BrandsListPage(categorySlug: categorySlug),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'section-see-all',
          path: AppRoutes.sectionSeeAll,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final sectionId = extra['section-id'] is int
                ? extra['section-id'] as int
                : int.tryParse(extra['section-id']?.toString() ?? '') ?? 0;
            return platformPage(
              SectionSeeAllPage(
                key: ValueKey('section-see-all-$sectionId'),
                sectionId: sectionId,
                type: extra['type']?.toString() ?? '',
                title: extra['title']?.toString() ?? '',
              ),
              context: context,
              state: state,
            );
          },
        ),
        GoRoute(
          name: 'product-section-see-all',
          path: AppRoutes.productSectionSeeAll,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final sectionId = extra['section-id'] is int
                ? extra['section-id'] as int
                : int.tryParse(extra['section-id']?.toString() ?? '') ?? 0;
            return platformPage(
              ProductSectionSeeAllPage(
                key: ValueKey('product-section-see-all-$sectionId'),
                sectionId: sectionId,
                title: extra['title']?.toString() ?? '',
              ),
              context: context,
              state: state,
            );
          },
        ),
        GoRoute(
          name: 'mobile-otp-login-page',
          path: AppRoutes.mobileOtpLoginPage,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                MobileOtpLoginPage(
                  isDirectLogin: extra['isDirectLogin'],
                  isUpdate: extra['isUpdate'] ?? false,
                ),
                context: context,
                state: state
            );
          } ,
        ),
        GoRoute(
          name: 'continue-with-otp',
          path: AppRoutes.continueWithOtp,
          pageBuilder: (context, state) => platformPage(
            const ContinueWithOtpPage(),
            context: context,
            state: state,
          ),
        ),
        GoRoute(
          name: 'email-otp-verification',
          path: AppRoutes.emailOtpVerification,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
              EmailOtpVerificationPage(email: extra['email'] ?? ''),
              context: context,
              state: state,
            );
          },
        ),

        GoRoute(
          name: 'delivery-zone',
          path: AppRoutes.deliveryZoneList,
          pageBuilder: (context, state) => platformPage(
              const DeliveryZoneListingPage(),
              context: context,
              state: state
          ),
        ),
        GoRoute(
          name: 'delivery-zone-detail',
          path: AppRoutes.deliveryZoneDetail,
          pageBuilder: (context, state) {
            final map = state.extra as Map<String, dynamic>? ?? {};
            final zoneId = map["zoneId"] ??
                int.tryParse(state.uri.queryParameters['zoneId'] ?? '');
            return platformPage(
                DeliveryZoneDetailPage(
                  zoneId: zoneId,
                ),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'notifications',
          path: AppRoutes.notifications,
          pageBuilder: (context, state) =>
              platformPage(
                  const NotificationPage(),
                  context: context,
                  state: state
              ),
        ),
        GoRoute(
          name: 'refer-and-earn-page',
          path: AppRoutes.referAndEarnPage,
          pageBuilder: (context, state) {
            return platformPage(
                const ReferAndEarnPage(),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'sub-category-list-page',
          path: AppRoutes.subCategoryListPage,
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return platformPage(
                SubCategoryListPage(
                  slug: extra['slug'] ?? '',
                  isForAllCategory: extra['isForAllCategory'] as bool?,
                ),
                context: context,
                state: state
            );
          },
        ),
        GoRoute(
          name: 'order-transactions-page',
          path: AppRoutes.orderTransactionsPage,
          pageBuilder: (context, state) {
            return platformPage(
                const OrderTransactionPage(),
                context: context,
                state: state
            );
          },
        ),

      ]);
}
