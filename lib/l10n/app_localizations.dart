import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('te')
  ];

  /// No description provided for @supportDropMedia.
  ///
  /// In en, this message translates to:
  /// **'Drop images or PDFs to attach'**
  String get supportDropMedia;

  /// No description provided for @supportZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get supportZoomIn;

  /// No description provided for @supportZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get supportZoomOut;

  /// No description provided for @supportZoomReset.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get supportZoomReset;

  /// No description provided for @timelineOrderPlacedDone.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed'**
  String get timelineOrderPlacedDone;

  /// No description provided for @timelineOrderPlacedPending.
  ///
  /// In en, this message translates to:
  /// **'Order yet to be placed'**
  String get timelineOrderPlacedPending;

  /// No description provided for @timelinePaymentReceivedDone.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get timelinePaymentReceivedDone;

  /// No description provided for @timelinePaymentReceivedPending.
  ///
  /// In en, this message translates to:
  /// **'Payment yet to be received'**
  String get timelinePaymentReceivedPending;

  /// No description provided for @timelinePreparingDone.
  ///
  /// In en, this message translates to:
  /// **'Seller is preparing your order'**
  String get timelinePreparingDone;

  /// No description provided for @timelinePreparingPending.
  ///
  /// In en, this message translates to:
  /// **'Seller yet to process your order'**
  String get timelinePreparingPending;

  /// No description provided for @timelineShippedDone.
  ///
  /// In en, this message translates to:
  /// **'Your item has been shipped'**
  String get timelineShippedDone;

  /// No description provided for @timelineShippedPending.
  ///
  /// In en, this message translates to:
  /// **'Item yet to be shipped'**
  String get timelineShippedPending;

  /// No description provided for @timelineOutForDeliveryDone.
  ///
  /// In en, this message translates to:
  /// **'Your item is out for delivery'**
  String get timelineOutForDeliveryDone;

  /// No description provided for @timelineOutForDeliveryPending.
  ///
  /// In en, this message translates to:
  /// **'Item yet to be out for delivery'**
  String get timelineOutForDeliveryPending;

  /// No description provided for @timelineDeliveredDone.
  ///
  /// In en, this message translates to:
  /// **'Your item has been delivered'**
  String get timelineDeliveredDone;

  /// No description provided for @timelineDeliveredPending.
  ///
  /// In en, this message translates to:
  /// **'Item yet to be delivered'**
  String get timelineDeliveredPending;

  /// No description provided for @timelineReturnRequestedDone.
  ///
  /// In en, this message translates to:
  /// **'Return requested'**
  String get timelineReturnRequestedDone;

  /// No description provided for @timelineReturnRequestedPending.
  ///
  /// In en, this message translates to:
  /// **'Return yet to be requested'**
  String get timelineReturnRequestedPending;

  /// No description provided for @timelineReturnReceivedDone.
  ///
  /// In en, this message translates to:
  /// **'Return received by seller'**
  String get timelineReturnReceivedDone;

  /// No description provided for @timelineReturnReceivedPending.
  ///
  /// In en, this message translates to:
  /// **'Return yet to be received by seller'**
  String get timelineReturnReceivedPending;

  /// No description provided for @timelineRefundIssuedDone.
  ///
  /// In en, this message translates to:
  /// **'Refund processed'**
  String get timelineRefundIssuedDone;

  /// No description provided for @timelineRefundIssuedPending.
  ///
  /// In en, this message translates to:
  /// **'Refund yet to be processed'**
  String get timelineRefundIssuedPending;

  /// No description provided for @orderTrackStepConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderTrackStepConfirmed;

  /// No description provided for @orderTrackStepShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderTrackStepShipped;

  /// No description provided for @orderTrackStepDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get orderTrackStepDelivery;

  /// No description provided for @orderTrackSeeAllUpdates.
  ///
  /// In en, this message translates to:
  /// **'See all updates'**
  String get orderTrackSeeAllUpdates;

  /// No description provided for @viewReturnTimeline.
  ///
  /// In en, this message translates to:
  /// **'View return timeline'**
  String get viewReturnTimeline;

  /// No description provided for @returnStepRequestedDone.
  ///
  /// In en, this message translates to:
  /// **'Your return request was placed.'**
  String get returnStepRequestedDone;

  /// No description provided for @returnStepRequestedPending.
  ///
  /// In en, this message translates to:
  /// **'Return request not placed yet.'**
  String get returnStepRequestedPending;

  /// No description provided for @returnStepApprovedDone.
  ///
  /// In en, this message translates to:
  /// **'The seller approved your return.'**
  String get returnStepApprovedDone;

  /// No description provided for @returnStepApprovedPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the seller to approve your return.'**
  String get returnStepApprovedPending;

  /// No description provided for @returnStepPickedUpDone.
  ///
  /// In en, this message translates to:
  /// **'The item was picked up.'**
  String get returnStepPickedUpDone;

  /// No description provided for @returnStepPickedUpPending.
  ///
  /// In en, this message translates to:
  /// **'The item is yet to be picked up.'**
  String get returnStepPickedUpPending;

  /// No description provided for @returnStepReceivedDone.
  ///
  /// In en, this message translates to:
  /// **'The seller received the item.'**
  String get returnStepReceivedDone;

  /// No description provided for @returnStepReceivedPending.
  ///
  /// In en, this message translates to:
  /// **'The item is yet to reach the seller.'**
  String get returnStepReceivedPending;

  /// No description provided for @returnStepRefundedDone.
  ///
  /// In en, this message translates to:
  /// **'Your refund has been issued.'**
  String get returnStepRefundedDone;

  /// No description provided for @returnStepRefundedPending.
  ///
  /// In en, this message translates to:
  /// **'Refund will be issued after the item is received.'**
  String get returnStepRefundedPending;

  /// No description provided for @orderTrackSummaryPlaced.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed'**
  String get orderTrackSummaryPlaced;

  /// No description provided for @orderTrackSummaryConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your order is confirmed'**
  String get orderTrackSummaryConfirmed;

  /// No description provided for @orderTrackSummaryPreparing.
  ///
  /// In en, this message translates to:
  /// **'Seller is preparing your order'**
  String get orderTrackSummaryPreparing;

  /// No description provided for @orderTrackSummaryShipped.
  ///
  /// In en, this message translates to:
  /// **'Your order is on the way'**
  String get orderTrackSummaryShipped;

  /// No description provided for @orderTrackSummaryDelivered.
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered'**
  String get orderTrackSummaryDelivered;

  /// No description provided for @orderTrackSummaryReturned.
  ///
  /// In en, this message translates to:
  /// **'Your return is in progress'**
  String get orderTrackSummaryReturned;

  /// No description provided for @orderTrackSummaryRefunded.
  ///
  /// In en, this message translates to:
  /// **'Your refund has been processed'**
  String get orderTrackSummaryRefunded;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Hyper Local'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Hyper Local'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get gujarati;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get networkError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgain;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get enableLocation;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @changeAppTheme.
  ///
  /// In en, this message translates to:
  /// **'Change app theme'**
  String get changeAppTheme;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System mode'**
  String get systemMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @viewCouponOffers.
  ///
  /// In en, this message translates to:
  /// **'View Coupon & Offers'**
  String get viewCouponOffers;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @payUsing.
  ///
  /// In en, this message translates to:
  /// **'Pay Using'**
  String get payUsing;

  /// No description provided for @yourCartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get yourCartIsEmpty;

  /// No description provided for @yourShoppingBagIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping bag is empty'**
  String get yourShoppingBagIsEmpty;

  /// No description provided for @looksLikeYouHaventAddedAnythingYet.
  ///
  /// In en, this message translates to:
  /// **'Looks like you haven\'t added anything yet'**
  String get looksLikeYouHaventAddedAnythingYet;

  /// No description provided for @browseProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse products'**
  String get browseProducts;

  /// No description provided for @addMoreItemsTapped.
  ///
  /// In en, this message translates to:
  /// **'Add more items tapped!'**
  String get addMoreItemsTapped;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @areYouSureYouWantToRemoveItemFromCart.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {item} from cart?'**
  String areYouSureYouWantToRemoveItemFromCart(String item);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @deliversHere.
  ///
  /// In en, this message translates to:
  /// **'Delivers here'**
  String get deliversHere;

  /// No description provided for @notDeliverable.
  ///
  /// In en, this message translates to:
  /// **'Not deliverable'**
  String get notDeliverable;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @shippingLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shippingLabel;

  /// No description provided for @promo.
  ///
  /// In en, this message translates to:
  /// **'Promo'**
  String get promo;

  /// No description provided for @promoNote.
  ///
  /// In en, this message translates to:
  /// **'This promo has been applied to your order. The discount is reflected in your total amount.'**
  String get promoNote;

  /// No description provided for @applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get applied;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @cashbackLabel.
  ///
  /// In en, this message translates to:
  /// **'CASHBACK'**
  String get cashbackLabel;

  /// No description provided for @moreLabel.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get moreLabel;

  /// No description provided for @lessLabel.
  ///
  /// In en, this message translates to:
  /// **'LESS'**
  String get lessLabel;

  /// No description provided for @addMoreToAvailOffer.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} more to avail this offer'**
  String addMoreToAvailOffer(String amount);

  /// No description provided for @flatDiscountOnOrdersAbove.
  ///
  /// In en, this message translates to:
  /// **'Flat {discount} discount on orders above {minOrder}'**
  String flatDiscountOnOrdersAbove(String discount, String minOrder);

  /// No description provided for @percentOffOnOrdersAbove.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off on orders above {minOrder}'**
  String percentOffOnOrdersAbove(String percent, String minOrder);

  /// No description provided for @uptoCashbackOnOrdersAbove.
  ///
  /// In en, this message translates to:
  /// **'Upto {amount} cashback on orders above {minOrder}'**
  String uptoCashbackOnOrdersAbove(String amount, String minOrder);

  /// No description provided for @validTill.
  ///
  /// In en, this message translates to:
  /// **'Valid till {date}'**
  String validTill(String date);

  /// No description provided for @maxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Maximum discount {amount}'**
  String maxDiscount(String amount);

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String percentOff(int percent);

  /// No description provided for @saveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for Later'**
  String get saveForLater;

  /// No description provided for @billDetails.
  ///
  /// In en, this message translates to:
  /// **'Bill details'**
  String get billDetails;

  /// No description provided for @itemsTotal.
  ///
  /// In en, this message translates to:
  /// **'Items total'**
  String get itemsTotal;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @youreSavingOnOrder.
  ///
  /// In en, this message translates to:
  /// **'You\'re saving {amount} on this order'**
  String youreSavingOnOrder(Object amount);

  /// No description provided for @deliveryCharge.
  ///
  /// In en, this message translates to:
  /// **'Delivery charge'**
  String get deliveryCharge;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @perStoreDropOffFees.
  ///
  /// In en, this message translates to:
  /// **'Per store drop off fees'**
  String get perStoreDropOffFees;

  /// No description provided for @handlingCharge.
  ///
  /// In en, this message translates to:
  /// **'Handling charge'**
  String get handlingCharge;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @promoDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promo discount'**
  String get promoDiscount;

  /// No description provided for @removeCoupon.
  ///
  /// In en, this message translates to:
  /// **'Remove Coupon'**
  String get removeCoupon;

  /// No description provided for @totalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get totalPayable;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get grandTotal;

  /// No description provided for @yourTotalSavings.
  ///
  /// In en, this message translates to:
  /// **'Your total savings'**
  String get yourTotalSavings;

  /// No description provided for @downloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get downloadInvoice;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failedToLoadOrders;

  /// No description provided for @rateOrder.
  ///
  /// In en, this message translates to:
  /// **'Rate Order'**
  String get rateOrder;

  /// No description provided for @howWasYourOrder.
  ///
  /// In en, this message translates to:
  /// **'How was your order?'**
  String get howWasYourOrder;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @orderDetailsRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Order details refreshed'**
  String get orderDetailsRefreshed;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// No description provided for @failedToLoadOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order details'**
  String get failedToLoadOrderDetails;

  /// No description provided for @noItemsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No items to display'**
  String get noItemsToDisplay;

  /// No description provided for @deleteReview.
  ///
  /// In en, this message translates to:
  /// **'Delete Review?'**
  String get deleteReview;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @cancelItem.
  ///
  /// In en, this message translates to:
  /// **'Cancel item'**
  String get cancelItem;

  /// No description provided for @cancellationPeriodPassed.
  ///
  /// In en, this message translates to:
  /// **'Cancellation period has passed'**
  String get cancellationPeriodPassed;

  /// No description provided for @areYouSureYouWantToCancelThisItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this item?'**
  String get areYouSureYouWantToCancelThisItem;

  /// No description provided for @cancelReturnRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel return request'**
  String get cancelReturnRequest;

  /// No description provided for @areYouSureYouWantToCancelThisReturnRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this return request?'**
  String get areYouSureYouWantToCancelThisReturnRequest;

  /// No description provided for @cancelReturnRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Return Request'**
  String get cancelReturnRequestButton;

  /// No description provided for @cancelItemButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Item'**
  String get cancelItemButton;

  /// No description provided for @howWasYourShoppingExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your shopping experience?'**
  String get howWasYourShoppingExperience;

  /// No description provided for @trackDelivery.
  ///
  /// In en, this message translates to:
  /// **'Track Delivery'**
  String get trackDelivery;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery'**
  String get estimatedDelivery;

  /// No description provided for @myWishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get myWishlist;

  /// No description provided for @createNewWishlist.
  ///
  /// In en, this message translates to:
  /// **'Create new wishlist'**
  String get createNewWishlist;

  /// No description provided for @createNewWishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Wishlist'**
  String get createNewWishlistTitle;

  /// No description provided for @enterWishlistName.
  ///
  /// In en, this message translates to:
  /// **'Enter wishlist name'**
  String get enterWishlistName;

  /// No description provided for @pleaseEnterAWishlistName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a wishlist name'**
  String get pleaseEnterAWishlistName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @editWishlist.
  ///
  /// In en, this message translates to:
  /// **'Edit Wishlist'**
  String get editWishlist;

  /// No description provided for @noWishlistsYet.
  ///
  /// In en, this message translates to:
  /// **'No wishlists yet'**
  String get noWishlistsYet;

  /// No description provided for @noOtherWishlistsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No other wishlists available'**
  String get noOtherWishlistsAvailable;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @deleteWishlistName.
  ///
  /// In en, this message translates to:
  /// **'Delete {wishlistName}'**
  String deleteWishlistName(String wishlistName);

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @areYouSureYouWantToDeleteThisAddress.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this address?'**
  String get areYouSureYouWantToDeleteThisAddress;

  /// No description provided for @near.
  ///
  /// In en, this message translates to:
  /// **'Near'**
  String get near;

  /// No description provided for @noAddressSelected.
  ///
  /// In en, this message translates to:
  /// **'No address selected'**
  String get noAddressSelected;

  /// No description provided for @pleaseSelectAnImageAndEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please select an image and enter your name'**
  String get pleaseSelectAnImageAndEnterYourName;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @labelCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String labelCopiedToClipboard(String label);

  /// No description provided for @yourDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Your Delivery Address'**
  String get yourDeliveryAddress;

  /// No description provided for @shoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingList;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get aboutUs;

  /// No description provided for @termsCondition.
  ///
  /// In en, this message translates to:
  /// **'Terms & Condition'**
  String get termsCondition;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get refundPolicy;

  /// No description provided for @shippingPolicy.
  ///
  /// In en, this message translates to:
  /// **'Shipping Policy'**
  String get shippingPolicy;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @specification.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get specification;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @similarProducts.
  ///
  /// In en, this message translates to:
  /// **'Similar Products'**
  String get similarProducts;

  /// No description provided for @specifications.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get specifications;

  /// No description provided for @customerReviews.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviews;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @addYourReview.
  ///
  /// In en, this message translates to:
  /// **'Add Your Review'**
  String get addYourReview;

  /// No description provided for @rateThisProduct.
  ///
  /// In en, this message translates to:
  /// **'Rate this product'**
  String get rateThisProduct;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// No description provided for @questionAndAnswers.
  ///
  /// In en, this message translates to:
  /// **'Question and Answers'**
  String get questionAndAnswers;

  /// No description provided for @askAQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a Question'**
  String get askAQuestion;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @questionSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Question submitted successfully!'**
  String get questionSubmittedSuccessfully;

  /// No description provided for @pleaseSelectVariant.
  ///
  /// In en, this message translates to:
  /// **'Please select variant'**
  String get pleaseSelectVariant;

  /// No description provided for @viewProductDetails.
  ///
  /// In en, this message translates to:
  /// **'View Product Details'**
  String get viewProductDetails;

  /// No description provided for @productAddedToCartSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added to cart successfully!'**
  String get productAddedToCartSuccessfully;

  /// No description provided for @failedToAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to add product: {error}'**
  String failedToAddProduct(String error);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @storeClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get storeClosed;

  /// No description provided for @productVariants.
  ///
  /// In en, this message translates to:
  /// **'Product Variants'**
  String get productVariants;

  /// No description provided for @selectVariant.
  ///
  /// In en, this message translates to:
  /// **'Select variant'**
  String get selectVariant;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noProductFound.
  ///
  /// In en, this message translates to:
  /// **'No Product Found'**
  String get noProductFound;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @popularity.
  ///
  /// In en, this message translates to:
  /// **'Popularity'**
  String get popularity;

  /// No description provided for @searchResultFor.
  ///
  /// In en, this message translates to:
  /// **'Search result for \"{title}\"'**
  String searchResultFor(String title);

  /// No description provided for @relevanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Relevance (default)'**
  String get relevanceDefault;

  /// No description provided for @priceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price (low to high)'**
  String get priceLowToHigh;

  /// No description provided for @priceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price (high to low)'**
  String get priceHighToLow;

  /// No description provided for @discountHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Discount (high to low)'**
  String get discountHighToLow;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @startTypingForSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Start typing for suggestions'**
  String get startTypingForSuggestions;

  /// No description provided for @noSuggestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No suggestions found'**
  String get noSuggestionsFound;

  /// No description provided for @speak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get speak;

  /// No description provided for @trySayingSomething.
  ///
  /// In en, this message translates to:
  /// **'Try saying something'**
  String get trySayingSomething;

  /// No description provided for @speechStoppedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Speech stopped. Try again.'**
  String get speechStoppedTryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @searchForProducts.
  ///
  /// In en, this message translates to:
  /// **'Search for products'**
  String get searchForProducts;

  /// No description provided for @typeProductNameBrandOrCategory.
  ///
  /// In en, this message translates to:
  /// **'Type a product name, brand, or category to get started'**
  String get typeProductNameBrandOrCategory;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @trySearchingWithDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get trySearchingWithDifferentKeywords;

  /// No description provided for @nearbyStores.
  ///
  /// In en, this message translates to:
  /// **'Nearby Stores'**
  String get nearbyStores;

  /// No description provided for @noStoresFoundNearby.
  ///
  /// In en, this message translates to:
  /// **'No stores found nearby.'**
  String get noStoresFoundNearby;

  /// No description provided for @searchInStore.
  ///
  /// In en, this message translates to:
  /// **'Search in {storeName}'**
  String searchInStore(String storeName);

  /// No description provided for @savedForLater.
  ///
  /// In en, this message translates to:
  /// **'Saved for later'**
  String get savedForLater;

  /// No description provided for @moveToCart.
  ///
  /// In en, this message translates to:
  /// **'Move to Cart'**
  String get moveToCart;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add First Item'**
  String get addFirstItem;

  /// No description provided for @resultFor.
  ///
  /// In en, this message translates to:
  /// **'Result for \"{title}\"'**
  String resultFor(String title);

  /// No description provided for @addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add Money'**
  String get addMoney;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get enterAmount;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get note;

  /// No description provided for @hyperlocalWalletBalanceValidFor1Year.
  ///
  /// In en, this message translates to:
  /// **'Hyperlocal Wallet balance is valid for 1 year from the date of money added'**
  String get hyperlocalWalletBalanceValidFor1Year;

  /// No description provided for @hyperlocalWalletBalanceCannotBeTransferred.
  ///
  /// In en, this message translates to:
  /// **'Hyperlocal Wallet balance cannot be transfer to a bank account as per RBI guidelines'**
  String get hyperlocalWalletBalanceCannotBeTransferred;

  /// No description provided for @pleaseEnterAnAmountGreaterThanOrEqualTo1.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount greater than or equal to 1'**
  String get pleaseEnterAnAmountGreaterThanOrEqualTo1;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @promoCodeCoupons.
  ///
  /// In en, this message translates to:
  /// **'Promo Code & Coupons'**
  String get promoCodeCoupons;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @tapToContact.
  ///
  /// In en, this message translates to:
  /// **'Tap to contact'**
  String get tapToContact;

  /// No description provided for @rateStoreName.
  ///
  /// In en, this message translates to:
  /// **'Rate {storeName}'**
  String rateStoreName(String storeName);

  /// No description provided for @editYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edit your feedback'**
  String get editYourFeedback;

  /// No description provided for @howWasYourExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience?'**
  String get howWasYourExperience;

  /// No description provided for @tapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rate'**
  String get tapToRate;

  /// No description provided for @star.
  ///
  /// In en, this message translates to:
  /// **'{rating} Star'**
  String star(int rating);

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'{rating} Stars'**
  String stars(int rating);

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @egGreatService.
  ///
  /// In en, this message translates to:
  /// **'e.g., Great service!'**
  String get egGreatService;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionRequired;

  /// No description provided for @shareMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Share more details...'**
  String get shareMoreDetails;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @updateFeedback.
  ///
  /// In en, this message translates to:
  /// **'Update Feedback'**
  String get updateFeedback;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @deleteFeedback.
  ///
  /// In en, this message translates to:
  /// **'Delete Feedback'**
  String get deleteFeedback;

  /// No description provided for @areYouSureYouWantToDeleteThisFeedback.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this feedback?'**
  String get areYouSureYouWantToDeleteThisFeedback;

  /// No description provided for @pleaseGiveARating.
  ///
  /// In en, this message translates to:
  /// **'Please give a rating'**
  String get pleaseGiveARating;

  /// No description provided for @pleaseEnterATitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterATitle;

  /// No description provided for @pleaseEnterADescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get pleaseEnterADescription;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type'**
  String get deliveryType;

  /// No description provided for @rushDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rush Delivery'**
  String get rushDelivery;

  /// No description provided for @prioritizedDeliveryForYourUrgentNeeds.
  ///
  /// In en, this message translates to:
  /// **'Prioritized delivery for your urgent needs.'**
  String get prioritizedDeliveryForYourUrgentNeeds;

  /// No description provided for @regularDelivery.
  ///
  /// In en, this message translates to:
  /// **'Regular Delivery'**
  String get regularDelivery;

  /// No description provided for @standardDeliveryWithNoExtraCharges.
  ///
  /// In en, this message translates to:
  /// **'Standard delivery with no extra charges.'**
  String get standardDeliveryWithNoExtraCharges;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetConnection;

  /// No description provided for @appUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'App Under Maintenance'**
  String get appUnderMaintenance;

  /// No description provided for @noOrderFound.
  ///
  /// In en, this message translates to:
  /// **'No Order Found'**
  String get noOrderFound;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No Search Results'**
  String get noSearchResults;

  /// No description provided for @microphoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission or speech service unavailable'**
  String get microphoneUnavailable;

  /// No description provided for @speakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak Now'**
  String get speakNow;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @noSpeechDetected.
  ///
  /// In en, this message translates to:
  /// **'No speech detected'**
  String get noSpeechDetected;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get locationServices;

  /// No description provided for @appPermission.
  ///
  /// In en, this message translates to:
  /// **'App Permission'**
  String get appPermission;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with apple'**
  String get continueWithApple;

  /// No description provided for @continueWithMobile.
  ///
  /// In en, this message translates to:
  /// **'Continue with mobile'**
  String get continueWithMobile;

  /// No description provided for @continueWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Continue with OTP'**
  String get continueWithOtp;

  /// No description provided for @otpLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a one-time code to verify it\'s you.'**
  String get otpLoginSubtitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone and we\'ll send you a code to reset your password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @reviewsRatings.
  ///
  /// In en, this message translates to:
  /// **'Reviews & Ratings'**
  String get reviewsRatings;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @dialog.
  ///
  /// In en, this message translates to:
  /// **'Dialog'**
  String get dialog;

  /// No description provided for @looksLikeTheStoreCatchingSomeRest.
  ///
  /// In en, this message translates to:
  /// **'Looks like the store\'s catching some rest. Come back in a little while!'**
  String get looksLikeTheStoreCatchingSomeRest;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address Line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2Optional.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2 (Optional)'**
  String get addressLine2Optional;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @zipcode.
  ///
  /// In en, this message translates to:
  /// **'Zipcode'**
  String get zipcode;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @soldBy.
  ///
  /// In en, this message translates to:
  /// **'Sold by:'**
  String get soldBy;

  /// No description provided for @searchAnAreaOrAddress.
  ///
  /// In en, this message translates to:
  /// **'Search an area or address'**
  String get searchAnAreaOrAddress;

  /// No description provided for @describeTheIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get describeTheIssue;

  /// No description provided for @writeYourReviewHere.
  ///
  /// In en, this message translates to:
  /// **'Write your review here...'**
  String get writeYourReviewHere;

  /// No description provided for @typeYourQuestionHere.
  ///
  /// In en, this message translates to:
  /// **'Type your question here...'**
  String get typeYourQuestionHere;

  /// No description provided for @enterReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter review title'**
  String get enterReviewTitle;

  /// No description provided for @shareYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get shareYourThoughts;

  /// No description provided for @searchForAreaStreetName.
  ///
  /// In en, this message translates to:
  /// **'Search for area, street name...'**
  String get searchForAreaStreetName;

  /// No description provided for @pleaseSelectADeliveryAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery address first'**
  String get pleaseSelectADeliveryAddressFirst;

  /// No description provided for @paymentMethodNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Payment method not selected'**
  String get paymentMethodNotSelected;

  /// No description provided for @inclusiveOfAllTax.
  ///
  /// In en, this message translates to:
  /// **'(inclusive of all tax)'**
  String get inclusiveOfAllTax;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @packOf.
  ///
  /// In en, this message translates to:
  /// **'Pack Of'**
  String get packOf;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @madeIn.
  ///
  /// In en, this message translates to:
  /// **'Made In'**
  String get madeIn;

  /// No description provided for @indicator.
  ///
  /// In en, this message translates to:
  /// **'Indicator'**
  String get indicator;

  /// No description provided for @guaranteePeriod.
  ///
  /// In en, this message translates to:
  /// **'Guarantee Period'**
  String get guaranteePeriod;

  /// No description provided for @warrantyPeriod.
  ///
  /// In en, this message translates to:
  /// **'Warranty Period'**
  String get warrantyPeriod;

  /// No description provided for @returnable.
  ///
  /// In en, this message translates to:
  /// **'Returnable'**
  String get returnable;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current Language'**
  String get currentLanguage;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo Applied'**
  String get promoApplied;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get on;

  /// No description provided for @rushDeliveryActive.
  ///
  /// In en, this message translates to:
  /// **'Rush Delivery Active'**
  String get rushDeliveryActive;

  /// No description provided for @cashbackApplied.
  ///
  /// In en, this message translates to:
  /// **'Cashback Applied'**
  String get cashbackApplied;

  /// No description provided for @instantDiscountApplied.
  ///
  /// In en, this message translates to:
  /// **'Instant Discount Applied'**
  String get instantDiscountApplied;

  /// No description provided for @willBeAdded.
  ///
  /// In en, this message translates to:
  /// **'Will be added'**
  String get willBeAdded;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @clearCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to clear the cart?'**
  String get clearCartConfirm;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesClear.
  ///
  /// In en, this message translates to:
  /// **'Yes, clear'**
  String get yesClear;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @maxCartItemLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have reached maximum cart item limit'**
  String get maxCartItemLimitReached;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @shopByCategories.
  ///
  /// In en, this message translates to:
  /// **'Shop By Categories'**
  String get shopByCategories;

  /// No description provided for @topBrands.
  ///
  /// In en, this message translates to:
  /// **'Top Brands'**
  String get topBrands;

  /// No description provided for @addItemsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add items to get started'**
  String get addItemsToGetStarted;

  /// No description provided for @yourShoppingListIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get yourShoppingListIsEmpty;

  /// No description provided for @listItem.
  ///
  /// In en, this message translates to:
  /// **'List item'**
  String get listItem;

  /// No description provided for @itemsAdded.
  ///
  /// In en, this message translates to:
  /// **'items added'**
  String get itemsAdded;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get startShopping;

  /// No description provided for @typeItemName.
  ///
  /// In en, this message translates to:
  /// **'Type item name...'**
  String get typeItemName;

  /// No description provided for @pleaseAdd1ItemInShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 1 item in your shopping list'**
  String get pleaseAdd1ItemInShoppingList;

  /// No description provided for @selectDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Location'**
  String get selectDeliveryLocation;

  /// No description provided for @searchForAreaStreet.
  ///
  /// In en, this message translates to:
  /// **'Search for area, street name...'**
  String get searchForAreaStreet;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @useCurrentLocationHint.
  ///
  /// In en, this message translates to:
  /// **'See delivery dates for your area'**
  String get useCurrentLocationHint;

  /// No description provided for @gettingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get gettingYourLocation;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your current location'**
  String get couldNotGetLocation;

  /// No description provided for @setAsDefaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefaultAddress;

  /// No description provided for @defaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultAddress;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get myAccount;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @myTransactions.
  ///
  /// In en, this message translates to:
  /// **'My transactions'**
  String get myTransactions;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @selectDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Address'**
  String get selectDeliveryAddress;

  /// No description provided for @addAddressToContinue.
  ///
  /// In en, this message translates to:
  /// **'Add an address to continue'**
  String get addAddressToContinue;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not Logged In'**
  String get notLoggedIn;

  /// No description provided for @pleaseLoginToViewYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your profile'**
  String get pleaseLoginToViewYourProfile;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @trackYourDelivery.
  ///
  /// In en, this message translates to:
  /// **'Track your Delivery'**
  String get trackYourDelivery;

  /// No description provided for @returnItem.
  ///
  /// In en, this message translates to:
  /// **'Return Item'**
  String get returnItem;

  /// No description provided for @failedToLoadTrackingData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tracking data'**
  String get failedToLoadTrackingData;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @trackingLiveLocation.
  ///
  /// In en, this message translates to:
  /// **'Tracking live location'**
  String get trackingLiveLocation;

  /// No description provided for @arrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in'**
  String get arrivingIn;

  /// No description provided for @mins.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get mins;

  /// No description provided for @deliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Delivery Partner'**
  String get deliveryPartner;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery details'**
  String get deliveryDetails;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String copiedToClipboard(String label);

  /// No description provided for @orderIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Order ID copied!'**
  String get orderIdCopied;

  /// No description provided for @reasonForReturn.
  ///
  /// In en, this message translates to:
  /// **'Reason for return'**
  String get reasonForReturn;

  /// No description provided for @submitReturn.
  ///
  /// In en, this message translates to:
  /// **'Submit Return'**
  String get submitReturn;

  /// No description provided for @thisProductIsNotCancelable.
  ///
  /// In en, this message translates to:
  /// **'This product is not cancelable'**
  String get thisProductIsNotCancelable;

  /// No description provided for @productCanNoLongerBeCancelled.
  ///
  /// In en, this message translates to:
  /// **'This product can no longer be cancelled'**
  String get productCanNoLongerBeCancelled;

  /// No description provided for @thisProductIsNotReturnable.
  ///
  /// In en, this message translates to:
  /// **'This product is not returnable'**
  String get thisProductIsNotReturnable;

  /// No description provided for @returnButton.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnButton;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @moveToEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get moveToEllipsis;

  /// No description provided for @addToEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Add to…'**
  String get addToEllipsis;

  /// No description provided for @locationAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location Access Needed'**
  String get locationAccessNeeded;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @appPermissions.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get appPermissions;

  /// No description provided for @checkingEmail.
  ///
  /// In en, this message translates to:
  /// **'Checking email...'**
  String get checkingEmail;

  /// No description provided for @searchInStoreName.
  ///
  /// In en, this message translates to:
  /// **'Search in {storeName}'**
  String searchInStoreName(String storeName);

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @greatService.
  ///
  /// In en, this message translates to:
  /// **'e.g., Great service!'**
  String get greatService;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @emailOrPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @uploadImages.
  ///
  /// In en, this message translates to:
  /// **'Upload images'**
  String get uploadImages;

  /// No description provided for @tapToUploadPhotos.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload photos'**
  String get tapToUploadPhotos;

  /// No description provided for @helpUsUnderstandYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Help us understand your experience'**
  String get helpUsUnderstandYourExperience;

  /// No description provided for @youCanUploadUpToMaxImages.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to {max} images only.'**
  String youCanUploadUpToMaxImages(int max);

  /// No description provided for @onlyRemainingMoreImagesAdded.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} more image(s) added. Max limit: {max}.'**
  String onlyRemainingMoreImagesAdded(int remaining, int max);

  /// No description provided for @maxImagesAllowedExtensions.
  ///
  /// In en, this message translates to:
  /// **'• Max {max} images • {extensions} • {size} per image'**
  String maxImagesAllowedExtensions(int max, String extensions, String size);

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCart;

  /// No description provided for @clearAllItems.
  ///
  /// In en, this message translates to:
  /// **'Clear all items?'**
  String get clearAllItems;

  /// No description provided for @allItemsWillBeRemovedCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'All items will be removed and this action cannot be undone'**
  String get allItemsWillBeRemovedCannotBeUndone;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailedOrCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment failed or cancelled'**
  String get paymentFailedOrCancelled;

  /// No description provided for @failedToDeleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete address'**
  String get failedToDeleteAddress;

  /// No description provided for @pressAgainToExitTheApp.
  ///
  /// In en, this message translates to:
  /// **'Press again to exit the app'**
  String get pressAgainToExitTheApp;

  /// No description provided for @youHaveReachedMaximumLimitOfCart.
  ///
  /// In en, this message translates to:
  /// **'You have reached maximum limit of the cart'**
  String get youHaveReachedMaximumLimitOfCart;

  /// No description provided for @sellerInformationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Seller information not available'**
  String get sellerInformationNotAvailable;

  /// No description provided for @failedToRefreshOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh order details'**
  String get failedToRefreshOrderDetails;

  /// No description provided for @productSavedForLater.
  ///
  /// In en, this message translates to:
  /// **'{productName} is saved for later'**
  String productSavedForLater(String productName);

  /// No description provided for @promoCodeAppliedOnYourCart.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied on your cart'**
  String get promoCodeAppliedOnYourCart;

  /// No description provided for @youHaveCrossedMaximumCartAmountLimit.
  ///
  /// In en, this message translates to:
  /// **'You have crossed maximum cart amount limit. Please remove some products from cart'**
  String get youHaveCrossedMaximumCartAmountLimit;

  /// No description provided for @feedbackSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted successfully!'**
  String get feedbackSubmittedSuccessfully;

  /// No description provided for @feedbackUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback updated successfully!'**
  String get feedbackUpdatedSuccessfully;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @copiedToClipboardWithLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard!'**
  String copiedToClipboardWithLabel(String label);

  /// No description provided for @pleaseEnterCompleteOTP.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete OTP'**
  String get pleaseEnterCompleteOTP;

  /// No description provided for @verificationIdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Verification ID not found. Please try again.'**
  String get verificationIdNotFound;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phoneNumber}'**
  String otpSentTo(String phoneNumber);

  /// No description provided for @registrationDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Registration data not found. Please try again.'**
  String get registrationDataNotFound;

  /// No description provided for @noAccountFoundWithEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email or phone'**
  String get noAccountFoundWithEmailOrPhone;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered. Please use a different email.'**
  String get emailAlreadyRegistered;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @pleaseEnterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterYourPhoneNumber;

  /// No description provided for @pleaseEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPassword;

  /// No description provided for @passwordMustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMustBeAtLeast8Characters;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @otpVerified.
  ///
  /// In en, this message translates to:
  /// **'OTP Verified'**
  String get otpVerified;

  /// No description provided for @pleaseSelectAPaymentMethodFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method first'**
  String get pleaseSelectAPaymentMethodFirst;

  /// No description provided for @fetchingAddress.
  ///
  /// In en, this message translates to:
  /// **'Fetching address...'**
  String get fetchingAddress;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get selectedLocation;

  /// No description provided for @gettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address...'**
  String get gettingAddress;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @deliveryNotAvailableAtThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery not available at this location'**
  String get deliveryNotAvailableAtThisLocation;

  /// No description provided for @sorryWeDontDeliverHereYet.
  ///
  /// In en, this message translates to:
  /// **'Sorry! We don\'t deliver here yet'**
  String get sorryWeDontDeliverHereYet;

  /// No description provided for @thisLocationIsOutsideOurDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'This location is currently outside our delivery zone. Try searching for a nearby area or check back later.'**
  String get thisLocationIsOutsideOurDeliveryZone;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetails;

  /// No description provided for @pleaseEnterAddressLine1.
  ///
  /// In en, this message translates to:
  /// **'Please enter Address Line 1'**
  String get pleaseEnterAddressLine1;

  /// No description provided for @pleaseEnterCountry.
  ///
  /// In en, this message translates to:
  /// **'Please enter Country'**
  String get pleaseEnterCountry;

  /// No description provided for @pleaseEnterState.
  ///
  /// In en, this message translates to:
  /// **'Please enter State'**
  String get pleaseEnterState;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter City'**
  String get pleaseEnterCity;

  /// No description provided for @pleaseEnterZipcode.
  ///
  /// In en, this message translates to:
  /// **'Please enter Zipcode'**
  String get pleaseEnterZipcode;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @pleaseEnterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter mobile number'**
  String get pleaseEnterMobileNumber;

  /// No description provided for @saveAddressAs.
  ///
  /// In en, this message translates to:
  /// **'Save address as'**
  String get saveAddressAs;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @enterCompleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter Complete Address'**
  String get enterCompleteAddress;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @checkingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Checking delivery...'**
  String get checkingDelivery;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @confirmAddressToProceed.
  ///
  /// In en, this message translates to:
  /// **'Confirm Address to Proceed'**
  String get confirmAddressToProceed;

  /// No description provided for @addAddressToProceed.
  ///
  /// In en, this message translates to:
  /// **'Add Address to Proceed'**
  String get addAddressToProceed;

  /// No description provided for @deliveryNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Delivery Not Available'**
  String get deliveryNotAvailable;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInToYourAccount;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAnAccount;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @phoneNumberVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified successfully'**
  String get phoneNumberVerifiedSuccessfully;

  /// No description provided for @thisEmailIsNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is not registered. Please sign up first.'**
  String get thisEmailIsNotRegistered;

  /// No description provided for @thisPhoneNumberIsNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This phone number is not registered. Please sign up first.'**
  String get thisPhoneNumberIsNotRegistered;

  /// No description provided for @unableToVerifyUser.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify user. Please try again.'**
  String get unableToVerifyUser;

  /// No description provided for @emailOrPhoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number is required'**
  String get emailOrPhoneNumberIsRequired;

  /// No description provided for @enterValidEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter valid email or phone'**
  String get enterValidEmailOrPhone;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAnAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @emailAlreadyRegisteredUseDifferent.
  ///
  /// In en, this message translates to:
  /// **'Email already registered. Please use a different email.'**
  String get emailAlreadyRegisteredUseDifferent;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocation;

  /// No description provided for @chooseAddressForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Choose address for delivery'**
  String get chooseAddressForDelivery;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @tapCoinToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Tap coin to refresh'**
  String get tapCoinToRefresh;

  /// No description provided for @viewTransactions.
  ///
  /// In en, this message translates to:
  /// **'View Transactions'**
  String get viewTransactions;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @pleaseFillDetailsCreateYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the details to create your account'**
  String get pleaseFillDetailsCreateYourAccount;

  /// No description provided for @emailAvailable.
  ///
  /// In en, this message translates to:
  /// **'Email available'**
  String get emailAvailable;

  /// No description provided for @errorVerifyingEmail.
  ///
  /// In en, this message translates to:
  /// **'Error verifying email'**
  String get errorVerifyingEmail;

  /// No description provided for @pleaseAddYourDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Please add your delivery address'**
  String get pleaseAddYourDeliveryAddress;

  /// No description provided for @areYouSureDeleteFeedback.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete feedback'**
  String get areYouSureDeleteFeedback;

  /// No description provided for @addTo.
  ///
  /// In en, this message translates to:
  /// **'Add to…'**
  String get addTo;

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to…'**
  String get moveTo;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @mobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @rewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get rewardPoints;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get referralCode;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// No description provided for @pleaseCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get pleaseCheckConnection;

  /// No description provided for @noProfileDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No profile data available'**
  String get noProfileDataAvailable;

  /// No description provided for @giveYourDeliveryHeroFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give your delivery hero a feedback!'**
  String get giveYourDeliveryHeroFeedback;

  /// No description provided for @editYourFeedbackFor.
  ///
  /// In en, this message translates to:
  /// **'Edit your feedback for {name}'**
  String editYourFeedbackFor(String name);

  /// No description provided for @leaveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Feedback'**
  String get leaveFeedback;

  /// No description provided for @editFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edit Feedback'**
  String get editFeedback;

  /// No description provided for @editSellerFeedback.
  ///
  /// In en, this message translates to:
  /// **'Edit Seller Feedback'**
  String get editSellerFeedback;

  /// No description provided for @leaveSellerFeedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Seller Feedback'**
  String get leaveSellerFeedback;

  /// No description provided for @productNotApprovedBySeller.
  ///
  /// In en, this message translates to:
  /// **'This product is not approved by seller'**
  String get productNotApprovedBySeller;

  /// No description provided for @leaveItemFeedback.
  ///
  /// In en, this message translates to:
  /// **'Leave Item Feedback'**
  String get leaveItemFeedback;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash On Delivery'**
  String get cashOnDelivery;

  /// No description provided for @paidOnline.
  ///
  /// In en, this message translates to:
  /// **'Paid Online'**
  String get paidOnline;

  /// No description provided for @orderPlacedOn.
  ///
  /// In en, this message translates to:
  /// **'Order placed on {date}'**
  String orderPlacedOn(String date);

  /// No description provided for @locationAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'This app provides hyper-local services. Please enable location to get personalized recommendations and accurate results.'**
  String get locationAccessDescription;

  /// No description provided for @turnOnLocationServicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Turn on Location Services and grant app location permission to continue.'**
  String get turnOnLocationServicesDescription;

  /// No description provided for @loadingPaymentPage.
  ///
  /// In en, this message translates to:
  /// **'Loading payment page...'**
  String get loadingPaymentPage;

  /// No description provided for @youCanUploadUpToImagesOnly.
  ///
  /// In en, this message translates to:
  /// **'You can upload up to {count} images only.'**
  String youCanUploadUpToImagesOnly(int count);

  /// No description provided for @onlyMoreImagesAddedMaxLimit.
  ///
  /// In en, this message translates to:
  /// **'Only {remaining} more image(s) added. Max limit: {max}.'**
  String onlyMoreImagesAddedMaxLimit(int remaining, int max);

  /// No description provided for @onlinePaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Online Payment Methods'**
  String get onlinePaymentMethods;

  /// No description provided for @noCategoryFound.
  ///
  /// In en, this message translates to:
  /// **'No Category Found'**
  String get noCategoryFound;

  /// No description provided for @noStoreFound.
  ///
  /// In en, this message translates to:
  /// **'No Store Found'**
  String get noStoreFound;

  /// No description provided for @wereNotHereYet.
  ///
  /// In en, this message translates to:
  /// **'We’re not here yet'**
  String get wereNotHereYet;

  /// No description provided for @weCouldntFindAnyCategories.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any categories.'**
  String get weCouldntFindAnyCategories;

  /// No description provided for @weCouldntFindAnyStoreInYourSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any store in your select location.'**
  String get weCouldntFindAnyStoreInYourSelectLocation;

  /// No description provided for @phoneNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Phone number copied to clipboard!'**
  String get phoneNumberCopied;

  /// No description provided for @emailCopied.
  ///
  /// In en, this message translates to:
  /// **'Email copied to clipboard!'**
  String get emailCopied;

  /// No description provided for @pleaseWaitBeforeResending.
  ///
  /// In en, this message translates to:
  /// **'Please wait before resending.'**
  String get pleaseWaitBeforeResending;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To Pay:'**
  String get toPay;

  /// No description provided for @currentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Currently unavailable'**
  String get currentlyUnavailable;

  /// No description provided for @noStoresOrProductsAreAvailableInThisAreaRightNow.
  ///
  /// In en, this message translates to:
  /// **'No stores or products are available in this area right now.'**
  String get noStoresOrProductsAreAvailableInThisAreaRightNow;

  /// No description provided for @checkConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get checkConnectionAndTryAgain;

  /// No description provided for @weWillBeBackSoon.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be back soon. Hang tight!'**
  String get weWillBeBackSoon;

  /// No description provided for @noOrdersYetDescription.
  ///
  /// In en, this message translates to:
  /// **'It looks like you don\'t have any orders yet.'**
  String get noOrdersYetDescription;

  /// No description provided for @tryAdjustingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms.'**
  String get tryAdjustingSearchTerms;

  /// No description provided for @noProductMatchingSearch.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any products matching your search.'**
  String get noProductMatchingSearch;

  /// No description provided for @feedbackDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Review deleted successfully!'**
  String get feedbackDeletedSuccessfully;

  /// No description provided for @rateDeliveryHero.
  ///
  /// In en, this message translates to:
  /// **'Rate Delivery Hero'**
  String get rateDeliveryHero;

  /// No description provided for @howWasTheDelivery.
  ///
  /// In en, this message translates to:
  /// **'How was the delivery?'**
  String get howWasTheDelivery;

  /// No description provided for @egSuperFastDelivery.
  ///
  /// In en, this message translates to:
  /// **'e.g., Super fast delivery!'**
  String get egSuperFastDelivery;

  /// No description provided for @youMightAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get youMightAlsoLike;

  /// No description provided for @storeCurrentlyClosed.
  ///
  /// In en, this message translates to:
  /// **'Store is currently closed'**
  String get storeCurrentlyClosed;

  /// No description provided for @minimumQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity is {minQty}'**
  String minimumQuantityRequired(Object minQty);

  /// No description provided for @maximumQuantityAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum {maxQty} items allowed'**
  String maximumQuantityAllowed(Object maxQty);

  /// No description provided for @quantityMustMatchStepFromMinimum.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be {minQty}, or {minQty} plus a multiple of {stepSize}'**
  String quantityMustMatchStepFromMinimum(Object minQty, Object stepSize);

  /// No description provided for @onlyXItemsInStock.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} items available in stock'**
  String onlyXItemsInStock(Object stock);

  /// No description provided for @minimumCartAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Add {minAmount} more to reach the {miniCheckoutAmount} minimum checkout.'**
  String minimumCartAmountRequired(Object minAmount, Object miniCheckoutAmount);

  /// No description provided for @youHaveReachedMaximumLimitOfTheCart.
  ///
  /// In en, this message translates to:
  /// **'You can only add up to {allowedItems} items in your cart.'**
  String youHaveReachedMaximumLimitOfTheCart(Object allowedItems);

  /// No description provided for @onlyOneStoreAtATime.
  ///
  /// In en, this message translates to:
  /// **'You can only order from one store at a time'**
  String get onlyOneStoreAtATime;

  /// No description provided for @onlyFewLeft.
  ///
  /// In en, this message translates to:
  /// **'Only {stock} left!'**
  String onlyFewLeft(Object stock);

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @noTransactionYet.
  ///
  /// In en, this message translates to:
  /// **'No Transaction Yet'**
  String get noTransactionYet;

  /// No description provided for @noTransactionDescriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'Your wallet activity will appear here once'**
  String get noTransactionDescriptionMsg;

  /// No description provided for @noTransactionDescriptionSecondaryMsg.
  ///
  /// In en, this message translates to:
  /// **'you make your first transaction.'**
  String get noTransactionDescriptionSecondaryMsg;

  /// Shown when user tries to add items beyond cart limit
  ///
  /// In en, this message translates to:
  /// **'You can add only {remaining} more item(s) to your cart.'**
  String cannotAddMoreThanXItems(Object remaining);

  /// Simpler version of max items warning
  ///
  /// In en, this message translates to:
  /// **'You can add only {count} more item(s).'**
  String youCanAddOnlyXMoreItems(Object count);

  /// No description provided for @cartIsAlreadyAtMaximumLimit.
  ///
  /// In en, this message translates to:
  /// **'Your cart has reached the maximum item limit ({maxAllowed}).'**
  String cartIsAlreadyAtMaximumLimit(Object maxAllowed);

  /// No description provided for @cannotAddFromDifferentStore.
  ///
  /// In en, this message translates to:
  /// **'You can only add items from the same store. Please clear your cart or choose items from this store.'**
  String get cannotAddFromDifferentStore;

  /// No description provided for @cartAlreadyContainsMultipleStores.
  ///
  /// In en, this message translates to:
  /// **'Your cart already contains items from multiple stores. Please complete the current order or clear the cart first.'**
  String get cartAlreadyContainsMultipleStores;

  /// No description provided for @inCart.
  ///
  /// In en, this message translates to:
  /// **'in cart'**
  String get inCart;

  /// No description provided for @thisActionIsPermanent.
  ///
  /// In en, this message translates to:
  /// **'This action is PERMANENT.'**
  String get thisActionIsPermanent;

  /// No description provided for @allYourDataWillBeLostForever.
  ///
  /// In en, this message translates to:
  /// **'All your data will be lost forever.'**
  String get allYourDataWillBeLostForever;

  /// No description provided for @addYourFirstAddressToStart.
  ///
  /// In en, this message translates to:
  /// **'Add your first address to get started'**
  String get addYourFirstAddressToStart;

  /// No description provided for @noAddressFound.
  ///
  /// In en, this message translates to:
  /// **'No Address Found'**
  String get noAddressFound;

  /// No description provided for @includingAllTax.
  ///
  /// In en, this message translates to:
  /// **'(inclusive of all tax)'**
  String get includingAllTax;

  /// No description provided for @dataPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'data'**
  String get dataPlaceholder;

  /// No description provided for @writeYourNoteHere.
  ///
  /// In en, this message translates to:
  /// **'Write your note here...'**
  String get writeYourNoteHere;

  /// No description provided for @clearingYourCart.
  ///
  /// In en, this message translates to:
  /// **'Clearing your cart...'**
  String get clearingYourCart;

  /// No description provided for @imagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get imagesLabel;

  /// No description provided for @imagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG (Max 5MB)'**
  String get imagesSubtitle;

  /// No description provided for @pdfDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocumentLabel;

  /// No description provided for @pdfDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PDF files (Max 10MB)'**
  String get pdfDocumentSubtitle;

  /// No description provided for @wordDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Word Document'**
  String get wordDocumentLabel;

  /// No description provided for @wordDocumentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'DOCX files (Max 10MB)'**
  String get wordDocumentSubtitle;

  /// No description provided for @cannotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: {url}'**
  String cannotOpenFile(String url);

  /// No description provided for @errorOpeningAttachment.
  ///
  /// In en, this message translates to:
  /// **'Error opening attachment: {error}'**
  String errorOpeningAttachment(String error);

  /// No description provided for @paystackPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Paystack Payment'**
  String get paystackPaymentTitle;

  /// No description provided for @enableLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocationTitle;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @youWillBeResponsible.
  ///
  /// In en, this message translates to:
  /// **'you will be responsible'**
  String get youWillBeResponsible;

  /// No description provided for @deleteWishlistConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this wishlist?'**
  String get deleteWishlistConfirmation;

  /// No description provided for @noReviewsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reviews available'**
  String get noReviewsAvailable;

  /// No description provided for @searchForStore.
  ///
  /// In en, this message translates to:
  /// **'Search for store'**
  String get searchForStore;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @introPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Shop with Confidence'**
  String get introPage1Title;

  /// No description provided for @introPage1Description.
  ///
  /// In en, this message translates to:
  /// **'Discover thousands of products from trusted sellers with secure payments and fast delivery.'**
  String get introPage1Description;

  /// No description provided for @introPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Track Your Orders'**
  String get introPage2Title;

  /// No description provided for @introPage2Description.
  ///
  /// In en, this message translates to:
  /// **'Stay updated with real-time tracking and get notifications about your order status.'**
  String get introPage2Description;

  /// No description provided for @introPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Easy Returns'**
  String get introPage3Title;

  /// No description provided for @introPage3Description.
  ///
  /// In en, this message translates to:
  /// **'Not satisfied? Return your items hassle-free with our 30-day return policy.'**
  String get introPage3Description;

  /// No description provided for @pleaseEnterAtleast2Letters.
  ///
  /// In en, this message translates to:
  /// **'Please enter atleast 2 letters'**
  String get pleaseEnterAtleast2Letters;

  /// No description provided for @atleast1ItemIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Atleast 1 item is required'**
  String get atleast1ItemIsRequired;

  /// No description provided for @enterYourPhoneNumberToReceiveOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we’ll send you an OTP to verify.'**
  String get enterYourPhoneNumberToReceiveOtp;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @phoneNumberTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too short'**
  String get phoneNumberTooShort;

  /// No description provided for @deliveryZones.
  ///
  /// In en, this message translates to:
  /// **'Delivery Zones'**
  String get deliveryZones;

  /// No description provided for @searchDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'Search Delivery Zone'**
  String get searchDeliveryZone;

  /// No description provided for @zoneDetails.
  ///
  /// In en, this message translates to:
  /// **'Zone Details'**
  String get zoneDetails;

  /// No description provided for @viewDetailsAboutDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'View details about delivery zone'**
  String get viewDetailsAboutDeliveryZone;

  /// No description provided for @zoneInformation.
  ///
  /// In en, this message translates to:
  /// **'Zone Information'**
  String get zoneInformation;

  /// No description provided for @zoneId.
  ///
  /// In en, this message translates to:
  /// **'Zone ID'**
  String get zoneId;

  /// No description provided for @zoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone Name'**
  String get zoneName;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @deliveryFees.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fees'**
  String get deliveryFees;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @freeDeliveryAbove.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery Above'**
  String get freeDeliveryAbove;

  /// No description provided for @perKMCharge.
  ///
  /// In en, this message translates to:
  /// **'Per KM Charge'**
  String get perKMCharge;

  /// No description provided for @perStoreFee.
  ///
  /// In en, this message translates to:
  /// **'Per Store Fee'**
  String get perStoreFee;

  /// No description provided for @deliveryTimes.
  ///
  /// In en, this message translates to:
  /// **'Delivery Times'**
  String get deliveryTimes;

  /// No description provided for @regularTimePerKM.
  ///
  /// In en, this message translates to:
  /// **'Regular Time Per KM'**
  String get regularTimePerKM;

  /// No description provided for @bufferTime.
  ///
  /// In en, this message translates to:
  /// **'Buffer Time'**
  String get bufferTime;

  /// No description provided for @coverageDetails.
  ///
  /// In en, this message translates to:
  /// **'Coverage Details'**
  String get coverageDetails;

  /// No description provided for @radius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get radius;

  /// No description provided for @centerCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Center Coordinates'**
  String get centerCoordinates;

  /// No description provided for @boundaryPoints.
  ///
  /// In en, this message translates to:
  /// **'Boundary Points'**
  String get boundaryPoints;

  /// No description provided for @handlingFee.
  ///
  /// In en, this message translates to:
  /// **'Handling Fee'**
  String get handlingFee;

  /// No description provided for @coverageRadius.
  ///
  /// In en, this message translates to:
  /// **'Coverage Radius'**
  String get coverageRadius;

  /// No description provided for @noteThisStoreIsNOtAvailableInYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Note: This store is not available in your location.'**
  String get noteThisStoreIsNOtAvailableInYourLocation;

  /// No description provided for @rush.
  ///
  /// In en, this message translates to:
  /// **'Rush'**
  String get rush;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @yourWishlistIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your Wishlist is Empty'**
  String get yourWishlistIsEmpty;

  /// No description provided for @createYourFirstWishlistToOrganizeAndSaveItemsYouHave.
  ///
  /// In en, this message translates to:
  /// **'Create your first wishlist to organize and save items you love'**
  String get createYourFirstWishlistToOrganizeAndSaveItemsYouHave;

  /// No description provided for @viewOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'View Order Details'**
  String get viewOrderDetails;

  /// No description provided for @phoneNumberAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Phone number is already registered'**
  String get phoneNumberAlreadyRegistered;

  /// No description provided for @pleaseSelectAValidCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid country code'**
  String get pleaseSelectAValidCountryCode;

  /// No description provided for @phoneNumberAvailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number is available'**
  String get phoneNumberAvailable;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @noPromoCodesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Promo Codes Available'**
  String get noPromoCodesAvailable;

  /// No description provided for @thereAreNoActivePromoCodeOrCouponsAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'There are no active promo codes or coupons available right now'**
  String get thereAreNoActivePromoCodeOrCouponsAvailableRightNow;

  /// No description provided for @phoneNumberTooLong.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too long'**
  String get phoneNumberTooLong;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @forceUpdateDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. Please update to continue using the app.'**
  String get forceUpdateDialogMessage;

  /// No description provided for @doItLater.
  ///
  /// In en, this message translates to:
  /// **'Do it later'**
  String get doItLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer version of the app is being prepared. It will be available on the store shortly.\n\nThank you for your patience!'**
  String get comingSoonMessage;

  /// No description provided for @referralCodeHintText.
  ///
  /// In en, this message translates to:
  /// **'Referral Code (Optional)'**
  String get referralCodeHintText;

  /// No description provided for @referAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer and Earn'**
  String get referAndEarn;

  /// No description provided for @failedToLoadReferralData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load referral data'**
  String get failedToLoadReferralData;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get codeCopied;

  /// No description provided for @appLink.
  ///
  /// In en, this message translates to:
  /// **'App Link'**
  String get appLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get linkCopied;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @shareYourCode.
  ///
  /// In en, this message translates to:
  /// **'Share Your Code'**
  String get shareYourCode;

  /// No description provided for @sendYourReferralCodeOrAppLinkToFriends.
  ///
  /// In en, this message translates to:
  /// **'Send your referral code or app link to friends.'**
  String get sendYourReferralCodeOrAppLinkToFriends;

  /// No description provided for @friendSignsUp.
  ///
  /// In en, this message translates to:
  /// **'Friend Signs Up'**
  String get friendSignsUp;

  /// No description provided for @theyRegisterUsingYourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'They register using your referral code.'**
  String get theyRegisterUsingYourReferralCode;

  /// No description provided for @youEarn.
  ///
  /// In en, this message translates to:
  /// **'You Earn'**
  String get youEarn;

  /// No description provided for @whenTheyCompleteTheirFirstOrderYouEarn.
  ///
  /// In en, this message translates to:
  /// **'When they complete their first order, you earn'**
  String get whenTheyCompleteTheirFirstOrderYouEarn;

  /// No description provided for @upTo.
  ///
  /// In en, this message translates to:
  /// **'up to'**
  String get upTo;

  /// No description provided for @shareNow.
  ///
  /// In en, this message translates to:
  /// **'Share Now'**
  String get shareNow;

  /// No description provided for @referAndEarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer your friends & earn rewards'**
  String get referAndEarnTitle;

  /// No description provided for @referAndEarnDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends using your referral code and earn rewards when they sign up and place their first order'**
  String get referAndEarnDescription;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @subCategories.
  ///
  /// In en, this message translates to:
  /// **'Sub Categories'**
  String get subCategories;

  /// No description provided for @addonGroupRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one option'**
  String get addonGroupRequiredError;

  /// No description provided for @editAddOnsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Add-ons'**
  String get editAddOnsTitle;

  /// No description provided for @noAddOnsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No add-ons available for this item'**
  String get noAddOnsAvailable;

  /// No description provided for @addOnsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load add-ons'**
  String get addOnsLoadError;

  /// No description provided for @addonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get addonsTitle;

  /// No description provided for @addonHintSelectOneRequired.
  ///
  /// In en, this message translates to:
  /// **'Select 1 (required)'**
  String get addonHintSelectOneRequired;

  /// No description provided for @addonHintSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Select any 1'**
  String get addonHintSelectOne;

  /// No description provided for @addonHintSelectAtLeastOneRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least 1 (required)'**
  String get addonHintSelectAtLeastOneRequired;

  /// No description provided for @addonHintSelectAny.
  ///
  /// In en, this message translates to:
  /// **'Select any'**
  String get addonHintSelectAny;

  /// No description provided for @addonRequiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get addonRequiredBadge;

  /// No description provided for @addonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get addonUnavailable;

  /// No description provided for @yourCustomisations.
  ///
  /// In en, this message translates to:
  /// **'Your Customisations'**
  String get yourCustomisations;

  /// No description provided for @addNewCustomisation.
  ///
  /// In en, this message translates to:
  /// **'Add new customisation'**
  String get addNewCustomisation;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pleaseVerifyEmailAndMobileBeforePlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email and mobile number before placing the order.'**
  String get pleaseVerifyEmailAndMobileBeforePlacingOrder;

  /// No description provided for @pleaseVerifyMobileBeforePlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Please verify your mobile number before placing the order.'**
  String get pleaseVerifyMobileBeforePlacingOrder;

  /// No description provided for @pleaseVerifyEmailBeforePlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before placing the order.'**
  String get pleaseVerifyEmailBeforePlacingOrder;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// No description provided for @mobileVerification.
  ///
  /// In en, this message translates to:
  /// **'Mobile Verification'**
  String get mobileVerification;

  /// No description provided for @sendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Email'**
  String get sendVerificationEmail;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @checkVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Verification Status'**
  String get checkVerificationStatus;

  /// No description provided for @verificationLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to your email address. Open it in your browser to finish verifying.'**
  String get verificationLinkSentMessage;

  /// No description provided for @verificationEmailSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSentSuccessfully;

  /// No description provided for @emailIsNowVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email is now verified'**
  String get emailIsNowVerified;

  /// No description provided for @emailStillNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email is not verified yet. Please check your inbox and open the link.'**
  String get emailStillNotVerified;

  /// No description provided for @addEmail.
  ///
  /// In en, this message translates to:
  /// **'Add Email'**
  String get addEmail;

  /// No description provided for @addMobile.
  ///
  /// In en, this message translates to:
  /// **'Add Mobile'**
  String get addMobile;

  /// No description provided for @customisable.
  ///
  /// In en, this message translates to:
  /// **'Customisable'**
  String get customisable;

  /// No description provided for @onlyNumbersAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only numbers allowed'**
  String get onlyNumbersAllowed;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get verifyYourPhone;

  /// No description provided for @weSentVerificationCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to'**
  String get weSentVerificationCodeTo;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code?'**
  String get didntReceiveCode;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Countdown shown on the OTP screen until the user can request a new code.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} s'**
  String resendInSeconds(int seconds);

  /// Badge shown on product cards highlighted by the seller / system as recommended for the user.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Badge shown on product cards that are part of an advertisement campaign.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get sponsored;

  /// No description provided for @repeatOrder.
  ///
  /// In en, this message translates to:
  /// **'Repeat order'**
  String get repeatOrder;

  /// No description provided for @orderNote.
  ///
  /// In en, this message translates to:
  /// **'Order note'**
  String get orderNote;

  /// No description provided for @noteForDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Note for the delivery partner'**
  String get noteForDeliveryPartner;

  /// No description provided for @needHelpWithOrder.
  ///
  /// In en, this message translates to:
  /// **'Need help with this order?'**
  String get needHelpWithOrder;

  /// No description provided for @statusPlaced.
  ///
  /// In en, this message translates to:
  /// **'PLACED'**
  String get statusPlaced;

  /// No description provided for @statusPartiallyAccepted.
  ///
  /// In en, this message translates to:
  /// **'PARTIALLY ACCEPTED'**
  String get statusPartiallyAccepted;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get statusConfirmed;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'PREPARING'**
  String get statusPreparing;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'SHIPPED'**
  String get statusShipped;

  /// No description provided for @statusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'OUT FOR DELIVERY'**
  String get statusOutForDelivery;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'DELIVERED'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get statusCancelled;

  /// No description provided for @statusReturned.
  ///
  /// In en, this message translates to:
  /// **'RETURNED'**
  String get statusReturned;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get statusFailed;

  /// No description provided for @statusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'READY FOR PICKUP'**
  String get statusReadyForPickup;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'ASSIGNED'**
  String get statusAssigned;

  /// No description provided for @heroAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get heroAwaitingConfirmation;

  /// No description provided for @heroReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready for pickup'**
  String get heroReadyForPickup;

  /// No description provided for @heroAssigned.
  ///
  /// In en, this message translates to:
  /// **'Delivery partner assigned'**
  String get heroAssigned;

  /// No description provided for @secondaryAssigned.
  ///
  /// In en, this message translates to:
  /// **'A delivery partner is heading to pick up your order'**
  String get secondaryAssigned;

  /// No description provided for @heroPartiallyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order partially accepted'**
  String get heroPartiallyAccepted;

  /// No description provided for @heroStorePreparing.
  ///
  /// In en, this message translates to:
  /// **'Store is preparing your order'**
  String get heroStorePreparing;

  /// No description provided for @heroArrivingBy.
  ///
  /// In en, this message translates to:
  /// **'Arriving by {time}'**
  String heroArrivingBy(String time);

  /// No description provided for @shipmentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shipment} other{{count} shipments}}'**
  String shipmentCount(int count);

  /// No description provided for @shipmentItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String shipmentItemCount(int count);

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size {size}'**
  String sizeLabel(String size);

  /// No description provided for @heroOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get heroOnTheWay;

  /// No description provided for @secondaryReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Head to the store to collect your order'**
  String get secondaryReadyForPickup;

  /// No description provided for @heroDeliveredOnTime.
  ///
  /// In en, this message translates to:
  /// **'Delivered on time'**
  String get heroDeliveredOnTime;

  /// No description provided for @heroDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get heroDelivered;

  /// No description provided for @heroOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get heroOrderCancelled;

  /// No description provided for @heroReturnedAndRefunded.
  ///
  /// In en, this message translates to:
  /// **'Returned & refunded'**
  String get heroReturnedAndRefunded;

  /// No description provided for @heroPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get heroPaymentFailed;

  /// No description provided for @heroRunningLate.
  ///
  /// In en, this message translates to:
  /// **'Running a bit late'**
  String get heroRunningLate;

  /// No description provided for @secondaryPlacedAndEta.
  ///
  /// In en, this message translates to:
  /// **'Placed {placed} · ETA {eta}'**
  String secondaryPlacedAndEta(String placed, String eta);

  /// No description provided for @secondaryUsuallyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Usually accepted in 2 min'**
  String get secondaryUsuallyAccepted;

  /// No description provided for @secondaryPartialItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items unavailable'**
  String secondaryPartialItems(int count);

  /// No description provided for @itemCountAccepted.
  ///
  /// In en, this message translates to:
  /// **'{count} accepted'**
  String itemCountAccepted(int count);

  /// No description provided for @itemCountPreparing.
  ///
  /// In en, this message translates to:
  /// **'{count} preparing'**
  String itemCountPreparing(int count);

  /// No description provided for @itemCountRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} rejected'**
  String itemCountRejected(int count);

  /// No description provided for @itemCountPending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String itemCountPending(int count);

  /// No description provided for @secondaryDistanceAway.
  ///
  /// In en, this message translates to:
  /// **'{name} is {distance} away · ~{minutes} min'**
  String secondaryDistanceAway(String name, String distance, int minutes);

  /// No description provided for @secondaryDeliveredOn.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time}'**
  String secondaryDeliveredOn(String date, String time);

  /// No description provided for @secondaryCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by you · {date}'**
  String secondaryCancelledByYou(String date);

  /// No description provided for @secondaryCancelledByStore.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by store · {date}'**
  String secondaryCancelledByStore(String date);

  /// No description provided for @secondaryItemsReturned.
  ///
  /// In en, this message translates to:
  /// **'{count} items returned · {date}'**
  String secondaryItemsReturned(int count, String date);

  /// No description provided for @secondaryExpectedBy.
  ///
  /// In en, this message translates to:
  /// **'Expected by {time}'**
  String secondaryExpectedBy(String time);

  /// No description provided for @expectedDeliveryBetween.
  ///
  /// In en, this message translates to:
  /// **'Delivery between {start} - {end}'**
  String expectedDeliveryBetween(String start, String end);

  /// No description provided for @actionTrackDelivery.
  ///
  /// In en, this message translates to:
  /// **'Track delivery'**
  String get actionTrackDelivery;

  /// No description provided for @actionTrackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get actionTrackOrder;

  /// No description provided for @actionCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get actionCancelOrder;

  /// No description provided for @actionReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get actionReorder;

  /// No description provided for @actionReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get actionReturn;

  /// No description provided for @actionRetryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry payment'**
  String get actionRetryPayment;

  /// No description provided for @refundProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get refundProcessing;

  /// No description provided for @refundCredited.
  ///
  /// In en, this message translates to:
  /// **'Credited'**
  String get refundCredited;

  /// No description provided for @refundProcessingNote.
  ///
  /// In en, this message translates to:
  /// **'{amount} will be credited to your wallet in 1–3 days'**
  String refundProcessingNote(String amount);

  /// No description provided for @refundCreditedNote.
  ///
  /// In en, this message translates to:
  /// **'{amount} added to your wallet on {date}'**
  String refundCreditedNote(String amount, String date);

  /// No description provided for @refundStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund status'**
  String get refundStatusLabel;

  /// No description provided for @refundLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundLabel;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @viewMoreItems.
  ///
  /// In en, this message translates to:
  /// **'View {count} more items'**
  String viewMoreItems(int count);

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @qtyShort.
  ///
  /// In en, this message translates to:
  /// **'Qty {count}'**
  String qtyShort(int count);

  /// No description provided for @otpChip.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpChip;

  /// No description provided for @ratingExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get ratingExperience;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get totalPaid;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @deliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to'**
  String get deliveredTo;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @placedOn.
  ///
  /// In en, this message translates to:
  /// **'Placed on'**
  String get placedOn;

  /// No description provided for @invoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceLabel;

  /// No description provided for @downloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadLabel;

  /// No description provided for @addressTypeHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get addressTypeHome;

  /// No description provided for @addressTypeWork.
  ///
  /// In en, this message translates to:
  /// **'WORK'**
  String get addressTypeWork;

  /// No description provided for @addressTypeOther.
  ///
  /// In en, this message translates to:
  /// **'OTHER'**
  String get addressTypeOther;

  /// No description provided for @errorLoadingOrder.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load order details'**
  String get errorLoadingOrder;

  /// No description provided for @retryLabel.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLabel;

  /// No description provided for @waitingForStoreToAccept.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the store to accept your order'**
  String get waitingForStoreToAccept;

  /// No description provided for @partialOrderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Some items are unavailable. Please review your order'**
  String get partialOrderAccepted;

  /// No description provided for @trackingOrder.
  ///
  /// In en, this message translates to:
  /// **'Tracking Order'**
  String get trackingOrder;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered'**
  String get orderDelivered;

  /// No description provided for @successfullyDelivered.
  ///
  /// In en, this message translates to:
  /// **'Successfully Delivered'**
  String get successfullyDelivered;

  /// No description provided for @orderDeliveredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully delivered'**
  String get orderDeliveredSuccessfully;

  /// No description provided for @shortly.
  ///
  /// In en, this message translates to:
  /// **'shortly'**
  String get shortly;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesLabel;

  /// No description provided for @destinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destinationLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @hurryOnlyLeft.
  ///
  /// In en, this message translates to:
  /// **'Hurry! Only {count} left'**
  String hurryOnlyLeft(int count);

  /// No description provided for @nReviews.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String nReviews(int count);

  /// No description provided for @checkOutThisProduct.
  ///
  /// In en, this message translates to:
  /// **'Take a look at this product!'**
  String get checkOutThisProduct;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @orderTransaction.
  ///
  /// In en, this message translates to:
  /// **'Order transactions'**
  String get orderTransaction;

  /// No description provided for @authMessage.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue. This helps us save your preferences and keep your shopping journey seamless.'**
  String get authMessage;

  /// No description provided for @referralCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Got an invite code?'**
  String get referralCodeTitle;

  /// No description provided for @referralCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply a friend\'s invite code to unlock rewards. You can also skip this step.'**
  String get referralCodeSubtitle;

  /// No description provided for @referralCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code'**
  String get referralCodeHint;

  /// No description provided for @referralCodePrefilledHint.
  ///
  /// In en, this message translates to:
  /// **'Code added from your invite link'**
  String get referralCodePrefilledHint;

  /// No description provided for @applyReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyReferralCode;

  /// No description provided for @skipReferral.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipReferral;

  /// No description provided for @referralAppliedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied'**
  String get referralAppliedSuccess;

  /// No description provided for @referralFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update referral. Please try again.'**
  String get referralFailedRetry;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @currentCountry.
  ///
  /// In en, this message translates to:
  /// **'Current Country'**
  String get currentCountry;

  /// No description provided for @countrySwitched.
  ///
  /// In en, this message translates to:
  /// **'Country updated'**
  String get countrySwitched;

  /// No description provided for @countrySwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change country. Please try again.'**
  String get countrySwitchFailed;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @addressPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an address to set your shipping country'**
  String get addressPickerHint;

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet.'**
  String get noSavedAddresses;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickOnMap;

  /// No description provided for @manageAddresses.
  ///
  /// In en, this message translates to:
  /// **'Manage addresses'**
  String get manageAddresses;

  /// No description provided for @loginToSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save and pick addresses.'**
  String get loginToSaveAddress;

  /// No description provided for @addressCountryNotSupported.
  ///
  /// In en, this message translates to:
  /// **'We don\'t ship to this country yet'**
  String get addressCountryNotSupported;

  /// No description provided for @resolvingLocation.
  ///
  /// In en, this message translates to:
  /// **'Resolving your location…'**
  String get resolvingLocation;

  /// No description provided for @detectedCountry.
  ///
  /// In en, this message translates to:
  /// **'Detected country'**
  String get detectedCountry;

  /// No description provided for @dropPinToResolve.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to drop a pin'**
  String get dropPinToResolve;

  /// No description provided for @useThisCountry.
  ///
  /// In en, this message translates to:
  /// **'Use this country'**
  String get useThisCountry;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search a place or city…'**
  String get searchLocation;

  /// No description provided for @exploreStores.
  ///
  /// In en, this message translates to:
  /// **'Explore Stores'**
  String get exploreStores;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get office;

  /// No description provided for @bag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get bag;

  /// No description provided for @shoppingBag.
  ///
  /// In en, this message translates to:
  /// **'Shopping Bag'**
  String get shoppingBag;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform fee'**
  String get platformFee;

  /// No description provided for @codFee.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery fee'**
  String get codFee;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @paymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment Options'**
  String get paymentOptions;

  /// No description provided for @paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid By'**
  String get paidBy;

  /// No description provided for @ordersCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} orders · last 6 months'**
  String ordersCountSubtitle(Object count);

  /// No description provided for @searchYourOrders.
  ///
  /// In en, this message translates to:
  /// **'Search your orders'**
  String get searchYourOrders;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All orders'**
  String get allOrders;

  /// No description provided for @orderStatusDate.
  ///
  /// In en, this message translates to:
  /// **'{status} {date}'**
  String orderStatusDate(Object status, Object date);

  /// No description provided for @returnWindowCloses.
  ///
  /// In en, this message translates to:
  /// **'Return window closes {date}'**
  String returnWindowCloses(Object date);

  /// No description provided for @returnWindowClosed.
  ///
  /// In en, this message translates to:
  /// **'Return window closed'**
  String get returnWindowClosed;

  /// No description provided for @refundOfCredited.
  ///
  /// In en, this message translates to:
  /// **'Refund of {amount} credited'**
  String refundOfCredited(Object amount);

  /// No description provided for @refundInitiatedToSource.
  ///
  /// In en, this message translates to:
  /// **'Refund of {amount} initiated to source'**
  String refundInitiatedToSource(Object amount);

  /// No description provided for @cancelledAsPerRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancelled as per your request'**
  String get cancelledAsPerRequest;

  /// No description provided for @pickupScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Pickup scheduled for {date}'**
  String pickupScheduledFor(Object date);

  /// No description provided for @refundCreditedProcessedNote.
  ///
  /// In en, this message translates to:
  /// **'Processed to your original payment method. It may take 2-3 days to reflect.'**
  String get refundCreditedProcessedNote;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @getInvoice.
  ///
  /// In en, this message translates to:
  /// **'Get Invoice'**
  String get getInvoice;

  /// No description provided for @viewBreakup.
  ///
  /// In en, this message translates to:
  /// **'View Breakup'**
  String get viewBreakup;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmount;

  /// No description provided for @totalItemPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Item Price'**
  String get totalItemPrice;

  /// No description provided for @otherItemsInThisDelivery.
  ///
  /// In en, this message translates to:
  /// **'Other items in this delivery'**
  String get otherItemsInThisDelivery;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @moreItemsInThisOrder.
  ///
  /// In en, this message translates to:
  /// **'{count} more items in this order'**
  String moreItemsInThisOrder(Object count);

  /// No description provided for @onThisItemYouSaved.
  ///
  /// In en, this message translates to:
  /// **'On this item you saved a total of {amount}'**
  String onThisItemYouSaved(Object amount);

  /// No description provided for @youSavedOnThisOrder.
  ///
  /// In en, this message translates to:
  /// **'You saved {amount} on this order'**
  String youSavedOnThisOrder(Object amount);

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark'**
  String get remark;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get selectReason;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get feedbackSubmitted;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review (optional)'**
  String get writeAReview;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @rateSeller.
  ///
  /// In en, this message translates to:
  /// **'Rate seller'**
  String get rateSeller;

  /// No description provided for @editRating.
  ///
  /// In en, this message translates to:
  /// **'Edit rating'**
  String get editRating;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a title (optional)'**
  String get titleOptional;

  /// No description provided for @howWasTheItem.
  ///
  /// In en, this message translates to:
  /// **'How was the item?'**
  String get howWasTheItem;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @writeAReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeAReviewLabel;

  /// No description provided for @whatShouldOthersKnow.
  ///
  /// In en, this message translates to:
  /// **'What should other customers know?'**
  String get whatShouldOthersKnow;

  /// No description provided for @titleYourReview.
  ///
  /// In en, this message translates to:
  /// **'Title your review'**
  String get titleYourReview;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'(required)'**
  String get requiredLabel;

  /// No description provided for @titleReviewHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s most important to know?'**
  String get titleReviewHint;

  /// No description provided for @orderTrackStepCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderTrackStepCancelled;

  /// No description provided for @orderTrackStepReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get orderTrackStepReturned;

  /// No description provided for @orderTrackStepRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get orderTrackStepRefunded;

  /// No description provided for @orderTrackSummaryCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your order was cancelled'**
  String get orderTrackSummaryCancelled;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @addPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photos'**
  String get addPhotosHint;

  /// No description provided for @returnUpTo.
  ///
  /// In en, this message translates to:
  /// **'You can return up to {count}'**
  String returnUpTo(Object count);

  /// No description provided for @orderPlacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order placed!'**
  String get orderPlacedTitle;

  /// No description provided for @orderPlacedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you — your order is confirmed.'**
  String get orderPlacedThanks;

  /// No description provided for @deliveringTo.
  ///
  /// In en, this message translates to:
  /// **'Delivering to'**
  String get deliveringTo;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track order'**
  String get trackOrder;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue shopping'**
  String get continueShopping;

  /// No description provided for @stayHere.
  ///
  /// In en, this message translates to:
  /// **'Stay here'**
  String get stayHere;

  /// No description provided for @redirectingIn.
  ///
  /// In en, this message translates to:
  /// **'Taking you to your order in {seconds}s'**
  String redirectingIn(Object seconds);

  /// No description provided for @itemRefundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get itemRefundTitle;

  /// No description provided for @itemRefundAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund amount'**
  String get itemRefundAmountLabel;

  /// No description provided for @itemRefundQtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Items returned'**
  String get itemRefundQtyLabel;

  /// No description provided for @itemRefundMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund method'**
  String get itemRefundMethodLabel;

  /// No description provided for @itemRefundDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded on'**
  String get itemRefundDateLabel;

  /// No description provided for @itemRefundReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get itemRefundReasonLabel;

  /// No description provided for @refundStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refundStatusRefunded;

  /// No description provided for @refundStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get refundStatusProcessing;

  /// No description provided for @refundStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get refundStatusRejected;

  /// No description provided for @refundStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get refundStatusRequested;

  /// No description provided for @itemRefundCreditedNote.
  ///
  /// In en, this message translates to:
  /// **'Refund completed successfully.'**
  String get itemRefundCreditedNote;

  /// No description provided for @itemRefundProcessingNote.
  ///
  /// In en, this message translates to:
  /// **'Refund is being processed and should reflect within 1–3 days.'**
  String get itemRefundProcessingNote;

  /// No description provided for @itemRefundRejectedNote.
  ///
  /// In en, this message translates to:
  /// **'This return was rejected, so no refund was issued.'**
  String get itemRefundRejectedNote;

  /// No description provided for @itemRefundRequestedNote.
  ///
  /// In en, this message translates to:
  /// **'Refund will be initiated once your return is approved.'**
  String get itemRefundRequestedNote;

  /// No description provided for @refundMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get refundMethodWallet;

  /// No description provided for @refundMethodSource.
  ///
  /// In en, this message translates to:
  /// **'Original payment method'**
  String get refundMethodSource;

  /// No description provided for @deleteAccountRecoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'After deleting your account, you can recover it by logging in again within 30 days. After that, your account and all your data will be permanently deleted.'**
  String get deleteAccountRecoveryMessage;

  /// No description provided for @youSaveAmount.
  ///
  /// In en, this message translates to:
  /// **'You save {amount}'**
  String youSaveAmount(String amount);

  /// No description provided for @onlyNLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String onlyNLeft(int count);

  /// No description provided for @deliveryByDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery by {date}'**
  String deliveryByDate(String date);

  /// Cart select all checkbox label
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @orderConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmation'**
  String get orderConfirmation;

  /// No description provided for @expectedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery'**
  String get expectedDelivery;

  /// No description provided for @amountPayable.
  ///
  /// In en, this message translates to:
  /// **'Amount Payable'**
  String get amountPayable;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @confirmingPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirming payment…'**
  String get confirmingPaymentTitle;

  /// No description provided for @confirmingPaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please keep the app open while we confirm with your bank.'**
  String get confirmingPaymentSubtitle;

  /// No description provided for @paymentFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your order is still reserved. You can try paying again.'**
  String get paymentFailedSubtitle;

  /// No description provided for @paymentCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelledTitle;

  /// No description provided for @paymentCancelledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No amount was charged.'**
  String get paymentCancelledSubtitle;

  /// No description provided for @paymentStillConfirmingTitle.
  ///
  /// In en, this message translates to:
  /// **'Still confirming'**
  String get paymentStillConfirmingTitle;

  /// No description provided for @paymentStillConfirmingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is taking longer than usual. We\'ll notify you as soon as it\'s confirmed.'**
  String get paymentStillConfirmingSubtitle;

  /// No description provided for @retryPayment.
  ///
  /// In en, this message translates to:
  /// **'Retry payment'**
  String get retryPayment;

  /// No description provided for @backToCart.
  ///
  /// In en, this message translates to:
  /// **'Back to cart'**
  String get backToCart;

  /// No description provided for @viewMyOrders.
  ///
  /// In en, this message translates to:
  /// **'View my orders'**
  String get viewMyOrders;

  /// No description provided for @deliveryAndServices.
  ///
  /// In en, this message translates to:
  /// **'Delivery & Services'**
  String get deliveryAndServices;

  /// No description provided for @standardDelivery.
  ///
  /// In en, this message translates to:
  /// **'STANDARD'**
  String get standardDelivery;

  /// No description provided for @payOnDeliveryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Pay on Delivery is available'**
  String get payOnDeliveryAvailable;

  /// No description provided for @hassleFreeReturnAndExchange.
  ///
  /// In en, this message translates to:
  /// **'Hassle free {days} days Return & Exchange'**
  String hassleFreeReturnAndExchange(Object days);

  /// No description provided for @mrp.
  ///
  /// In en, this message translates to:
  /// **'MRP'**
  String get mrp;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get searchCity;

  /// No description provided for @noCountriesFound.
  ///
  /// In en, this message translates to:
  /// **'No countries found'**
  String get noCountriesFound;

  /// No description provided for @noCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get noCitiesFound;

  /// No description provided for @pleaseSelectCountry.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseSelectCountry;

  /// No description provided for @pleaseSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get pleaseSelectCity;

  /// No description provided for @pleaseEnterValidZipcode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid pincode'**
  String get pleaseEnterValidZipcode;

  /// No description provided for @pincodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This pincode is not serviceable yet'**
  String get pincodeNotFound;

  /// No description provided for @chooseMarketForPincode.
  ///
  /// In en, this message translates to:
  /// **'Multiple regions match this pincode. Please choose one.'**
  String get chooseMarketForPincode;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @searchLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get searchLocationOnMap;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @addMoreAttachments.
  ///
  /// In en, this message translates to:
  /// **'Add more attachments'**
  String get addMoreAttachments;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachment;

  /// No description provided for @chooseFileTypeToUpload.
  ///
  /// In en, this message translates to:
  /// **'Choose file type to upload'**
  String get chooseFileTypeToUpload;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @backToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get backToTop;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get supportTitle;

  /// No description provided for @supportYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYou;

  /// No description provided for @supportBy.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get supportBy;

  /// No description provided for @supportCallRequested.
  ///
  /// In en, this message translates to:
  /// **'Call requested'**
  String get supportCallRequested;

  /// No description provided for @supportCallUpdated.
  ///
  /// In en, this message translates to:
  /// **'Call request updated'**
  String get supportCallUpdated;

  /// No description provided for @supportAssigned.
  ///
  /// In en, this message translates to:
  /// **'Conversation assigned'**
  String get supportAssigned;

  /// No description provided for @supportUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Conversation unassigned'**
  String get supportUnassigned;

  /// No description provided for @supportStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Conversation status updated'**
  String get supportStatusUpdated;

  /// No description provided for @supportAssistant.
  ///
  /// In en, this message translates to:
  /// **'Your personal support assistant'**
  String get supportAssistant;

  /// No description provided for @supportWelcome.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get supportWelcome;

  /// No description provided for @supportWelcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose an order or general help to start a guided support conversation.'**
  String get supportWelcomeDescription;

  /// No description provided for @supportSelectOrder.
  ///
  /// In en, this message translates to:
  /// **'Which order do you need help with?'**
  String get supportSelectOrder;

  /// No description provided for @supportOlderOrders.
  ///
  /// In en, this message translates to:
  /// **'Other previous orders'**
  String get supportOlderOrders;

  /// No description provided for @supportGeneralHelp.
  ///
  /// In en, this message translates to:
  /// **'My issue is not related to an order'**
  String get supportGeneralHelp;

  /// No description provided for @supportSelectTopic.
  ///
  /// In en, this message translates to:
  /// **'What can we help you with?'**
  String get supportSelectTopic;

  /// No description provided for @supportDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get supportDescribeIssue;

  /// No description provided for @supportMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your message…'**
  String get supportMessagePlaceholder;

  /// No description provided for @supportStartChat.
  ///
  /// In en, this message translates to:
  /// **'Start chat'**
  String get supportStartChat;

  /// No description provided for @supportSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get supportSend;

  /// No description provided for @supportResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve chat'**
  String get supportResolve;

  /// No description provided for @supportResolved.
  ///
  /// In en, this message translates to:
  /// **'This conversation has been closed'**
  String get supportResolved;

  /// No description provided for @supportResolveTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolve this chat?'**
  String get supportResolveTitle;

  /// No description provided for @supportResolveBody.
  ///
  /// In en, this message translates to:
  /// **'Only resolve the chat when your issue has been handled. The conversation will become read-only.'**
  String get supportResolveBody;

  /// No description provided for @supportKeepChatting.
  ///
  /// In en, this message translates to:
  /// **'Keep chatting'**
  String get supportKeepChatting;

  /// No description provided for @supportConfirmResolve.
  ///
  /// In en, this message translates to:
  /// **'Yes, resolve chat'**
  String get supportConfirmResolve;

  /// No description provided for @supportCallback.
  ///
  /// In en, this message translates to:
  /// **'Callback'**
  String get supportCallback;

  /// No description provided for @supportCallbackBody.
  ///
  /// In en, this message translates to:
  /// **'Request a call on your registered phone number?'**
  String get supportCallbackBody;

  /// No description provided for @supportRequestCallback.
  ///
  /// In en, this message translates to:
  /// **'Request callback'**
  String get supportRequestCallback;

  /// No description provided for @supportRate.
  ///
  /// In en, this message translates to:
  /// **'How would you rate our assistance?'**
  String get supportRate;

  /// No description provided for @supportFeedback.
  ///
  /// In en, this message translates to:
  /// **'Optional feedback'**
  String get supportFeedback;

  /// No description provided for @supportRatingHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a rating, add optional feedback, then submit.'**
  String get supportRatingHint;

  /// No description provided for @supportSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get supportSubmitRating;

  /// No description provided for @supportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback'**
  String get supportThanks;

  /// No description provided for @supportStillIssue.
  ///
  /// In en, this message translates to:
  /// **'Still have an issue?'**
  String get supportStillIssue;

  /// No description provided for @supportChatWithUs.
  ///
  /// In en, this message translates to:
  /// **'Chat with us'**
  String get supportChatWithUs;

  /// No description provided for @supportNewChatHint.
  ///
  /// In en, this message translates to:
  /// **'Start a new support conversation when you are ready.'**
  String get supportNewChatHint;

  /// No description provided for @supportQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get supportQuickReplies;

  /// No description provided for @supportAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get supportAttach;

  /// No description provided for @supportDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get supportDownload;

  /// No description provided for @supportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get supportShare;

  /// No description provided for @supportPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get supportPreview;

  /// No description provided for @supportLoadOlder.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get supportLoadOlder;

  /// No description provided for @supportExecutive.
  ///
  /// In en, this message translates to:
  /// **'A customer support executive will connect with you shortly.'**
  String get supportExecutive;

  /// No description provided for @supportTyping.
  ///
  /// In en, this message translates to:
  /// **'Support is typing…'**
  String get supportTyping;

  /// No description provided for @supportLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get supportLive;

  /// No description provided for @supportPolling.
  ///
  /// In en, this message translates to:
  /// **'Polling'**
  String get supportPolling;

  /// No description provided for @supportOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get supportOffline;

  /// No description provided for @supportContact.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get supportContact;

  /// No description provided for @supportCall.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get supportCall;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get supportEmail;

  /// No description provided for @supportRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get supportRetry;

  /// No description provided for @supportLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation…'**
  String get supportLoading;

  /// No description provided for @supportFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not load your support conversation.'**
  String get supportFailed;

  /// No description provided for @supportGeneral.
  ///
  /// In en, this message translates to:
  /// **'General help'**
  String get supportGeneral;

  /// No description provided for @supportRecentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent orders'**
  String get supportRecentOrders;

  /// No description provided for @supportDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get supportDelivered;

  /// No description provided for @supportRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get supportRemove;

  /// No description provided for @supportMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Message not sent. Tap to retry.'**
  String get supportMessageFailed;

  /// No description provided for @supportAttachmentError.
  ///
  /// In en, this message translates to:
  /// **'Choose up to five JPEG, PNG, WebP or PDF files, maximum 10 MB each.'**
  String get supportAttachmentError;

  /// No description provided for @supportActionFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that action. Please try again.'**
  String get supportActionFailed;

  /// No description provided for @supportNoMessages.
  ///
  /// In en, this message translates to:
  /// **'Your support messages will appear here.'**
  String get supportNoMessages;

  /// No description provided for @supportClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get supportClose;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'fr',
        'gu',
        'hi',
        'te'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
