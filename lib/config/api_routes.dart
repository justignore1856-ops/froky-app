import 'dart:core';

import 'package:hyper_commerce/config/constant.dart';

class ApiRoutes {
  static String loginApi = '${AppConstant.baseUrl}login';
  static String registerApi = '${AppConstant.baseUrl}register';
  static String verifyUserApi = '${AppConstant.baseUrl}verify-user';
  static String forgotPasswordApi = '${AppConstant.baseUrl}forget-password';
  static String googleAuthApi = '${AppConstant.baseUrl}auth/google/callback';
  static String appleAuthApi = '${AppConstant.baseUrl}auth/apple/callback';
  static String mobileOtpAuthApi = '${AppConstant.baseUrl}auth/phone/callback';
  static String logoutApi = '${AppConstant.baseUrl}logout';
  static String categoryApi = '${AppConstant.baseUrl}categories';
  static String filterCategoryApi = '${AppConstant.baseUrl}categories/sidebar';
  static String filterProductApi =
      '${AppConstant.baseUrl}products/sidebar-filters';
  static String bannerApi = '${AppConstant.baseUrl}banners';
  static String homeLayoutApi = '${AppConstant.baseUrl}home-layout';
  static String homeTabApi = '${AppConstant.baseUrl}home-tab';
  // Full paginated items for one home-layout section. Append the section id.
  static String homeLayoutSectionApi =
      '${AppConstant.baseUrl}home-layout/sections/';
  static String featureSectionProductApi =
      '${AppConstant.baseUrl}featured-sections';
  static String subCategoryApi = '${AppConstant.baseUrl}categories';
  static String allTabSubCategoryApi =
      '${AppConstant.baseUrl}categories/sub-categories';
  static String productDetailApi = '${AppConstant.baseUrl}products/';
  static String brandsApi = '${AppConstant.baseUrl}brands';
  static String filterBrandsApi = '${AppConstant.baseUrl}brands/sidebar';
  static String addToCartApi = '${AppConstant.baseUrl}user/cart/add';
  static String categoryProductApi =
      '${AppConstant.baseUrl}markets/products';
  static String storeProductApi =
      '${AppConstant.baseUrl}markets/products';
  static String getCartApi = '${AppConstant.baseUrl}user/cart';
  static String removeItemFromCartApi = '${AppConstant.baseUrl}user/cart/item/';
  static String clearCartApi = '${AppConstant.baseUrl}user/cart/clear-cart';
  static String getSimilarProductApi =
      '${AppConstant.baseUrl}markets/products';
  static String addAddressApi = '${AppConstant.baseUrl}user/addresses';
  static String getAddressesApi = '${AppConstant.baseUrl}user/addresses';
  static String removeAddressesApi = '${AppConstant.baseUrl}user/addresses/';
  static String updateAddressesApi = '${AppConstant.baseUrl}user/addresses/';
  static String checkDeliveryZoneApi =
      '${AppConstant.baseUrl}delivery-zone/check';
  static String settingsApi = '${AppConstant.baseUrl}settings';
  static String createOrderApi = '${AppConstant.baseUrl}user/orders';
  static String getMyOrderApi = '${AppConstant.baseUrl}user/orders';
  static String getUserProfileApi = '${AppConstant.baseUrl}user/profile';
  static String updateUserProfileApi = '${AppConstant.baseUrl}user/profile';
  static String deleteUserApi = '${AppConstant.baseUrl}user/delete-account';
  static String getPromoCodeApi = '${AppConstant.baseUrl}user/promos/available';
  static String validatePromoCodeApi =
      '${AppConstant.baseUrl}user/promos/validate';
  static String orderDetailApi = '${AppConstant.baseUrl}user/orders/';
  static String payOrderApi(String slug) =>
      '${AppConstant.baseUrl}user/orders/$slug/pay';
  static String cancelPaymentApi(String slug) =>
      '${AppConstant.baseUrl}user/orders/$slug/cancel-payment';
  static String prepareWalletRechargeApi =
      '${AppConstant.baseUrl}user/wallet/prepare-wallet-recharge';
  static String userWalletApi = '${AppConstant.baseUrl}user/wallet';
  static String walletTransactionsApi =
      '${AppConstant.baseUrl}user/wallet/transactions';
  static String addProductFeedbackApi = '${AppConstant.baseUrl}reviews';
  static String updateProductFeedbackApi = '${AppConstant.baseUrl}reviews/';
  static String deleteProductFeedbackApi = '${AppConstant.baseUrl}reviews/';
  static String addSellerFeedbackApi = '${AppConstant.baseUrl}seller-feedback';
  static String updateSellerFeedbackApi =
      '${AppConstant.baseUrl}seller-feedback/';
  static String deleteSellerFeedbackApi =
      '${AppConstant.baseUrl}seller-feedback/';
  static String shoppingListApi =
      '${AppConstant.baseUrl}products/search-by-keywords';
  static String getWishlistApi = '${AppConstant.baseUrl}user/wishlists';
  static String createWishlistApi =
      '${AppConstant.baseUrl}user/wishlists/create';
  static String updateWishlistApi = '${AppConstant.baseUrl}user/wishlists/';
  static String deleteWishlistApi = '${AppConstant.baseUrl}user/wishlists/';
  static String moveItemToAnotherWishlistApi =
      '${AppConstant.baseUrl}user/wishlists/items/';
  static String searchApi = '${AppConstant.baseUrl}markets/products';
  static String wishlistProductApi = '${AppConstant.baseUrl}user/wishlists/';
  static String favoriteWishlistApi =
      '${AppConstant.baseUrl}user/wishlists/favorite';
  static String toggleFavoriteWishlistApi =
      '${AppConstant.baseUrl}user/wishlists/toggle';
  static String saveForLaterApi =
      '${AppConstant.baseUrl}user/cart/item/save-for-later';
  static String saveProductApi =
      '${AppConstant.baseUrl}user/cart/item/save-for-later/';
  static String specificFeatureSectionProductApi =
      '${AppConstant.baseUrl}featured-sections/';
  static String fetchStoresApi = '${AppConstant.baseUrl}stores';
  static String returnOrderItemApi = '${AppConstant.baseUrl}user/orders/items/';
  static String cancelReturnRequestApi =
      '${AppConstant.baseUrl}user/orders/items/';
  static String cancelOrderItemApi = '${AppConstant.baseUrl}user/orders/items/';
  static String storeDetailApi = '${AppConstant.baseUrl}stores/';
  static String flutterwaveApi =
      '${AppConstant.baseUrl}flutterwave/create-order';
  static String cartSyncApi = '${AppConstant.baseUrl}user/cart/sync';
  static String deliveryZonesApi = '${AppConstant.baseUrl}delivery-zone';
  static String deliveryZoneDetailApi = '${AppConstant.baseUrl}delivery-zone/';
  static String findStoresApi = '${AppConstant.baseUrl}stores/map';
  static String notificationsApi = '${AppConstant.baseUrl}user/notifications';
  static String supportThreadApi = '${AppConstant.baseUrl}user/support/thread';
  static String supportThreadMessagesApi =
      '${AppConstant.baseUrl}user/support/thread/messages';
  static String supportThreadUpdatesApi =
      '${AppConstant.baseUrl}user/support/thread/updates';
  static String supportRealtimeApi =
      '${AppConstant.baseUrl}user/support/realtime';
  static String supportTopicsApi = '${AppConstant.baseUrl}user/support/topics';
  static String supportSessionsApi =
      '${AppConstant.baseUrl}user/support/sessions';
  static String supportSessionMessagesApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/messages';
  static String supportSessionTypingApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/typing';
  static String supportSessionReadApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/read';
  static String supportSessionCallbacksApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/callbacks';
  static String supportSessionResolveApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/resolve';
  static String supportSessionRatingApi(String slug) =>
      '${AppConstant.baseUrl}user/support/sessions/$slug/rating';
  static String markNotificationAsReadApi(String id) =>
      '${AppConstant.baseUrl}user/notifications/$id/read';
  static String markAllNotificationsAsReadApi =
      '${AppConstant.baseUrl}user/notifications/mark-all-read';
  static String reOrderApi = '${AppConstant.baseUrl}user/orders/';
  static String sendCustomOtpApi = '${AppConstant.baseUrl}auth/send-otp';
  static String verifyCustomOtpApi = '${AppConstant.baseUrl}auth/verify-otp';
  static String versionCheckApi = '${AppConstant.baseUrl}settings/check-version';
  static String getReferInfoApi = '${AppConstant.baseUrl}user/referral';
  static String orderTransactionsApi =
      '${AppConstant.baseUrl}user/order-transactions';
  static String sendEmailVerificationLinkApi =
      '${AppConstant.baseUrl}user/update-email';
  static String resendEmailVerificationLinkApi =
      '${AppConstant.baseUrl}user/email/verification-notification';
  static String adBulkImpressionsApi =
      '${AppConstant.baseUrl}ads/bulk-impressions';
  static String adBulkClicksApi = '${AppConstant.baseUrl}ads/bulk-clicks';
  static String syncDeviceApi = '${AppConstant.baseUrl}devices/sync';
  static String applyReferralApi = '${AppConstant.baseUrl}user/referral/submit';
  static String emailSendOtpApi = '${AppConstant.baseUrl}auth/email/send-otp';
  static String emailVerifyOtpApi = '${AppConstant.baseUrl}auth/email/verify-otp';
  static String forgetPasswordSendOtpApi =
      '${AppConstant.baseUrl}forget-password/send-otp';
  static String forgetPasswordVerifyOtpApi =
      '${AppConstant.baseUrl}forget-password/verify-otp';
  static String resetPasswordApi = '${AppConstant.baseUrl}reset-password';
  static String geoCountriesApi = '${AppConstant.baseUrl}geo/countries';
  static String geoCitiesApi = '${AppConstant.baseUrl}geo/cities';
  static String resolvePincodeApi = '${AppConstant.baseUrl}geo/resolve-pincode';
  static String watchAndBuyReelsApi = '${AppConstant.baseUrl}watch-and-buy/reels';
  static String watchAndBuyLikesApi =
      '${AppConstant.baseUrl}watch-and-buy/reels/likes';
  static String watchAndBuyStatusFeedApi =
      '${AppConstant.baseUrl}watch-and-buy/statuses';
  static String watchAndBuyMarkStatusSeenApi =
      '${AppConstant.baseUrl}watch-and-buy/statuses/seen';
  static String watchAndBuyProfileStatusesApi(String username) =>
      '${AppConstant.baseUrl}watch-and-buy/profiles/$username/statuses';
  static String sellerProfileApi(String username) =>
      '${AppConstant.baseUrl}watch-and-buy/profiles/$username';
}
