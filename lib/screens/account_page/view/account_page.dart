import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:hyper_commerce/config/global_keys.dart';
import 'package:intl/intl.dart';
import 'package:hyper_commerce/config/settings_data_instance.dart';
import 'package:hyper_commerce/router/app_routes.dart';
import 'package:hyper_commerce/screens/auth/bloc/auth/auth_state.dart';
import 'package:hyper_commerce/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_commerce/screens/policies/view/app_policies_page.dart';
import 'package:hyper_commerce/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_commerce/services/recent_product/recent_product_service.dart';
import 'package:hyper_commerce/services/shopping_list_hive.dart';
import '../../../bloc/language_bloc/language_bloc.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../model/user_data_model/user_data_model.dart';
import '../../../services/market/market_service.dart';
import '../../../utils/widgets/country_bottom_sheet.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../utils/widgets/language_bottom_sheet.dart';
import '../../auth/bloc/auth/auth_bloc.dart';
import '../../auth/bloc/auth/auth_event.dart';
import '../widgets/account_menu_tile.dart';
import '../widgets/section_card_widget.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Timer? _holdTimer;
  Timer? _progressTimer;
  int _secondsHeld = 0;

  @override
  void initState() {
    super.initState();
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _progressTimer?.cancel();
    _progressTimer = null;
    super.dispose();
  }

  void _startHold() {
    _secondsHeld = 0;

    // 🔥 Light vibration on start
    HapticFeedback.lightImpact();

    debugPrint("Hold started");

    // ⏱️ Log every second
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsHeld++;
      debugPrint("Holding... $_secondsHeld sec");
    });

    // 🎯 Trigger after 5 seconds
    _holdTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      debugPrint("Hold completed (5 sec)");

      // 💥 Strong feedback on success
      HapticFeedback.heavyImpact();

      if (!kReleaseMode) {
        GlobalKeys.httpInspectorEnabled.value = !GlobalKeys.httpInspectorEnabled.value;
      } else {
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            GlobalKeys.httpInspectorEnabled.value
                ? "HTTP Inspector Enabled 🚀"
                : "HTTP Inspector Disabled ❌",
          ),
        ),
      );
    });
  }

  void _cancelHold() {
    if (_secondsHeld > 0 && _secondsHeld < 5) {
      debugPrint("Hold cancelled at $_secondsHeld sec");
    }

    _holdTimer?.cancel();
    _progressTimer?.cancel();
    _secondsHeld = 0;
  }


  void _pushOrLogin(String route) {
    if (Global.userData == null) {
      GoRouter.of(context).pushReplacement(AppRoutes.login);
    } else {
      GoRouter.of(context).push(route);
    }
  }

  void _openPolicy(PolicyType type) {
    GoRouter.of(context)
        .push(AppRoutes.policyPage, extra: {'policy-type': type});
  }

  @override
  Widget build(BuildContext context) {
    log('Is Dev ${SettingsData.instance.system?.isDev}');
    final l10n = AppLocalizations.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<UserProfileBloc, UserProfileState>(
            listener: (context, state) {}),
        BlocListener<AuthBloc, AuthState>(listener: (context, state) {
          if (state is LogoutUser) {
            Global.clearUserData();
            ShoppingListHiveHelper.clearLastList();
            RecentlyViewedService.clear();
            context.read<GetUserCartBloc>().add(FetchUserCart());
            GoRouter.of(context).pushReplacement(AppRoutes.login);
          }
        }),
      ],
      child: CustomScaffold(
        showViewCart: false,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        onConnectivityRestored: (_) async {
          context.read<UserProfileBloc>().add(FetchUserProfile());
        },
        title: l10n?.myAccount ?? 'My account',
        showAppBar: true,
        // appBar: const AccountPageAppBar(),
        body: ValueListenableBuilder<String?>(
          valueListenable: Global.tokenNotifier,
          builder: (context, token, _) {
            final loggedIn = token != null;
            return ListView(
              padding: EdgeInsets.only(bottom: 28.h),
              children: [
                SizedBox(height: 8.h),
                _profileHeader(l10n),

                _sectionLabel(context, l10n?.manage ?? 'Manage'),
                _menuCard(context, [
                  AccountMenuTile(
                    icon: TablerIcons.shopping_bag,
                    title: l10n?.myOrders ?? 'My orders',
                    onTap: () => _pushOrLogin(AppRoutes.myOrders),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.map_pin,
                    title: l10n?.manageAddresses ?? 'Manage addresses',
                    onTap: () => _pushOrLogin(AppRoutes.addressList),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.credit_card,
                    title: l10n?.myTransactions ?? 'My transactions',
                    onTap: () => _pushOrLogin(AppRoutes.orderTransactionsPage),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.heart,
                    title: l10n?.myWishlist ?? 'My wishlist',
                    onTap: () => _pushOrLogin(AppRoutes.wishlistPage),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.wallet,
                    title: l10n?.wallet ?? 'Wallet',
                    onTap: () => _pushOrLogin(AppRoutes.wallet),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.notebook,
                    title: l10n?.shoppingList ?? 'Shopping List',
                    onTap: () => _pushOrLogin(AppRoutes.shoppingList),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.bookmark,
                    title: l10n?.savedForLater ?? 'Saved for later',
                    onTap: () => _pushOrLogin(AppRoutes.saveForLater),
                  ),
                  if (SettingsData.instance.system?.referEarnStatus == true)
                    AccountMenuTile(
                      icon: TablerIcons.moneybag,
                      title: l10n?.referAndEarn ?? 'Refer and Earn',
                      onTap: () => _pushOrLogin(AppRoutes.referAndEarnPage),
                    ),
                ]),

                _sectionLabel(context, l10n?.settings ?? 'Settings'),
                _menuCard(context, [
                  AccountMenuTile(
                    icon: Icons.person_outline,
                    title: l10n?.accountSettings ?? 'Account settings',
                    onTap: () => _pushOrLogin(AppRoutes.userProfile),
                  ),
                  AccountMenuTile(
                    icon: Icons.notifications_none,
                    title: l10n?.notifications ?? 'Notification',
                    onTap: () => _pushOrLogin(AppRoutes.notifications),
                  ),
                  GestureDetector(
                    onTapDown: (_) => _startHold(),
                    onTapUp: (_) => _cancelHold(),
                    onTapCancel: _cancelHold,
                    child: AccountMenuTile(
                      icon: TablerIcons.help_circle,
                      title: l10n?.support ?? 'Support',
                      onTap: () => _pushOrLogin(AppRoutes.supportPage),
                    ),
                  ),
                  BlocBuilder<LanguageBloc, LanguageState>(
                    builder: (context, state) {
                      String currentLanguage = 'English';
                      if (state is LanguageLoaded) {
                        final language = Global.supportedLanguages.firstWhere(
                          (lang) => lang['code'] == state.languageCode,
                          orElse: () => {'nativeName': 'English'},
                        );
                        currentLanguage = language['nativeName']!;
                      }
                      return AccountMenuTile(
                        icon: TablerIcons.language,
                        title: l10n?.language ?? 'Language',
                        subtitle:
                            "${l10n?.currentLanguage ?? 'Current'}: $currentLanguage",
                        onTap: () => LanguageBottomSheet.show(context),
                      );
                    },
                  ),
                  if(SettingsData.instance.system?.isDev ?? false)
                    StreamBuilder<String?>(
                      stream: MarketService.changes,
                      builder: (context, _) {
                        final countryName = MarketService.currentCountryName();
                        final countryIso = MarketService.currentCountryIso2();
                        final display = (countryName?.isNotEmpty == true)
                            ? countryName!
                            : (countryIso ?? '');
                        return AccountMenuTile(
                          icon: TablerIcons.world,
                          title: l10n?.country ?? 'Country',
                          subtitle: display.isEmpty
                              ? (l10n?.selectCountry ?? 'Select Country')
                              : "${l10n?.currentCountry ?? 'Current'}: $display",
                          onTap: () => CountryBottomSheet.show(context),
                        );
                      },
                    ),
                  AccountMenuTile(
                    icon: TablerIcons.building_store,
                    title: l10n?.stores ?? 'Stores',
                    onTap: () =>
                        GoRouter.of(context).push(AppRoutes.nearbyStores),
                  ),
                ]),

                _sectionLabel(context, l10n?.others ?? 'Others'),
                _menuCard(context, [
                  AccountMenuTile(
                    icon: Icons.info_outline,
                    title: l10n?.aboutUs ?? 'About us',
                    onTap: () => _openPolicy(PolicyType.aboutUs),
                  ),
                  AccountMenuTile(
                    icon: Icons.description_outlined,
                    title: l10n?.termsCondition ?? 'Terms & Condition',
                    onTap: () => _openPolicy(PolicyType.termsAndConditions),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.lock,
                    title: l10n?.privacyPolicy ?? 'Privacy Policy',
                    onTap: () => _openPolicy(PolicyType.privacyPolicy),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.rotate,
                    title: l10n?.refundPolicy ?? 'Refund Policy',
                    onTap: () => _openPolicy(PolicyType.refundPolicy),
                  ),
                  AccountMenuTile(
                    icon: TablerIcons.truck_delivery,
                    title: l10n?.shippingPolicy ?? 'Shipping Policy',
                    onTap: () => _openPolicy(PolicyType.shippingPolicy),
                  ),
                ]),

                SizedBox(height: 20.h),

                // Logout only — Delete account lives in Account settings.
                SectionCard(
                  child: loggedIn
                      ? AccountMenuTile(
                          icon: TablerIcons.logout,
                          title: l10n?.logout ?? 'Logout',
                          onTap: () => _showLogoutConfirmationDialog(context),
                        )

                      : AccountMenuTile(
                          icon: TablerIcons.login,
                          title: l10n?.signIn ?? 'Sign In',
                          onTap: () => GoRouter.of(context)
                          .pushReplacement(AppRoutes.login),
                        )
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileHeader(AppLocalizations? l10n) {
    return ValueListenableBuilder<UserDataModel?>(
      valueListenable: Global.userDataNotifier,
      builder: (context, userData, _) {
        final name = (userData?.name.isNotEmpty ?? false)
            ? userData!.name
            : (l10n?.signIn ?? 'Sign In');
        final image = userData?.profileImage ?? '';
        final hasImage = image.isNotEmpty && image != 'profile_image';

        return InkWell(
          onTap: () {
            if (userData != null && userData.token.isNotEmpty) {
              GoRouter.of(context).push(AppRoutes.userProfile);
            } else {
              GoRouter.of(context).pushReplacement(AppRoutes.login);
            }
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  backgroundImage: hasImage ? NetworkImage(image) : null,
                  child: !hasImage
                      ? const Icon(HugeIconsSolid.user02, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: isTablet(context) ? 22 : 18.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTheme.fontFamily,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      _memberSinceLine(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _memberSinceLine(AppLocalizations? l10n) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        if (state is! UserProfileLoaded) return const SizedBox.shrink();
        final created = state.userData.data?.createdAt;
        final dt = (created != null && created.isNotEmpty)
            ? DateTime.tryParse(created)
            : null;
        if (dt == null) return const SizedBox.shrink();
        final formatted = DateFormat('MMM-yyyy').format(dt);
        return Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Text(
            '${l10n?.memberSince ?? 'Member since'} $formatted',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 10.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isTablet(context) ? 20 : 15.sp,
          fontWeight: FontWeight.w700,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i != tiles.length - 1) {
        children.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
          ),
        ));
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          if (!isDarkMode(context))
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(TablerIcons.logout, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Text(l10n?.logout ?? "Logout"),
                ],
              ),
              content: Text(l10n?.logoutConfirmation ??
                  "Are you sure you want to log out?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    l10n?.cancel ?? "Cancel",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          context.read<AuthBloc>().add(LogoutUserRequest());
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n?.logout ?? 'Logout'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
